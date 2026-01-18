"""
REST API routes for trip planning.
"""
from fastapi import APIRouter, HTTPException, status
from app.models.schemas import ItineraryItemRequest, TripItineraryResponse, APIResponse
from app.services.trip_planning_service import TripPlanningService
from app.utils.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/api", tags=["trip-planning"])

# Initialize service
trip_service = TripPlanningService()


@router.post("/plan-trip", response_model=TripItineraryResponse, status_code=status.HTTP_200_OK)
async def plan_trip(request: ItineraryItemRequest) -> TripItineraryResponse:
    """
    Plan a smart trip based on user preferences, budget, and dates.
    
    This endpoint accepts trip parameters and returns a day-wise optimized itinerary
    with places, routes, and estimated costs.
    
    **Request Body:**
    - `start_date`: Trip start date (YYYY-MM-DD)
    - `end_date`: Trip end date (YYYY-MM-DD)
    - `budget`: Total trip budget in currency units
    - `preferences`: List of preferred place categories (beach, history, adventure, food, shopping, nature, religious, cultural)
    - `latitude`: (Optional) Center latitude for location-based filtering
    - `longitude`: (Optional) Center longitude for location-based filtering
    
    **Response:**
    - `trip_id`: Unique identifier for the planned trip
    - `start_date`: Trip start date
    - `end_date`: Trip end date
    - `total_days`: Total number of days in the trip
    - `total_distance`: Total travel distance in kilometers
    - `total_estimated_cost`: Total estimated cost for the trip
    - `daily_itineraries`: List of day-wise itineraries with places and metrics
    - `algorithm_explanation`: Detailed explanation of the planning algorithm
    
    **Example Request:**
    ```json
    {
        "start_date": "2026-02-01",
        "end_date": "2026-02-05",
        "budget": 50000,
        "preferences": ["beach", "food", "adventure"],
        "latitude": 28.6139,
        "longitude": 77.2090
    }
    ```
    
    **Example Response:**
    ```json
    {
        "trip_id": "550e8400-e29b-41d4-a716-446655440000",
        "start_date": "2026-02-01",
        "end_date": "2026-02-05",
        "total_days": 5,
        "total_distance": 245.5,
        "total_estimated_cost": 49500,
        "daily_itineraries": [
            {
                "day": 1,
                "date": "2026-02-01",
                "places": [
                    {
                        "id": "beach_001",
                        "name": "Marina Beach",
                        "category": "beach",
                        "latitude": 13.0499,
                        "longitude": 80.2824,
                        "rating": 4.2,
                        "reviews": 1250,
                        "estimated_cost": 500,
                        "description": "Popular urban beach with scenic views"
                    }
                ],
                "total_distance": 52.3,
                "total_time": 240,
                "estimated_budget": 9850
            }
        ],
        "algorithm_explanation": "Trip Plan Algorithm: ..."
    }
    ```
    """
    try:
        logger.info(f"Received trip planning request: {request}")
        
        # Generate itinerary
        itinerary = trip_service.plan_trip(request)
        
        logger.info(f"Successfully planned trip: {itinerary.trip_id}")
        return itinerary
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid input: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred while planning the trip"
        )


@router.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {"status": "healthy", "service": "trip-planning-api"}


@router.post("/test-request")
async def test_request_example() -> APIResponse:
    """
    Returns example request format for trip planning.
    Useful for frontend developers to understand the API contract.
    """
    example = {
        "start_date": "2026-02-01",
        "end_date": "2026-02-05",
        "budget": 50000,
        "preferences": ["beach", "food", "adventure"],
        "latitude": 28.6139,
        "longitude": 77.2090
    }
    
    return APIResponse(
        success=True,
        data={"example_request": example},
        message="Use this format to make a request to /api/plan-trip"
    )
