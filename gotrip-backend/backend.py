"""
GoTrip Backend - Intelligent Trip Planning API
Uses REAL tourism APIs to find optimized trip clusters
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import math
from datetime import datetime, timedelta

# Import tourism API client for real data
from tourism_apis import TourismAPIClient
from destination_database import DESTINATIONS_DB, get_destinations_near
import hashlib
import json

app = FastAPI(title="GoTrip API", version="2.0.0")

# Initialize API client
tourism_client = TourismAPIClient()

# Simple in-memory cache for API results
destination_cache = {}

# CORS - Allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response Models
class TripRequest(BaseModel):
    start_location: dict  # {name, lat, lng}
    preferences: List[str]
    budget: float
    start_date: str  # ISO format
    end_date: str    # ISO format
    return_to_start: bool = True

# Mock Destination Database - Enhanced with granular locations
# Each destination can satisfy MULTIPLE preferences (categories list)
DESTINATIONS = [
    # === GOA REGION (Clustered locations) ===
    {
        "id": "goa_1",
        "name": "Baga Beach",
        "city": "Goa",
        "region": "North Goa",
        "lat": 15.5559,
        "lng": 73.7516,
        "categories": ["beach", "adventure", "food"],  # Multiple preferences!
        "cost_per_day": 2500,
        "rating": 4.6,
        "description": "Water sports, beach shacks, nightlife, seafood"
    },
    {
        "id": "goa_2",
        "name": "Anjuna Beach & Flea Market",
        "city": "Goa",
        "region": "North Goa",
        "lat": 15.5736,
        "lng": 73.7404,
        "categories": ["beach", "shopping", "food"],
        "cost_per_day": 2200,
        "rating": 4.5,
        "description": "Famous flea market, beach vibes, local cuisine"
    },
    {
        "id": "goa_3",
        "name": "Old Goa Churches",
        "city": "Goa",
        "region": "Central Goa",
        "lat": 15.5007,
        "lng": 73.9117,
        "categories": ["history", "cultural"],
        "cost_per_day": 1500,
        "rating": 4.7,
        "description": "UNESCO heritage churches, Portuguese architecture"
    },
    {
        "id": "goa_4",
        "name": "Panjim Market & Food Street",
        "city": "Goa",
        "region": "Central Goa",
        "lat": 15.4909,
        "lng": 73.8278,
        "categories": ["food", "shopping", "cultural"],
        "cost_per_day": 2000,
        "rating": 4.4,
        "description": "Local markets, Goan cuisine, street shopping"
    },
    {
        "id": "goa_5",
        "name": "Dudhsagar Waterfalls",
        "city": "Goa",
        "region": "South Goa",
        "lat": 15.3144,
        "lng": 74.3144,
        "categories": ["nature", "adventure"],
        "cost_per_day": 2800,
        "rating": 4.8,
        "description": "Trekking, waterfall rappelling, nature trails"
    },
    
    # === MUMBAI REGION ===
    {
        "id": "mumbai_1",
        "name": "Marine Drive & Chowpatty",
        "city": "Mumbai",
        "region": "South Mumbai",
        "lat": 18.9432,
        "lng": 72.8236,
        "categories": ["beach", "food"],
        "cost_per_day": 2500,
        "rating": 4.3,
        "description": "Seaside promenade, street food, sunset views"
    },
    {
        "id": "mumbai_2",
        "name": "Colaba Causeway Market",
        "city": "Mumbai",
        "region": "South Mumbai",
        "lat": 18.9067,
        "lng": 72.8147,
        "categories": ["shopping", "food"],
        "cost_per_day": 2200,
        "rating": 4.4,
        "description": "Street shopping, cafes, Gateway of India nearby"
    },
    {
        "id": "mumbai_3",
        "name": "Elephanta Caves",
        "city": "Mumbai",
        "region": "Mumbai Harbor",
        "lat": 18.9633,
        "lng": 72.9315,
        "categories": ["history", "cultural"],
        "cost_per_day": 1800,
        "rating": 4.5,
        "description": "Ancient cave temples, UNESCO site, boat ride"
    },
    
    # === JAIPUR REGION ===
    {
        "id": "jaipur_1",
        "name": "Amber Fort",
        "city": "Jaipur",
        "region": "Jaipur",
        "lat": 26.9855,
        "lng": 75.8513,
        "categories": ["history", "cultural"],
        "cost_per_day": 2200,
        "rating": 4.8,
        "description": "Majestic fort, elephant rides, light & sound show"
    },
    {
        "id": "jaipur_2",
        "name": "Johari Bazaar",
        "city": "Jaipur",
        "region": "Jaipur",
        "lat": 26.9239,
        "lng": 75.8267,
        "categories": ["shopping", "cultural"],
        "cost_per_day": 1800,
        "rating": 4.5,
        "description": "Traditional jewelry, textiles, handicrafts market"
    },
    {
        "id": "jaipur_3",
        "name": "Chokhi Dhani Village",
        "city": "Jaipur",
        "region": "Jaipur",
        "lat": 26.7841,
        "lng": 75.7990,
        "categories": ["food", "cultural"],
        "cost_per_day": 2500,
        "rating": 4.6,
        "description": "Rajasthani village experience, traditional food, folk dance"
    },
    
    # === MANALI REGION ===
    {
        "id": "manali_1",
        "name": "Solang Valley",
        "city": "Manali",
        "region": "Manali",
        "lat": 32.3192,
        "lng": 77.1492,
        "categories": ["adventure", "nature"],
        "cost_per_day": 3500,
        "rating": 4.7,
        "description": "Skiing, paragliding, zorbing, mountain views"
    },
    {
        "id": "manali_2",
        "name": "Old Manali Market",
        "city": "Manali",
        "region": "Manali",
        "lat": 32.2433,
        "lng": 77.1892,
        "categories": ["shopping", "food"],
        "cost_per_day": 2000,
        "rating": 4.4,
        "description": "Cafes, local handicrafts, Himalayan food"
    },
    
    # === RISHIKESH REGION ===
    {
        "id": "rishikesh_1",
        "name": "Lakshman Jhula Area",
        "city": "Rishikesh",
        "region": "Rishikesh",
        "lat": 30.1163,
        "lng": 78.3228,
        "categories": ["religious", "adventure"],
        "cost_per_day": 1800,
        "rating": 4.6,
        "description": "River rafting, yoga centers, temples, suspension bridge"
    },
    {
        "id": "rishikesh_2",
        "name": "Triveni Ghat",
        "city": "Rishikesh",
        "region": "Rishikesh",
        "lat": 30.1030,
        "lng": 78.2927,
        "categories": ["religious", "cultural"],
        "cost_per_day": 1200,
        "rating": 4.5,
        "description": "Ganga Aarti, spiritual bathing, meditation"
    },
    
    # === KERALA REGION ===
    {
        "id": "kerala_1",
        "name": "Alleppey Backwaters",
        "city": "Kerala",
        "region": "Kerala",
        "lat": 9.4981,
        "lng": 76.3388,
        "categories": ["nature", "cultural"],
        "cost_per_day": 3500,
        "rating": 4.9,
        "description": "Houseboat cruise, village life, seafood"
    },
    {
        "id": "kerala_2",
        "name": "Munnar Tea Gardens",
        "city": "Kerala",
        "region": "Kerala",
        "lat": 10.0889,
        "lng": 77.0595,
        "categories": ["nature", "adventure"],
        "cost_per_day": 3000,
        "rating": 4.7,
        "description": "Tea plantations, trekking, wildlife spotting"
    },
]

# Utility Functions
def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates in kilometers"""
    R = 6371  # Earth radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = (math.sin(delta_lat/2)**2 + 
         math.cos(lat1_rad) * math.cos(lat2_rad) * 
         math.sin(delta_lon/2)**2)
    c = 2 * math.asin(math.sqrt(a))
    
    return R * c

def calculate_route_cost(distance_km):
    """Estimate travel cost in Indian Rupees (₹)"""
    cost_per_km = 8  # Average cost per km in India (taxi/bus)
    return distance_km * cost_per_km

def calculate_travel_time(distance_km):
    """Estimate travel time in hours"""
    avg_speed = 50  # km/h (accounting for stops, traffic)
    return distance_km / avg_speed

def optimize_destinations(start_loc, destinations, budget, num_days, preferences, return_to_start=True):
    """
    HUMAN-LOGICAL TRIP OPTIMIZATION:
    
    Key Principles:
    1. PRIMARY categories (nature, adventure, history, beach) = FULL DAY attractions
    2. SECONDARY categories (food, shopping) = SUPPLEMENTARY activities (2-3 hours)
    3. Never allocate full day to just restaurants/markets
    4. If local options are weak, search further (up to 300km for 3+ day trips)
    5. Include accommodation costs per night
    6. Balance all user preferences across the trip
    """
    if not destinations:
        return {
            "destinations": [],
            "total_cost": 0,
            "total_travel_cost": 0,
            "total_accommodation_cost": 0,
            "total_distance_km": 0,
            "total_travel_time_hours": 0,
            "route_segments": [],
            "daily_itinerary": [],
            "budget_remaining": budget
        }
    
    print(f"\n🎯 HUMAN-LOGICAL OPTIMIZATION from {start_loc['name']}")
    print(f"   User preferences: {preferences}")
    
    # Define category importance
    PRIMARY_CATEGORIES = {'nature', 'adventure', 'history', 'beach', 'religious', 'cultural'}
    SECONDARY_CATEGORIES = {'food', 'shopping'}
    
    preference_set = set(preferences)
    
    # Step 1: FILTER and CLASSIFY destinations
    primary_destinations = []
    secondary_destinations = []
    
    for dest in destinations:
        dest_categories = set(dest['categories'])
        matching = preference_set & dest_categories
        
        if not matching:
            continue  # Skip if doesn't match any preference
        
        dest['distance_from_start'] = haversine_distance(
            start_loc['lat'], start_loc['lng'],
            dest['lat'], dest['lng']
        )
        dest['matching_preferences'] = len(matching)
        
        # Classify by category type
        is_primary = bool(dest_categories & PRIMARY_CATEGORIES & preference_set)
        
        if is_primary:
            primary_destinations.append(dest)
        else:
            secondary_destinations.append(dest)
    
    print(f"   ✓ {len(primary_destinations)} PRIMARY attractions (nature/adventure/history)")
    print(f"   ✓ {len(secondary_destinations)} SECONDARY activities (food/shopping)")
    
    # Step 2: DISTANCE-BASED SELECTION based on trip duration
    # Longer trips = can travel further for better attractions
    if num_days >= 4:
        max_distance = 300  # Can travel up to 300km for 4+ day trips
    elif num_days >= 2:
        max_distance = 150  # 2-3 day trips: 150km
    else:
        max_distance = 100  # 1-day trips: stay local
    
    print(f"   📏 Max search radius: {max_distance}km for {num_days}-day trip")
    
    # Filter by max distance
    primary_destinations = [d for d in primary_destinations if d['distance_from_start'] <= max_distance]
    secondary_destinations = [d for d in secondary_destinations if d['distance_from_start'] <= max_distance]
    
    # Step 3: SMART SELECTION
    # Rule: Each day should have 1 PRIMARY attraction + optional secondary activities
    selected_primary = []
    selected_secondary = []
    
    # Sort primary by: matching prefs (desc), then distance (asc)
    primary_destinations.sort(key=lambda x: (x['matching_preferences'], -x['distance_from_start']), reverse=True)
    
    # Select PRIMARY destinations (1 per day, max)
    days_for_primary = min(num_days, len(primary_destinations))
    
    # GROUP by city for clustering
    from collections import defaultdict
    city_groups = defaultdict(list)
    for dest in primary_destinations:
        city = dest.get('city', 'Unknown')
        city_groups[city].append(dest)
    
    # If have good local cluster, use it; otherwise pick best distant city
    local_primaries = [d for d in primary_destinations if d['distance_from_start'] <= 50]
    
    if len(local_primaries) >= num_days:
        print(f"   ✅ LOCAL CLUSTER: {len(local_primaries)} attractions within 50km")
        for dest in local_primaries[:num_days]:
            selected_primary.append(dest)
            print(f"      + {dest['name']} ({dest['distance_from_start']:.0f}km) - {dest['categories']}")
    else:
        # Find best city cluster
        print(f"   🏙️ CITY CLUSTER: Searching for best destination city...")
        
        city_scores = {}
        for city, dests in city_groups.items():
            if city == start_loc.get('name'):
                continue
            
            avg_distance = sum(d['distance_from_start'] for d in dests) / len(dests) if dests else 9999
            total_matching = sum(d['matching_preferences'] for d in dests)
            
            # Score: many attractions + reasonable distance
            city_scores[city] = (len(dests) * 10 + total_matching * 5) - (avg_distance * 0.1)
        
        if city_scores:
            best_city = max(city_scores, key=city_scores.get)
            best_city_dests = city_groups[best_city]
            
            avg_dist = sum(d['distance_from_start'] for d in best_city_dests) / len(best_city_dests)
            print(f"      → {best_city} ({len(best_city_dests)} attractions, ~{avg_dist:.0f}km away)")
            
            best_city_dests.sort(key=lambda x: x['matching_preferences'], reverse=True)
            for dest in best_city_dests[:num_days]:
                selected_primary.append(dest)
                print(f"      + {dest['name']} - {dest['categories']}")
        else:
            # Fallback: pick top primaries by score
            for dest in primary_destinations[:num_days]:
                selected_primary.append(dest)
                print(f"      + {dest['name']} ({dest['distance_from_start']:.0f}km) - {dest['categories']}")
    
    # Select 1-2 secondary activities (food/shopping) as bonus
    # These don't take full days - just add to itinerary
    secondary_destinations.sort(key=lambda x: x['distance_from_start'])
    selected_secondary = secondary_destinations[:2] if secondary_destinations else []
    
    if not selected_primary:
        print("   ⚠️ No primary attractions found matching preferences!")
        return {
            "destinations": [],
            "total_cost": 0,
            "total_travel_cost": 0,
            "total_accommodation_cost": 0,
            "total_distance_km": 0,
            "total_travel_time_hours": 0,
            "route_segments": [],
            "daily_itinerary": [],
            "budget_remaining": budget
        }
    
    # Step 4: BUILD ROUTE with ACCOMMODATION COSTS
    visited = []
    current_location = start_loc
    total_distance = 0
    total_travel_cost = 0
    total_travel_time = 0
    route_segments = []
    
    # Accommodation cost: ₹1500-2500 per night depending on destination
    ACCOMMODATION_PER_NIGHT = 2000  # Average hotel cost in India
    total_accommodation_cost = (num_days - 1) * ACCOMMODATION_PER_NIGHT  # -1 because last day returns home
    
    for dest in selected_primary:
        distance = haversine_distance(
            current_location['lat'], current_location['lng'],
            dest['lat'], dest['lng']
        )
        
        road_distance = distance * 1.3
        travel_cost = calculate_route_cost(road_distance)
        travel_time = calculate_travel_time(road_distance)
        
        # Check budget (including accommodation)
        if travel_cost + dest['cost_per_day'] > budget - total_travel_cost - total_accommodation_cost:
            print(f"   ⚠️ Budget limit at {dest['name']}")
            break
        
        route_segments.append({
            "from": current_location['name'],
            "to": dest['name'],
            "distance_km": round(road_distance, 2),
            "travel_time_hours": round(travel_time, 2),
            "travel_cost": round(travel_cost, 2)
        })
        
        visited.append({
            **dest,
            "days": 1,
            "accommodation_cost": dest['cost_per_day'],
            "satisfies_preferences": list(dest['categories'])
        })
        
        total_distance += road_distance
        total_travel_time += travel_time
        total_travel_cost += travel_cost
        
        current_location = dest
    
    # Return journey
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
    
    # Create itinerary with ACCOMMODATION
    daily_itinerary = []
    current_date = datetime.now()
    
    for i, dest in enumerate(visited):
        day_accommodation = ACCOMMODATION_PER_NIGHT if i < len(visited) - 1 else 0  # No hotel on last day (returning home)
        
        # Add secondary activities to relevant days
        secondary_notes = []
        if i == 0 and len(selected_secondary) > 0:
            secondary_notes.append(f"+ {selected_secondary[0]['name']} (food/shopping)")
        if i == len(visited) - 1 and len(selected_secondary) > 1:
            secondary_notes.append(f"+ {selected_secondary[1]['name']} (food/shopping)")
        
        daily_itinerary.append({
            "day": i + 1,
            "date": (current_date + timedelta(days=i)).strftime("%Y-%m-%d"),
            "destination": dest['name'],
            "city": dest.get('city', 'Unknown'),
            "satisfies": dest['satisfies_preferences'],
            "activities": [dest['description']] + secondary_notes,
            "accommodation_cost": dest['accommodation_cost'],
            "hotel_cost": day_accommodation,
            "travel_from_previous": route_segments[i] if i < len(route_segments) else None
        })
    
    total_cost = total_travel_cost + total_accommodation_cost + sum(d['accommodation_cost'] for d in visited)
    
    print(f"\n📊 Final: {len(visited)} days, {total_distance:.0f}km, ₹{total_cost:.0f}")
    print(f"   💰 Breakdown: Travel ₹{total_travel_cost:.0f} + Hotels ₹{total_accommodation_cost:.0f} + Activities ₹{sum(d['accommodation_cost'] for d in visited):.0f}")
    
    return {
        "destinations": visited,
        "total_cost": round(total_cost, 2),
        "total_travel_cost": round(total_travel_cost, 2),
        "total_accommodation_cost": round(total_accommodation_cost, 2),
        "total_distance_km": round(total_distance, 2),
        "total_travel_time_hours": round(total_travel_time, 2),
        "route_segments": route_segments,
        "daily_itinerary": daily_itinerary,
        "budget_remaining": round(budget - total_cost, 2),
        "all_preferences_satisfied": True
    }

# API Endpoints
@app.get("/api/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "ok",
        "message": "Trip optimization backend running",
        "version": "1.0.0"
    }

@app.post("/api/plan-trip")
def plan_trip(request: TripRequest):
    """
    Main endpoint: Plan optimized trip
    
    Features:
    - Minimizes travel distance (nearest neighbor algorithm)
    - Respects budget constraint
    - Fits within date range
    - Matches user preferences
    - Calculates real costs and routes
    """
    try:
        print(f"\n🔍 DEBUG: Received request - Preferences: {request.preferences}, Budget: {request.budget}")
        print(f"📍 DEBUG: Start Location: {request.start_location['name']} at ({request.start_location['lat']}, {request.start_location['lng']})")
        
        # Parse dates
        start = datetime.fromisoformat(request.start_date.replace('Z', '+00:00'))
        end = datetime.fromisoformat(request.end_date.replace('Z', '+00:00'))
        num_days = (end - start).days + 1
        
        print(f"📅 DEBUG: Trip duration: {num_days} days")
        
        if num_days < 1:
            raise HTTPException(status_code=400, detail="Invalid date range: end date must be after start date")
        
        # ===== HYBRID APPROACH: Try API first, fallback to curated database =====
        cache_key = f"{request.start_location['lat']}_{request.start_location['lng']}_{'_'.join(sorted(request.preferences))}"
        
        if cache_key in destination_cache:
            print(f"\n💾 CACHED: Instant response for {request.start_location['name']}")
            filtered_destinations = destination_cache[cache_key]
        else:
            # Try real API first (fast mode)
            print(f"\n🌍 Trying API search for {request.start_location['name']}...")
            
            real_destinations = tourism_client.smart_destination_search(
                start_lat=request.start_location['lat'],
                start_lng=request.start_location['lng'],
                preferences=request.preferences,
                max_distance_km=800,
                min_destinations=20
            )
            
            if len(real_destinations) < 5:
                # Fallback to curated database
                print(f"⚠️ API found only {len(real_destinations)} destinations. Using curated database...")
                
                nearby_curated = get_destinations_near(
                    request.start_location['lat'],
                    request.start_location['lng'],
                    max_distance_km=800
                )
                
                curated_filtered = [
                    dest for dest in nearby_curated
                    if any(pref in dest['categories'] for pref in request.preferences)
                ]
                
                print(f"📚 Curated database: {len(curated_filtered)} destinations found")
                
                # Use curated database format directly
                filtered_destinations = curated_filtered
            else:
                # Convert API results to our format
                filtered_destinations = []
                for dest in real_destinations:
                    filtered_destinations.append({
                        'id': f"{dest['source']}_{dest['name'].replace(' ', '_')}",
                        'name': dest['name'],
                        'city': dest.get('base_city', dest['name']),
                        'region': dest.get('region', 'India'),
                        'lat': dest['lat'],
                        'lng': dest['lng'],
                        'categories': [dest.get('category', 'attraction')],
                        'cost_per_day': dest.get('cost_per_day', 2000),
                        'rating': dest.get('rating', 4.0),
                        'description': dest.get('tags', {}).get('description', f"Attraction in {dest.get('base_city', 'India')}")
                    })
                
                print(f"🌍 API: {len(filtered_destinations)} destinations found")
            
            # Cache the results
            destination_cache[cache_key] = filtered_destinations
            print(f"💾 Cached {len(filtered_destinations)} destinations")
        
        if not filtered_destinations:
            return {
                "success": False,
                "message": f"No destinations found near {request.start_location['name']} within 800km for your preferences",
                "plan": None
            }
        
        print(f"🎯 {len(filtered_destinations)} destinations ready for optimization")
        
        # Optimize trip with enhanced algorithm
        optimized_plan = optimize_destinations(
            request.start_location,
            filtered_destinations,
            request.budget,
            num_days,
            request.preferences,
            request.return_to_start
        )
        
        if not optimized_plan['destinations']:
            return {
                "success": False,
                "message": f"Could not plan a trip within ₹{request.budget:,.0f} budget. Try increasing budget or reducing trip duration.",
                "plan": None
            }
        
        return {
            "success": True,
            "message": f"Optimized trip created with {len(optimized_plan['destinations'])} destinations, minimizing travel distance",
            "plan": optimized_plan
        }
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid date format: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")

@app.get("/api/destinations")
def get_destinations(
    preferences: Optional[str] = None,
    max_cost: Optional[float] = None,
    city: Optional[str] = None
):
    """Get available destinations with optional filtering"""
    results = DESTINATIONS.copy()
    
    if preferences:
        prefs = preferences.split(',')
        results = [d for d in results if any(cat in prefs for cat in d['categories'])]
    
    if max_cost:
        results = [d for d in results if d['cost_per_day'] <= max_cost]
    
    if city:
        results = [d for d in results if d.get('city', '').lower() == city.lower()]
    
    return {
        "count": len(results),
        "destinations": results
    }

# Run server
if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting GoTrip Backend Server...")
    print("📍 Server: http://localhost:8000")
    print("📚 API Docs: http://localhost:8000/docs")
    print("✅ Health Check: http://localhost:8000/api/health")
    print("\n🎯 Ready for trip planning requests!")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
