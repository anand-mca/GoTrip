"""
Pydantic models for request/response validation and serialization.
"""
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime, date
from enum import Enum


class PreferenceEnum(str, Enum):
    """User preference categories."""
    BEACH = "beach"
    HISTORY = "history"
    ADVENTURE = "adventure"
    FOOD = "food"
    SHOPPING = "shopping"
    NATURE = "nature"
    RELIGIOUS = "religious"
    CULTURAL = "cultural"


class ItineraryItemRequest(BaseModel):
    """Request model for single trip item."""
    start_date: date
    end_date: date
    budget: float = Field(..., gt=0, description="Budget in currency units")
    preferences: List[PreferenceEnum] = Field(..., min_items=1, description="User preferences")
    city_name: Optional[str] = Field(None, min_length=1, description="Starting city name (e.g., 'Mumbai', 'Delhi')")
    latitude: Optional[float] = Field(None, ge=-90, le=90, description="(Deprecated) Use city_name instead")
    longitude: Optional[float] = Field(None, ge=-180, le=180, description="(Deprecated) Use city_name instead")
    
    @validator('end_date')
    def validate_dates(cls, v, values):
        """Ensure end_date is after start_date."""
        if 'start_date' in values and v <= values['start_date']:
            raise ValueError('end_date must be after start_date')
        return v
    
    @validator('city_name', 'latitude', 'longitude', pre=True)
    def validate_location_inputs(cls, v):
        """Strip whitespace from city name."""
        if isinstance(v, str):
            return v.strip()
        return v


class PlaceModel(BaseModel):
    """Model for a place/attraction."""
    id: str
    name: str
    category: PreferenceEnum
    latitude: float
    longitude: float
    rating: float = Field(default=4.0, ge=0, le=5)
    reviews: int = Field(default=100, ge=0)
    estimated_cost: float = Field(default=0, ge=0)
    description: str = ""
    city: Optional[str] = None
    state: Optional[str] = None
    photo_url: Optional[str] = None
    opening_hours: Optional[str] = None
    
    class Config:
        use_enum_values = False


class DayItinerary(BaseModel):
    """Model for a single day in the itinerary."""
    day: int
    date: date
    places: List[PlaceModel]
    total_distance: float = Field(default=0, description="Total distance in km")
    total_time: float = Field(default=0, description="Total time in minutes")
    estimated_budget: float = Field(default=0, description="Estimated cost for the day")


class TripItineraryResponse(BaseModel):
    """Response model for complete trip itinerary."""
    trip_id: str
    start_date: date
    end_date: date
    total_days: int
    total_distance: float = Field(default=0, description="Total distance in km")
    total_estimated_cost: float = Field(default=0, description="Total estimated cost")
    daily_itineraries: List[DayItinerary]
    algorithm_explanation: str = ""
    
    class Config:
        use_enum_values = False


class ErrorResponse(BaseModel):
    """Error response model."""
    error: str
    details: Optional[str] = None
    status_code: int = 400


class APIResponse(BaseModel):
    """Generic API response wrapper."""
    success: bool
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    message: Optional[str] = None
