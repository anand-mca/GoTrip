"""
Configuration settings for the Trip Planning API.
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings."""
    
    # API Keys (use environment variables in production)
    GOOGLE_PLACES_API_KEY: Optional[str] = None
    GOOGLE_DIRECTIONS_API_KEY: Optional[str] = None
    OPENWEATHER_API_KEY: Optional[str] = None
    
    # API Configuration
    USE_MOCK_DATA: bool = True  # Toggle for testing
    DEFAULT_RADIUS: int = 15000  # meters
    MAX_PLACES_PER_TRIP: int = 20
    
    # Scoring Constants
    RATING_WEIGHT: float = 0.3
    PREFERENCE_WEIGHT: float = 0.4
    DISTANCE_WEIGHT: float = 0.2
    POPULARITY_WEIGHT: float = 0.1
    
    # Budget Configuration
    AVG_COST_PER_PLACE: dict = {
        "beach": 500,
        "history": 800,
        "adventure": 2000,
        "food": 1500,
        "shopping": 3000,
        "nature": 600,
        "religious": 300,
        "cultural": 700,
    }
    
    # Time Configuration (in minutes)
    AVG_VISIT_TIME: dict = {
        "beach": 180,
        "history": 120,
        "adventure": 240,
        "food": 90,
        "shopping": 120,
        "nature": 150,
        "religious": 60,
        "cultural": 100,
    }
    
    AVG_TRAVEL_TIME: int = 30  # minutes between places
    
    # Weather Configuration
    WEATHER_IMPACT_THRESHOLD: float = 0.6  # rainfall probability threshold
    
    # Coordinates for testing
    CENTER_LAT: float = 28.6139  # New Delhi as example
    CENTER_LON: float = 77.2090
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
