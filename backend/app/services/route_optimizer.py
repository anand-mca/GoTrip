"""
Route optimization using Nearest Neighbor heuristic for Traveling Salesman Problem.
Finds a feasible approximation to the optimal visiting order.
"""
from typing import List, Tuple
from app.models.schemas import PlaceModel
from app.services.scoring_engine import haversine_distance
from app.utils.logger import get_logger

logger = get_logger(__name__)


class RouteOptimizer:
    """
    Optimizes the visiting order of places to minimize total distance/time.
    
    Uses Nearest Neighbor algorithm:
    1. Start at a random/initial place
    2. Find the nearest unvisited place
    3. Move to that place
    4. Repeat until all places visited
    
    This is a greedy approximation that gives good results in O(n²) time.
    Optimal solution would require exponential time (NP-hard problem).
    """
    
    @staticmethod
    def calculate_route_distance(
        places: List[PlaceModel],
        start_lat: float = None,
        start_lon: float = None
    ) -> Tuple[float, List[PlaceModel]]:
        """
        Optimize route using Nearest Neighbor algorithm.
        
        Args:
            places: List of places to visit
            start_lat: Starting latitude (if None, uses first place)
            start_lon: Starting longitude (if None, uses first place)
        
        Returns:
            Tuple of (total_distance_km, optimized_place_order)
        """
        if not places:
            return 0.0, []
        
        if len(places) == 1:
            return 0.0, places
        
        # Initialize starting point
        if start_lat is None or start_lon is None:
            current_lat, current_lon = places[0].latitude, places[0].longitude
            unvisited = places[1:]
            visited = [places[0]]
        else:
            current_lat, current_lon = start_lat, start_lon
            unvisited = places.copy()
            visited = []
        
        total_distance = 0.0
        
        # Nearest Neighbor algorithm
        while unvisited:
            # Find nearest unvisited place
            nearest_place = None
            min_distance = float('inf')
            
            for place in unvisited:
                distance = haversine_distance(
                    current_lat, current_lon,
                    place.latitude, place.longitude
                )
                if distance < min_distance:
                    min_distance = distance
                    nearest_place = place
            
            # Move to nearest place
            if nearest_place:
                visited.append(nearest_place)
                total_distance += min_distance
                current_lat = nearest_place.latitude
                current_lon = nearest_place.longitude
                unvisited.remove(nearest_place)
                
                logger.debug(f"Route step: {nearest_place.name} (distance: {min_distance:.2f} km)")
        
        logger.info(f"Optimized route: {len(visited)} places, total distance: {total_distance:.2f} km")
        
        return total_distance, visited
    
    @staticmethod
    def optimize_multi_day_routes(
        daily_place_lists: List[List[PlaceModel]]
    ) -> List[Tuple[float, List[PlaceModel]]]:
        """
        Optimize routes for multiple days.
        
        Args:
            daily_place_lists: List of place lists for each day
        
        Returns:
            List of (distance, optimized_places) tuples for each day
        """
        optimized_days = []
        
        for day_places in daily_place_lists:
            distance, optimized = RouteOptimizer.calculate_route_distance(day_places)
            optimized_days.append((distance, optimized))
        
        return optimized_days
