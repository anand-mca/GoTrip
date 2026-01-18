"""
Scoring engine for ranking and evaluating places.
Uses rule-based logic with weighted factors.
"""
from typing import List, Tuple
from app.models.schemas import PlaceModel, PreferenceEnum
from app.config import settings
from app.utils.logger import get_logger
from math import radians, cos, sin, asin, sqrt

logger = get_logger(__name__)


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate great circle distance between two points on earth (in kilometers).
    """
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    km = 6371 * c
    return km


class ScoringEngine:
    """
    Scores places based on multiple factors:
    - Rating: Quality of the place (0-5 stars)
    - Popularity: Number of reviews
    - Preference match: How well it matches user preferences
    - Distance: Proximity to center location (closer is better)
    """
    
    def __init__(self):
        """Initialize scoring weights from configuration."""
        self.rating_weight = settings.RATING_WEIGHT
        self.preference_weight = settings.PREFERENCE_WEIGHT
        self.distance_weight = settings.DISTANCE_WEIGHT
        self.popularity_weight = settings.POPULARITY_WEIGHT
    
    def calculate_place_score(
        self,
        place: PlaceModel,
        user_preferences: List[PreferenceEnum],
        center_lat: float,
        center_lon: float,
        max_distance_km: float = 50
    ) -> float:
        """
        Calculate composite score for a place using multiple factors.
        
        Formula:
        Score = (Rating × 0.3) + (Preference_Match × 0.4) +
                (Popularity × 0.1) + (Distance_Bonus × 0.2)
        
        Args:
            place: The place to score
            user_preferences: List of preferred categories
            center_lat: Center latitude for distance calculation
            center_lon: Center longitude for distance calculation
            max_distance_km: Maximum distance to consider
        
        Returns:
            Score between 0 and 100
        """
        
        # 1. Rating Score (0-5 → 0-100)
        rating_score = (place.rating / 5.0) * 100
        
        # 2. Preference Match Score (is category in preferences?)
        preference_match = 1.0 if place.category in user_preferences else 0.5
        preference_score = preference_match * 100
        
        # 3. Popularity Score (log-normalized)
        popularity_normalized = min(place.reviews / 1000, 1.0)  # Cap at 1000 reviews
        popularity_score = popularity_normalized * 100
        
        # 4. Distance Score (closer = higher score)
        distance_km = haversine_distance(center_lat, center_lon, place.latitude, place.longitude)
        distance_score = 0
        if distance_km <= max_distance_km:
            distance_score = ((max_distance_km - distance_km) / max_distance_km) * 100
        
        # Composite score with weights
        composite_score = (
            (rating_score * self.rating_weight) +
            (preference_score * self.preference_weight) +
            (popularity_score * self.popularity_weight) +
            (distance_score * self.distance_weight)
        )
        
        logger.info(
            f"Score for {place.name}: {composite_score:.1f} "
            f"(Rating: {rating_score:.1f}, Preference: {preference_score:.1f}, "
            f"Popularity: {popularity_score:.1f}, Distance: {distance_score:.1f})"
        )
        
        return min(composite_score, 100)  # Cap at 100
    
    def score_and_rank_places(
        self,
        places: List[PlaceModel],
        user_preferences: List[PreferenceEnum],
        center_lat: float,
        center_lon: float
    ) -> List[Tuple[PlaceModel, float]]:
        """
        Score all places and return sorted by score (descending).
        
        Args:
            places: List of places to score
            user_preferences: User's preferred categories
            center_lat: Center latitude
            center_lon: Center longitude
        
        Returns:
            List of (place, score) tuples sorted by score descending
        """
        scored_places = [
            (place, self.calculate_place_score(place, user_preferences, center_lat, center_lon))
            for place in places
        ]
        
        # Sort by score descending
        scored_places.sort(key=lambda x: x[1], reverse=True)
        
        logger.info(f"Ranked {len(scored_places)} places by score")
        
        return scored_places
