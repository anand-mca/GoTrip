"""
Weather service for fetching weather data and adjusting trip recommendations.
"""
from typing import Dict, List, Optional
from app.models.schemas import PlaceModel, PreferenceEnum
from app.config import settings
from app.utils.logger import get_logger
import requests
from datetime import date

logger = get_logger(__name__)


class WeatherService:
    """
    Integrates weather data and adjusts place recommendations accordingly.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """Initialize with OpenWeatherMap API key."""
        self.api_key = api_key or settings.OPENWEATHER_API_KEY
        self.base_url = "https://api.openweathermap.org/data/2.5"
    
    def get_weather_forecast(
        self,
        latitude: float,
        longitude: float,
        days_ahead: int = 5
    ) -> Dict:
        """
        Get weather forecast for a location.
        
        Args:
            latitude: Location latitude
            longitude: Location longitude
            days_ahead: Number of days to forecast
        
        Returns:
            Weather data dictionary
        """
        if not self.api_key:
            logger.warning("No OpenWeatherMap API key. Returning mock weather data.")
            return self._get_mock_weather()
        
        try:
            url = f"{self.base_url}/forecast"
            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": self.api_key,
                "units": "metric"
            }
            
            response = requests.get(url, params=params, timeout=5)
            response.raise_for_status()
            
            logger.info(f"Fetched weather data for ({latitude}, {longitude})")
            return response.json()
            
        except requests.RequestException as e:
            logger.error(f"Weather API error: {e}. Using mock data.")
            return self._get_mock_weather()
    
    def should_avoid_place(
        self,
        place: PlaceModel,
        weather_data: Dict
    ) -> bool:
        """
        Determine if a place should be avoided based on weather.
        
        Rules:
        - Avoid beaches during heavy rain
        - Avoid outdoor adventures during thunderstorms
        - Avoid shopping during extreme heat
        
        Args:
            place: Place to evaluate
            weather_data: Weather forecast data
        
        Returns:
            True if place should be avoided
        """
        if not weather_data or "list" not in weather_data:
            return False
        
        # Check first forecast entry
        forecast = weather_data["list"][0]
        rain = forecast.get("rain", {}).get("3h", 0)
        clouds = forecast.get("clouds", {}).get("all", 0)
        temp = forecast.get("main", {}).get("temp", 20)
        
        # Beach: avoid if rain probability > threshold
        if place.category == PreferenceEnum.BEACH:
            if rain > 5 or clouds > 80:  # More than 5mm rain or 80% clouds
                logger.info(f"Avoiding beach {place.name} due to weather (rain: {rain}mm)")
                return True
        
        # Adventure: avoid storms
        if place.category == PreferenceEnum.ADVENTURE:
            if rain > 10 or clouds > 90:
                logger.info(f"Avoiding adventure {place.name} due to weather")
                return True
        
        # Shopping: avoid extreme heat/cold
        if place.category == PreferenceEnum.SHOPPING:
            if temp > 40 or temp < 5:
                logger.info(f"Avoiding shopping {place.name} due to extreme temperature ({temp}°C)")
                return True
        
        return False
    
    def adjust_places_by_weather(
        self,
        places: List[PlaceModel],
        weather_data: Dict
    ) -> List[PlaceModel]:
        """
        Filter and adjust places based on weather.
        
        Args:
            places: List of places to filter
            weather_data: Weather forecast data
        
        Returns:
            Filtered list of places safe to visit
        """
        if not weather_data:
            return places
        
        filtered_places = [
            place for place in places
            if not self.should_avoid_place(place, weather_data)
        ]
        
        logger.info(
            f"Filtered places by weather: {len(places)} → {len(filtered_places)}"
        )
        
        return filtered_places
    
    @staticmethod
    def _get_mock_weather() -> Dict:
        """Return mock weather data for testing."""
        return {
            "list": [
                {
                    "dt": 1234567890,
                    "main": {"temp": 28, "humidity": 65},
                    "weather": [{"main": "Clear"}],
                    "clouds": {"all": 20},
                    "rain": {"3h": 0},
                    "wind": {"speed": 5}
                }
            ]
        }
