"""
Geocoding service for converting city names to latitude and longitude.
Uses OpenStreetMap Nominatim API (free, no API key required).
Fallback to hardcoded coordinates for common Indian cities.
"""
import httpx
import asyncio
from typing import Optional, Dict, Tuple
from app.utils.logger import get_logger

logger = get_logger(__name__)

# Hardcoded coordinates for quick lookup (fallback)
CITY_COORDINATES = {
    'mumbai': (19.0760, 72.8777),
    'delhi': (28.6139, 77.2090),
    'bangalore': (12.9716, 77.5946),
    'bengaluru': (12.9716, 77.5946),
    'kolkata': (22.5726, 88.3639),
    'chennai': (13.0827, 80.2707),
    'hyderabad': (17.3850, 78.4867),
    'pune': (18.5204, 73.8567),
    'ahmedabad': (23.0225, 72.5714),
    'jaipur': (26.9124, 75.7873),
    'goa': (15.2993, 74.1240),
    'munnar': (10.0889, 77.0595),
    'manali': (32.2432, 77.1892),
    'shimla': (31.1048, 77.1734),
    'rishikesh': (30.0869, 78.2676),
    'udaipur': (24.5854, 73.7125),
    'kochi': (9.9312, 76.2673),
    'cochin': (9.9312, 76.2673),
    'agra': (27.1767, 78.0081),
    'varanasi': (25.3176, 82.9739),
    'pondicherry': (11.9416, 79.8083),
    'puducherry': (11.9416, 79.8083),
    'darjeeling': (27.0360, 88.2627),
    'srinagar': (34.0837, 74.7973),
    'srinagar, jammu and kashmir': (34.0837, 74.7973),
    'leh': (34.1526, 77.5769),
    'kanyakumari': (8.0883, 77.5385),
    'thiruvananthapuram': (8.5241, 76.9366),
    'trivandrum': (8.5241, 76.9366),
    'mysore': (12.2958, 76.6394),
    'ooty': (11.4102, 76.6955),
    'coimbatore': (11.0081, 76.9877),
    'salem': (11.6643, 78.1460),
    'madurai': (9.9252, 78.1198),
    'tiruchirappalli': (10.7905, 78.7047),
    'indore': (22.7196, 75.8577),
    'bhopal': (23.1815, 77.4104),
    'lucknow': (26.8467, 80.9462),
    'kanpur': (26.4499, 80.3319),
    'allahabad': (25.4358, 81.8463),
    'prayagraj': (25.4358, 81.8463),
    'varanasi': (25.3176, 82.9739),
    'gorakhpur': (26.7597, 83.3829),
    'patna': (25.5941, 85.1376),
    'ranchi': (23.3441, 85.3096),
    'jamshedpur': (22.8046, 86.1824),
    'visakhapatnam': (17.6869, 83.2185),
    'vijayawada': (16.5062, 80.6480),
    'tirupati': (13.1939, 79.8941),
    'raipur': (21.2514, 81.6296),
    'nagpur': (21.1458, 79.0882),
    'nashik': (19.9975, 73.7898),
    'aurangabad': (19.8762, 75.3433),
    'guwahati': (26.1445, 91.7362),
    'shillong': (25.5788, 91.8933),
    'imphal': (24.8170, 94.9080),
    'aizawl': (23.1815, 92.7879),
    'thiruvananthapuram': (8.5241, 76.9366),
    'kottayam': (9.6036, 76.5214),
    'alappuzha': (9.4981, 76.3388),
    'thrissur': (10.5167, 76.2167),
    'calicut': (11.2588, 75.7804),
    'kozhikode': (11.2588, 75.7804),
    'kannur': (12.0166, 75.3667),
    'kasaragod': (12.5064, 75.0504),
}


class GeocodingService:
    """
    Converts city names to coordinates using multiple strategies.
    Strategy 1: Hardcoded lookup (fastest, for common Indian cities)
    Strategy 2: OpenStreetMap Nominatim API (for any location)
    Strategy 3: Default to center of search radius
    """
    
    NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
    TIMEOUT = 10  # seconds (increased for API reliability)
    
    @staticmethod
    async def get_coordinates_by_city(city_name: str) -> Tuple[float, float]:
        """
        Get latitude and longitude for a city.
        
        Args:
            city_name: Name of the city (e.g., "Mumbai", "Delhi", "Bangalore")
        
        Returns:
            Tuple of (latitude, longitude)
            
        Raises:
            ValueError: If city not found
            
        Algorithm:
        1. Try hardcoded lookup (fastest)
        2. Try Nominatim API (for any location)
        3. Raise error if not found
        """
        
        logger.info(f"Geocoding city: {city_name}")
        
        # Step 1: Try hardcoded lookup
        try:
            coords = GeocodingService._lookup_hardcoded(city_name)
            if coords:
                logger.info(f"Found {city_name} in hardcoded list: {coords}")
                return coords
        except KeyError:
            pass
        
        # Step 2: Try Nominatim API
        try:
            coords = await GeocodingService._lookup_nominatim(city_name)
            if coords:
                logger.info(f"Found {city_name} via Nominatim API: {coords}")
                return coords
        except Exception as e:
            logger.warning(f"Nominatim API lookup failed: {str(e)}")
        
        # Step 3: City not found
        raise ValueError(f"Could not find coordinates for city: {city_name}")
    
    @staticmethod
    def _lookup_hardcoded(city_name: str) -> Optional[Tuple[float, float]]:
        """
        Lookup city in hardcoded dictionary.
        
        Args:
            city_name: City name
            
        Returns:
            (latitude, longitude) or None if not found
        """
        normalized_city = city_name.strip().lower()
        
        if normalized_city in CITY_COORDINATES:
            return CITY_COORDINATES[normalized_city]
        
        # Try partial match for compound city names
        for key, coords in CITY_COORDINATES.items():
            if normalized_city in key or key in normalized_city:
                return coords
        
        return None
    
    @staticmethod
    async def _lookup_nominatim(city_name: str) -> Optional[Tuple[float, float]]:
        """
        Lookup city using OpenStreetMap Nominatim API.
        
        Free API, no authentication required.
        
        Args:
            city_name: City name
            
        Returns:
            (latitude, longitude) or None if not found
            
        Example:
            Request: https://nominatim.openstreetmap.org/search?q=Mumbai&format=json
            Response: [
                {
                    "place_id": 123456,
                    "lat": "19.0760",
                    "lon": "72.8777",
                    "display_name": "Mumbai, Maharashtra, India",
                    ...
                }
            ]
        """
        try:
            async with httpx.AsyncClient(timeout=GeocodingService.TIMEOUT) as client:
                response = await client.get(
                    GeocodingService.NOMINATIM_URL,
                    params={
                        'q': city_name,
                        'format': 'json',
                        'limit': 1,
                    },
                    headers={
                        'User-Agent': 'GoTrip-Travel-Planning-API/1.0'
                    }
                )
                
                logger.info(f"Nominatim response status: {response.status_code}")
                
                if response.status_code == 200:
                    results = response.json()
                    
                    if results and len(results) > 0:
                        first_result = results[0]
                        lat = float(first_result['lat'])
                        lon = float(first_result['lon'])
                        
                        logger.info(
                            f"Nominatim found '{city_name}' at "
                            f"({lat}, {lon}) - {first_result.get('display_name', '')}"
                        )
                        
                        return (lat, lon)
                    else:
                        logger.warning(f"No results from Nominatim for city: {city_name}")
                        return None
                else:
                    logger.error(f"Nominatim API error: {response.status_code}")
                    return None
                    
        except asyncio.TimeoutError:
            logger.error(f"Nominatim API timeout for city: {city_name}")
            return None
        except Exception as e:
            logger.error(f"Nominatim API error: {str(e)}")
            return None
    
    @staticmethod
    async def validate_city(city_name: str) -> Dict[str, any]:
        """
        Validate a city name and return its details.
        
        Args:
            city_name: City name to validate
            
        Returns:
            Dictionary with:
            {
                'valid': bool,
                'city_name': str,
                'latitude': float,
                'longitude': float,
                'source': 'hardcoded' or 'nominatim'
            }
            
        Raises:
            ValueError: If city is not found
        """
        
        # Try hardcoded first (to detect source)
        try:
            coords = GeocodingService._lookup_hardcoded(city_name)
            if coords:
                return {
                    'valid': True,
                    'city_name': city_name,
                    'latitude': coords[0],
                    'longitude': coords[1],
                    'source': 'hardcoded'
                }
        except:
            pass
        
        # Try API
        try:
            coords = await GeocodingService._lookup_nominatim(city_name)
            if coords:
                return {
                    'valid': True,
                    'city_name': city_name,
                    'latitude': coords[0],
                    'longitude': coords[1],
                    'source': 'nominatim_api'
                }
        except:
            pass
        
        # Not found
        raise ValueError(f"City '{city_name}' not found in geocoding database")


# Synchronous wrapper for use in synchronous contexts
def get_city_coordinates(city_name: str) -> Tuple[float, float]:
    """
    Synchronous wrapper to get city coordinates.
    For use in non-async contexts.
    
    Args:
        city_name: City name
        
    Returns:
        (latitude, longitude)
        
    Raises:
        ValueError: If city not found
    """
    # Try hardcoded lookup first (no async needed)
    try:
        coords = GeocodingService._lookup_hardcoded(city_name)
        if coords:
            logger.info(f"Hardcoded lookup for {city_name}: {coords}")
            return coords
    except:
        pass
    
    # If not in hardcoded, raise error (can extend with sync API call if needed)
    raise ValueError(
        f"City '{city_name}' not found. Please check spelling or try another city. "
        f"Common cities: Mumbai, Delhi, Bangalore, Goa, Jaipur, Agra, Varanasi, etc."
    )
