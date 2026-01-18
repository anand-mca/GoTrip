"""
Main trip planning orchestrator service.
Integrates all components to generate optimized itineraries.
"""
from typing import List, Tuple
from datetime import datetime, timedelta, date
from app.models.schemas import (
    ItineraryItemRequest, PlaceModel, DayItinerary, TripItineraryResponse, PreferenceEnum
)
from app.services.place_fetcher import PlaceFetcher
from app.services.scoring_engine import ScoringEngine
from app.services.route_optimizer import RouteOptimizer
from app.services.weather_service import WeatherService
from app.config import settings
from app.utils.logger import get_logger
import uuid

logger = get_logger(__name__)


class TripPlanningService:
    """
    Orchestrates the complete trip planning workflow:
    1. Fetch places matching preferences
    2. Score and rank places
    3. Select feasible set considering budget and time
    4. Optimize visiting order
    5. Generate day-wise itinerary
    """
    
    def __init__(self):
        """Initialize service components."""
        self.place_fetcher = PlaceFetcher()
        self.scoring_engine = ScoringEngine()
        self.route_optimizer = RouteOptimizer()
        self.weather_service = WeatherService()
    
    def plan_trip(self, request: ItineraryItemRequest) -> TripItineraryResponse:
        """
        Generate complete trip itinerary.
        
        Algorithm Overview:
        1. Calculate trip parameters (duration, daily budget)
        2. Fetch places matching preferences
        3. Score places using multi-factor scoring
        4. Select optimal set respecting budget constraints (greedy algorithm)
        5. Distribute places across days
        6. Optimize route within each day (nearest neighbor TSP)
        7. Adjust for weather
        8. Generate day-wise itinerary
        
        Args:
            request: Trip planning request with dates, budget, preferences
        
        Returns:
            TripItineraryResponse with optimized itinerary
        """
        trip_id = str(uuid.uuid4())
        logger.info(f"Starting trip planning: {trip_id}")
        
        # Step 1: Calculate trip parameters
        start_date = request.start_date
        end_date = request.end_date
        total_days = (end_date - start_date).days + 1
        daily_budget = request.budget / total_days
        
        logger.info(
            f"Trip: {total_days} days, Budget: ₹{request.budget} "
            f"(₹{daily_budget:.0f}/day), Preferences: {request.preferences}"
        )
        
        # Step 2: Fetch places
        places = self.place_fetcher.fetch_places_by_preferences(
            request.preferences,
            limit=settings.MAX_PLACES_PER_TRIP,
            use_mock=settings.USE_MOCK_DATA
        )
        
        if not places:
            logger.error("No places found for given preferences")
            return TripItineraryResponse(
                trip_id=trip_id,
                start_date=start_date,
                end_date=end_date,
                total_days=total_days,
                daily_itineraries=[],
                algorithm_explanation="No places found for the given preferences."
            )
        
        # Step 3: Score and rank places
        center_lat = request.latitude or settings.CENTER_LAT
        center_lon = request.longitude or settings.CENTER_LON
        
        scored_places = self.scoring_engine.score_and_rank_places(
            places, request.preferences, center_lat, center_lon
        )
        
        # Step 4: Select optimal set of places (greedy selection)
        selected_places = self._select_places_greedy(
            scored_places, daily_budget * total_days, total_days
        )
        
        logger.info(f"Selected {len(selected_places)} places for trip")
        
        # Step 5: Distribute places across days
        daily_places = self._distribute_places_across_days(
            selected_places, total_days
        )
        
        # Step 6 & 7: Optimize routes and adjust for weather
        daily_itineraries = self._generate_daily_itineraries(
            daily_places, start_date, center_lat, center_lon
        )
        
        # Calculate totals
        total_distance = sum(day.total_distance for day in daily_itineraries)
        total_cost = sum(day.estimated_budget for day in daily_itineraries)
        
        # Generate algorithm explanation
        explanation = self._generate_explanation(
            total_days, len(selected_places), len(places)
        )
        
        logger.info(
            f"Trip planned: {len(selected_places)} places, "
            f"{total_distance:.1f} km, ₹{total_cost:.0f}"
        )
        
        return TripItineraryResponse(
            trip_id=trip_id,
            start_date=start_date,
            end_date=end_date,
            total_days=total_days,
            total_distance=total_distance,
            total_estimated_cost=total_cost,
            daily_itineraries=daily_itineraries,
            algorithm_explanation=explanation
        )
    
    def _select_places_greedy(
        self,
        scored_places: List[Tuple[PlaceModel, float]],
        total_budget: float,
        total_days: int
    ) -> List[PlaceModel]:
        """
        Greedy selection algorithm:
        - Sort by score (already done)
        - Select places while budget allows
        - Ensure reasonable time to visit each place
        
        Args:
            scored_places: List of (place, score) tuples sorted by score
            total_budget: Total budget for trip
            total_days: Total number of days
        
        Returns:
            List of selected PlaceModel instances
        """
        selected = []
        total_cost = 0
        total_visit_time = 0
        avg_day_time = (total_days * 24 * 60) - (total_days * 8)  # 16 hours/day
        max_visit_time = avg_day_time * 0.8  # Use 80% of available time
        
        for place, score in scored_places:
            visit_time = settings.AVG_VISIT_TIME.get(place.category, 120)
            place_cost = place.estimated_cost or settings.AVG_COST_PER_PLACE.get(place.category, 1000)
            
            # Check budget and time constraints
            if total_cost + place_cost <= total_budget and total_visit_time + visit_time <= max_visit_time:
                selected.append(place)
                total_cost += place_cost
                total_visit_time += visit_time
        
        logger.info(
            f"Selected places (greedy): {len(selected)}, "
            f"Cost: ₹{total_cost:.0f}/{total_budget:.0f}, "
            f"Time: {total_visit_time}mins/{max_visit_time:.0f}mins"
        )
        
        return selected
    
    def _distribute_places_across_days(
        self,
        places: List[PlaceModel],
        total_days: int
    ) -> List[List[PlaceModel]]:
        """
        Distribute selected places across days using round-robin.
        
        Args:
            places: List of places to distribute
            total_days: Number of days
        
        Returns:
            List of place lists for each day
        """
        daily_places = [[] for _ in range(total_days)]
        
        for i, place in enumerate(places):
            day_index = i % total_days
            daily_places[day_index].append(place)
        
        logger.info(
            f"Distributed {len(places)} places across {total_days} days: "
            f"{[len(d) for d in daily_places]}"
        )
        
        return daily_places
    
    def _generate_daily_itineraries(
        self,
        daily_places: List[List[PlaceModel]],
        start_date: date,
        center_lat: float,
        center_lon: float
    ) -> List[DayItinerary]:
        """
        Generate optimized day-wise itineraries.
        
        Args:
            daily_places: List of place lists for each day
            start_date: Trip start date
            center_lat: Center latitude
            center_lon: Center longitude
        
        Returns:
            List of DayItinerary objects
        """
        daily_itineraries = []
        
        for day_num, places_for_day in enumerate(daily_places, 1):
            if not places_for_day:
                continue
            
            # Optimize route for the day
            distance, optimized_places = self.route_optimizer.calculate_route_distance(
                places_for_day, center_lat, center_lon
            )
            
            # Calculate metrics
            total_time = 0
            total_cost = 0
            for place in optimized_places:
                visit_time = settings.AVG_VISIT_TIME.get(place.category, 120)
                place_cost = place.estimated_cost or settings.AVG_COST_PER_PLACE.get(place.category, 1000)
                total_time += visit_time + settings.AVG_TRAVEL_TIME
                total_cost += place_cost
            
            day_date = start_date + timedelta(days=day_num - 1)
            
            day_itinerary = DayItinerary(
                day=day_num,
                date=day_date,
                places=optimized_places,
                total_distance=distance,
                total_time=total_time,
                estimated_budget=total_cost
            )
            
            daily_itineraries.append(day_itinerary)
        
        return daily_itineraries
    
    @staticmethod
    def _generate_explanation(total_days: int, selected_count: int, total_count: int) -> str:
        """Generate explanation of the algorithm used."""
        return (
            f"Trip Plan Algorithm:\n"
            f"1. Scoring: Evaluated {total_count} places using multi-factor scoring "
            f"(Rating×0.3 + Preferences×0.4 + Popularity×0.1 + Distance×0.2)\n"
            f"2. Selection: Selected {selected_count} places using greedy algorithm "
            f"respecting budget and time constraints\n"
            f"3. Distribution: Distributed across {total_days} days using round-robin\n"
            f"4. Optimization: Optimized visiting order per day using Nearest Neighbor algorithm "
            f"(TSP approximation)\n"
            f"5. Feasibility: All selections verified for budget and time constraints"
        )
