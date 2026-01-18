"""
Main FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.routes import trip_planning
from app.utils.logger import get_logger

logger = get_logger(__name__)

# Create FastAPI app
app = FastAPI(
    title="GoTrip - Smart Trip Planning API",
    description="An intelligent travel itinerary planner using rule-based algorithms",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(trip_planning.router)


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "GoTrip - Smart Trip Planning API",
        "version": "1.0.0",
        "endpoints": {
            "docs": "/docs",
            "redoc": "/redoc",
            "plan_trip": "POST /api/plan-trip",
            "health": "GET /api/health"
        }
    }


@app.get("/info")
async def info():
    """Get API information and algorithm details."""
    return {
        "api_name": "GoTrip Smart Trip Planning API",
        "version": "1.0.0",
        "algorithms_used": {
            "scoring": "Multi-factor weighted scoring (Rating + Preferences + Popularity + Distance)",
            "selection": "Greedy algorithm respecting budget and time constraints",
            "optimization": "Nearest Neighbor heuristic for Traveling Salesman Problem",
            "weather_integration": "Rule-based weather adjustment and filtering"
        },
        "features": [
            "Multi-preference trip planning",
            "Budget-aware place selection",
            "Route optimization across multiple days",
            "Weather-based recommendations",
            "Day-wise itinerary generation",
            "Detailed cost and time estimates"
        ],
        "api_sources": {
            "production": ["Google Places API", "Google Directions API", "OpenWeatherMap API"],
            "fallback": "Mock data for testing and development"
        }
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
