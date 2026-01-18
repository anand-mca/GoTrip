"""
Place fetcher that aggregates places from multiple sources.
Currently implements mock data fallback; can be extended for real APIs.
"""
from typing import List, Optional
from app.models.schemas import PlaceModel, PreferenceEnum
from app.integrations.mock_data import get_mock_places
from app.utils.logger import get_logger

logger = get_logger(__name__)


class PlaceFetcher:
    """
    Fetches and aggregates places from various sources.
    """
    
    @staticmethod
    def fetch_places_by_preferences(
        preferences: List[PreferenceEnum],
        limit: int = 50,
        use_mock: bool = True
    ) -> List[PlaceModel]:
        """
        Fetch places matching user preferences.
        
        Args:
            preferences: List of preferred place categories
            limit: Maximum number of places to return
            use_mock: Whether to use mock data (True for testing)
        
        Returns:
            List of PlaceModel instances
        """
        logger.info(f"Fetching places for preferences: {preferences}")
        
        if use_mock:
            return PlaceFetcher._fetch_from_mock(preferences, limit)
        
        # TODO: Implement real API calls
        # 1. Google Places API
        # 2. OpenStreetMap Nominatim
        # 3. Fall back to mock data
        
        logger.warning("No real API implementation. Using mock data fallback.")
        return PlaceFetcher._fetch_from_mock(preferences, limit)
    
    @staticmethod
    def _fetch_from_mock(
        preferences: List[PreferenceEnum],
        limit: int
    ) -> List[PlaceModel]:
        """Fetch places from mock data."""
        # Convert PreferenceEnum to strings for comparison
        preference_strings = [p.value if hasattr(p, 'value') else str(p) for p in preferences]
        
        places = get_mock_places(preference_strings, limit)
        logger.info(f"Fetched {len(places)} places from mock data")
        return places
    
    @staticmethod
    def fetch_places_by_location(
        latitude: float,
        longitude: float,
        radius_km: float = 50,
        place_types: Optional[List[str]] = None,
        limit: int = 50
    ) -> List[PlaceModel]:
        """
        Fetch places near a specific location.
        
        Args:
            latitude: Center latitude
            longitude: Center longitude
            radius_km: Search radius in kilometers
            place_types: Types of places to search for
            limit: Maximum number of places
        
        Returns:
            List of PlaceModel instances
        """
        logger.info(f"Fetching places near ({latitude}, {longitude}) within {radius_km}km")
        
        # TODO: Implement location-based search using Google Places Nearby Search
        # or OpenStreetMap Nominatim reverse geocoding
        
        # For now, return mock data
        places = get_mock_places(limit=limit)
        logger.info(f"Fetched {len(places)} places by location")
        return places
