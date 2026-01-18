"""
Mock data provider for testing and development.
Provides realistic mock places for trip planning.
"""
from typing import List
from app.models.schemas import PlaceModel, PreferenceEnum
import json


MOCK_PLACES_DATA = [
    # Beach Category
    {
        "id": "beach_001",
        "name": "Marina Beach",
        "category": "beach",
        "latitude": 13.0499,
        "longitude": 80.2824,
        "rating": 4.2,
        "reviews": 1250,
        "estimated_cost": 500,
        "description": "Popular urban beach with scenic views",
    },
    {
        "id": "beach_002",
        "name": "Goa Beach",
        "category": "beach",
        "latitude": 15.2993,
        "longitude": 73.8243,
        "rating": 4.5,
        "reviews": 3450,
        "estimated_cost": 600,
        "description": "Beautiful beach with water sports",
    },
    
    # History Category
    {
        "id": "history_001",
        "name": "Taj Mahal",
        "category": "history",
        "latitude": 27.1751,
        "longitude": 78.0421,
        "rating": 4.8,
        "reviews": 8900,
        "estimated_cost": 1000,
        "description": "Monument to love, UNESCO World Heritage Site",
    },
    {
        "id": "history_002",
        "name": "Red Fort",
        "category": "history",
        "latitude": 28.6562,
        "longitude": 77.2410,
        "rating": 4.3,
        "reviews": 2100,
        "estimated_cost": 800,
        "description": "Historic fortress and UNESCO World Heritage Site",
    },
    
    # Adventure Category
    {
        "id": "adventure_001",
        "name": "Skydiving in Dubai",
        "category": "adventure",
        "latitude": 25.1866,
        "longitude": 55.2747,
        "rating": 4.7,
        "reviews": 890,
        "estimated_cost": 3000,
        "description": "Thrilling skydiving experience over Palm Island",
    },
    {
        "id": "adventure_002",
        "name": "Trekking in Himalayas",
        "category": "adventure",
        "latitude": 30.5176,
        "longitude": 77.1891,
        "rating": 4.6,
        "reviews": 1200,
        "estimated_cost": 2500,
        "description": "Mountain trekking with stunning views",
    },
    
    # Food Category
    {
        "id": "food_001",
        "name": "Chandni Chowk Food Market",
        "category": "food",
        "latitude": 28.6505,
        "longitude": 77.2303,
        "rating": 4.4,
        "reviews": 2800,
        "estimated_cost": 1200,
        "description": "Famous food market with authentic street food",
    },
    {
        "id": "food_002",
        "name": "Michelin Star Restaurant",
        "category": "food",
        "latitude": 28.5355,
        "longitude": 77.3910,
        "rating": 4.9,
        "reviews": 450,
        "estimated_cost": 3500,
        "description": "Fine dining experience with international cuisine",
    },
    
    # Shopping Category
    {
        "id": "shopping_001",
        "name": "Delhi Shopping Mall",
        "category": "shopping",
        "latitude": 28.5244,
        "longitude": 77.0855,
        "rating": 4.3,
        "reviews": 3200,
        "estimated_cost": 2500,
        "description": "Premium shopping mall with international brands",
    },
    {
        "id": "shopping_002",
        "name": "Local Handicraft Market",
        "category": "shopping",
        "latitude": 28.6273,
        "longitude": 77.2197,
        "rating": 4.1,
        "reviews": 1500,
        "estimated_cost": 1500,
        "description": "Traditional handicrafts and souvenirs",
    },
    
    # Nature Category
    {
        "id": "nature_001",
        "name": "Himalayan National Park",
        "category": "nature",
        "latitude": 32.2432,
        "longitude": 77.1892,
        "rating": 4.7,
        "reviews": 890,
        "estimated_cost": 600,
        "description": "Pristine natural reserve with diverse wildlife",
    },
    {
        "id": "nature_002",
        "name": "Botanical Gardens",
        "category": "nature",
        "latitude": 28.5921,
        "longitude": 77.2101,
        "rating": 4.2,
        "reviews": 1100,
        "estimated_cost": 400,
        "description": "Beautiful gardens with rare plant species",
    },
    
    # Religious Category
    {
        "id": "religious_001",
        "name": "Varanasi Temple",
        "category": "religious",
        "latitude": 25.3201,
        "longitude": 82.9776,
        "rating": 4.6,
        "reviews": 2300,
        "estimated_cost": 300,
        "description": "Sacred temple on the banks of Ganges",
    },
    {
        "id": "religious_002",
        "name": "Amritsar Golden Temple",
        "category": "religious",
        "latitude": 31.6200,
        "longitude": 74.8765,
        "rating": 4.7,
        "reviews": 3400,
        "estimated_cost": 200,
        "description": "Holiest shrine of Sikhism",
    },
    
    # Cultural Category
    {
        "id": "cultural_001",
        "name": "National Museum",
        "category": "cultural",
        "latitude": 28.6131,
        "longitude": 77.2197,
        "rating": 4.3,
        "reviews": 1800,
        "estimated_cost": 600,
        "description": "Museum showcasing Indian cultural heritage",
    },
    {
        "id": "cultural_002",
        "name": "Classical Music Festival",
        "category": "cultural",
        "latitude": 28.5921,
        "longitude": 77.2045,
        "rating": 4.5,
        "reviews": 650,
        "estimated_cost": 800,
        "description": "Annual cultural festival with performances",
    },
]


def get_mock_places(
    preferences: List[str] = None,
    limit: int = 20
) -> List[PlaceModel]:
    """
    Get mock places filtered by preferences.
    
    Args:
        preferences: List of place categories to filter by
        limit: Maximum number of places to return
    
    Returns:
        List of PlaceModel instances
    """
    # Filter by preferences if provided
    if preferences:
        filtered_data = [
            p for p in MOCK_PLACES_DATA
            if p["category"] in preferences
        ]
    else:
        filtered_data = MOCK_PLACES_DATA
    
    # Convert to PlaceModel and return limited list
    places = [
        PlaceModel(**place) for place in filtered_data[:limit]
    ]
    
    return places
