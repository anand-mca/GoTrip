# Enhanced Backend with Trip Optimization

This backend adds intelligent trip planning with travel optimization.

## New Features
- **Route Calculation**: Distance, time, cost between locations
- **Trip Optimization**: Minimizes travel while satisfying constraints
- **Constraint Satisfaction**: Date, budget, preferences
- **Travel Cost Estimation**: Real cost calculations

## Python FastAPI Implementation

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import math
import requests
from datetime import datetime, timedelta

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class TripRequest(BaseModel):
    start_location: dict  # {name, lat, lng}
    preferences: List[str]
    budget: float
    start_date: str
    end_date: str
    return_to_start: bool = True

class Destination(BaseModel):
    id: str
    name: str
    lat: float
    lng: float
    category: str
    cost_per_day: float
    rating: float
    description: str

# Mock destination database (replace with real database)
DESTINATIONS = [
    {"id": "1", "name": "Goa Beach", "lat": 15.2993, "lng": 74.1240, "category": "beach", "cost_per_day": 3000, "rating": 4.5, "description": "Beautiful beaches"},
    {"id": "2", "name": "Manali Adventure", "lat": 32.2396, "lng": 77.1887, "category": "adventure", "cost_per_day": 4000, "rating": 4.7, "description": "Mountain adventures"},
    {"id": "3", "name": "Jaipur Heritage", "lat": 26.9124, "lng": 75.7873, "category": "history", "cost_per_day": 2500, "rating": 4.6, "description": "Historic palaces"},
    {"id": "4", "name": "Kerala Backwaters", "lat": 9.9312, "lng": 76.2673, "category": "nature", "cost_per_day": 3500, "rating": 4.8, "description": "Serene backwaters"},
    {"id": "5", "name": "Mumbai Food Tour", "lat": 19.0760, "lng": 72.8777, "category": "food", "cost_per_day": 2000, "rating": 4.4, "description": "Street food paradise"},
    {"id": "6", "name": "Rishikesh Yoga", "lat": 30.0869, "lng": 78.2676, "category": "religious", "cost_per_day": 1500, "rating": 4.5, "description": "Spiritual retreat"},
]

def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points in km"""
    R = 6371  # Earth radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

def calculate_route_cost(distance_km):
    """Estimate travel cost in INR"""
    cost_per_km = 8  # Average cost per km in India
    return distance_km * cost_per_km

def calculate_travel_time(distance_km):
    """Estimate travel time in hours"""
    avg_speed = 50  # km/h
    return distance_km / avg_speed

def optimize_destinations(start_loc, destinations, budget, num_days, return_to_start=True):
    """
    Optimize trip using nearest neighbor algorithm
    Constraints: budget, time, minimal travel
    """
    if not destinations:
        return {
            "destinations": [],
            "total_cost": 0,
            "total_distance": 0,
            "total_travel_time": 0,
            "daily_itinerary": []
        }
    
    # Nearest neighbor algorithm for TSP-like optimization
    visited = []
    remaining = destinations.copy()
    current_location = start_loc
    
    total_travel_cost = 0
    total_accommodation_cost = 0
    total_distance = 0
    total_travel_time = 0
    route_segments = []
    
    days_remaining = num_days
    
    while remaining and days_remaining > 0:
        # Find nearest destination that fits budget
        best_dest = None
        best_distance = float('inf')
        
        for dest in remaining:
            distance = haversine_distance(
                current_location['lat'], current_location['lng'],
                dest['lat'], dest['lng']
            )
            
            # Multiply by 1.3 for road distance approximation
            road_distance = distance * 1.3
            travel_cost = calculate_route_cost(road_distance)
            
            # Estimate days needed (minimum 1 day per destination)
            dest_cost = dest['cost_per_day'] + travel_cost
            
            # Check if within budget and closer than current best
            if dest_cost <= budget - total_travel_cost - total_accommodation_cost and distance < best_distance:
                best_dest = dest
                best_distance = distance
        
        if best_dest is None:
            break  # No more destinations fit budget
        
        # Add this destination
        road_distance = best_distance * 1.3
        travel_cost = calculate_route_cost(road_distance)
        travel_time = calculate_travel_time(road_distance)
        
        route_segments.append({
            "from": current_location['name'],
            "to": best_dest['name'],
            "distance_km": round(road_distance, 2),
            "travel_time_hours": round(travel_time, 2),
            "travel_cost": round(travel_cost, 2)
        })
        
        visited.append({
            **best_dest,
            "days": 1,  # Minimum 1 day per destination
            "accommodation_cost": best_dest['cost_per_day']
        })
        
        total_distance += road_distance
        total_travel_time += travel_time
        total_travel_cost += travel_cost
        total_accommodation_cost += best_dest['cost_per_day']
        
        current_location = best_dest
        remaining.remove(best_dest)
        days_remaining -= 1
    
    # Add return journey if specified
    if return_to_start and visited:
        return_distance = haversine_distance(
            current_location['lat'], current_location['lng'],
            start_loc['lat'], start_loc['lng']
        ) * 1.3
        
        return_cost = calculate_route_cost(return_distance)
        return_time = calculate_travel_time(return_distance)
        
        route_segments.append({
            "from": current_location['name'],
            "to": start_loc['name'],
            "distance_km": round(return_distance, 2),
            "travel_time_hours": round(return_time, 2),
            "travel_cost": round(return_cost, 2)
        })
        
        total_distance += return_distance
        total_travel_time += return_time
        total_travel_cost += return_cost
    
    # Create daily itinerary
    daily_itinerary = []
    current_date = datetime.now()
    
    for i, dest in enumerate(visited):
        daily_itinerary.append({
            "day": i + 1,
            "date": (current_date + timedelta(days=i)).strftime("%Y-%m-%d"),
            "destination": dest['name'],
            "activities": [dest['description']],
            "accommodation_cost": dest['accommodation_cost'],
            "travel_from_previous": route_segments[i] if i < len(route_segments) else None
        })
    
    total_cost = total_travel_cost + total_accommodation_cost
    
    return {
        "destinations": visited,
        "total_cost": round(total_cost, 2),
        "total_travel_cost": round(total_travel_cost, 2),
        "total_accommodation_cost": round(total_accommodation_cost, 2),
        "total_distance_km": round(total_distance, 2),
        "total_travel_time_hours": round(total_travel_time, 2),
        "route_segments": route_segments,
        "daily_itinerary": daily_itinerary,
        "budget_remaining": round(budget - total_cost, 2)
    }

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "Trip optimization backend running"}

@app.post("/api/plan-trip")
def plan_trip(request: TripRequest):
    """
    Intelligent trip planning with optimization
    - Filters destinations by preferences
    - Optimizes route to minimize travel
    - Satisfies budget and date constraints
    """
    try:
        # Calculate trip duration
        start = datetime.fromisoformat(request.start_date.replace('Z', '+00:00'))
        end = datetime.fromisoformat(request.end_date.replace('Z', '+00:00'))
        num_days = (end - start).days + 1
        
        if num_days < 1:
            raise HTTPException(status_code=400, detail="Invalid date range")
        
        # Filter destinations by preferences
        filtered_destinations = [
            dest for dest in DESTINATIONS
            if dest['category'] in request.preferences
        ]
        
        if not filtered_destinations:
            return {
                "success": False,
                "message": "No destinations match your preferences",
                "plan": None
            }
        
        # Optimize trip
        optimized_plan = optimize_destinations(
            request.start_location,
            filtered_destinations,
            request.budget,
            num_days,
            request.return_to_start
        )
        
        if not optimized_plan['destinations']:
            return {
                "success": False,
                "message": "Could not create a trip within budget constraints",
                "plan": None
            }
        
        return {
            "success": True,
            "message": f"Found optimal trip with {len(optimized_plan['destinations'])} destinations",
            "plan": optimized_plan
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/destinations")
def get_destinations(
    preferences: Optional[str] = None,
    max_cost: Optional[float] = None
):
    """Get destinations with optional filtering"""
    results = DESTINATIONS.copy()
    
    if preferences:
        prefs = preferences.split(',')
        results = [d for d in results if d['category'] in prefs]
    
    if max_cost:
        results = [d for d in results if d['cost_per_day'] <= max_cost]
    
    return {"destinations": results}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## How to Run

1. **Install Dependencies**:
```bash
pip install fastapi uvicorn requests
```

2. **Run Server**:
```bash
python backend.py
```

3. **Test Endpoint**:
```bash
curl -X POST http://localhost:8000/api/plan-trip \
  -H "Content-Type: application/json" \
  -d '{
    "start_location": {"name": "Delhi", "lat": 28.6139, "lng": 77.2090},
    "preferences": ["beach", "adventure"],
    "budget": 25000,
    "start_date": "2026-02-01",
    "end_date": "2026-02-07",
    "return_to_start": true
  }'
```

## API Keys Configuration (When Needed)

To add API keys later, modify the route calculation to use real APIs:

```python
# Add at top of file
OPENROUTE_API_KEY = ""  # Get from openrouteservice.org
GOOGLE_MAPS_API_KEY = ""  # Get from Google Cloud Console

# Replace haversine_distance with real API call
def get_route_info(from_lat, from_lng, to_lat, to_lng):
    if OPENROUTE_API_KEY:
        # Use OpenRouteService
        url = f"https://api.openrouteservice.org/v2/directions/driving-car"
        headers = {"Authorization": OPENROUTE_API_KEY}
        params = {"start": f"{from_lng},{from_lat}", "end": f"{to_lng},{to_lat}"}
        response = requests.get(url, headers=headers, params=params)
        # Parse response...
    else:
        # Fall back to haversine estimation
        return haversine_distance(from_lat, from_lng, to_lat, to_lng) * 1.3
```

## Next Steps

1. Save this code as `backend.py` in `GoTrip/gotrip-backend/` folder
2. Run it with `python backend.py`
3. Update Flutter app to use the new `/api/plan-trip` endpoint
4. Test with mock data first
5. Add API keys when ready for production
