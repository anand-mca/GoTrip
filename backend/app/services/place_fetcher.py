"""
Place fetcher that aggregates places from multiple sources.
Primary: Supabase database, Fallback: Mock data for testing.
"""
from typing import List, Optional
import sys
from app.models.schemas import PlaceModel, PreferenceEnum
from app.integrations.mock_data import get_mock_places
from app.integrations.supabase_service import fetch_destinations_from_supabase
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
        use_mock: bool = False,
        center_lat: Optional[float] = None,
        center_lon: Optional[float] = None,
        radius_km: float = 500
    ) -> List[PlaceModel]:
        """
        Fetch places matching user preferences.
        
        Args:
            preferences: List of preferred place categories
            limit: Maximum number of places to return
            use_mock: Whether to use mock data (False for production with Supabase)
            center_lat, center_lon: Center location for distance calculation
            radius_km: Search radius in kilometers
        
        Returns:
            List of PlaceModel instances
        """
        print(f"\n{'='*80}")
        print(f"🔍 PLACE_FETCHER START: preferences={[p.value for p in preferences]}, use_mock={use_mock}")
        print(f"   radius={radius_km}km, center=({center_lat}, {center_lon})")
        print(f"{'='*80}", flush=True)
        sys.stdout.flush()
        
        logger.info(f"Fetching places for preferences: {preferences}")
        
        if use_mock:
            print(f"⚠️  USE_MOCK_DATA is TRUE - skipping Supabase, going straight to mock!", flush=True)
            sys.stdout.flush()
            return PlaceFetcher._fetch_from_mock(preferences, limit)
        
        # Try Supabase first
        print(f"\n📡 Attempting Supabase fetch...", flush=True)
        sys.stdout.flush()
        places = fetch_destinations_from_supabase(
            preferences=[p.value for p in preferences],
            limit=limit,
            center_lat=center_lat,
            center_lon=center_lon,
            radius_km=radius_km
        )
        
        print(f"📦 Supabase returned: {len(places) if places else 0} places", flush=True)
        sys.stdout.flush()
        
        if places:
            print(f"✅ Using Supabase data: {[p.name for p in places[:3]]}", flush=True)
            sys.stdout.flush()
            return places
        
        # Fall back to mock data
        print(f"\n⚠️  FALLBACK: Supabase returned empty. Using MOCK data!", flush=True)
        print(f"⚠️  Preferences: {[p.value for p in preferences]}", flush=True)
        sys.stdout.flush()
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
