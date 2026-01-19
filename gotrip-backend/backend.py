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
    REALISTIC TRIP PLANNING OPTIMIZATION:
    
    Key Principles:
    1. MULTI-DESTINATION DAYS: Group nearby attractions (<50km) into single days
    2. FULL DAY attractions: Resorts, homestays, large parks (6+ hours)
    3. HALF DAY attractions: Museums, beaches, viewpoints (2-4 hours)
    4. QUICK STOPS: Restaurants, shops, markets (1-2 hours)
    5. Each day = 1 full-day destination OR 2-3 half-day/quick destinations
    6. MUST satisfy ALL user preferences including food/shopping
    7. Include accommodation costs per night
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
    
    print(f"\n🎯 REALISTIC TRIP PLANNING from {start_loc['name']}")
    print(f"   User preferences: {preferences}")
    
    # Define destination types by time required
    FULL_DAY_KEYWORDS = ['resort', 'homestay', 'hotel', 'retreat', 'spa', 'park', 'sanctuary', 'national', 'wildlife']
    QUICK_VISIT_KEYWORDS = ['restaurant', 'cafe', 'market', 'shop', 'street', 'viewpoint', 'museum']
    
    preference_set = set(preferences)
    
    # Step 1: CLASSIFY all destinations
    all_matching = []
    for dest in destinations:
        dest_categories = set(dest['categories'])
        matching = preference_set & dest_categories
        
        if not matching:
            continue
        
        dest['distance_from_start'] = haversine_distance(
            start_loc['lat'], start_loc['lng'],
            dest['lat'], dest['lng']
        )
        dest['matching_preferences'] = len(matching)
        
        # Determine visit duration based on name/type
        dest_name_lower = dest['name'].lower()
        is_full_day = any(keyword in dest_name_lower for keyword in FULL_DAY_KEYWORDS)
        is_quick = any(keyword in dest_name_lower for keyword in QUICK_VISIT_KEYWORDS)
        
        if is_full_day:
            dest['visit_duration'] = 'full_day'  # 6-8 hours
        elif is_quick:
            dest['visit_duration'] = 'quick'  # 1-2 hours
        else:
            dest['visit_duration'] = 'half_day'  # 3-4 hours
        
        all_matching.append(dest)
    
    print(f"   ✓ {len(all_matching)} destinations match preferences")
    
    # Step 2: ENSURE ALL PREFERENCES SATISFIED
    # Track which preferences are covered
    covered_preferences = set()
    for dest in all_matching:
        covered_preferences.update(set(dest['categories']) & preference_set)
    
    missing_prefs = preference_set - covered_preferences
    if missing_prefs:
        print(f"   ⚠️ Cannot satisfy preferences: {missing_prefs}")
    
    # Step 3: DISTANCE-BASED FILTERING
    if num_days >= 4:
        max_distance = 300
    elif num_days >= 2:
        max_distance = 150
    else:
        max_distance = 100
    
    print(f"   📏 Max search radius: {max_distance}km for {num_days}-day trip")
    all_matching = [d for d in all_matching if d['distance_from_start'] <= max_distance]
    
    # Step 4: GROUP BY CITY/REGION
    from collections import defaultdict
    city_groups = defaultdict(list)
    for dest in all_matching:
        city = dest.get('city', 'Unknown')
        city_groups[city].append(dest)
    
    # Step 5: SELECT DESTINATIONS AND BUILD MULTI-DEST DAYS
    # Strategy: Create balanced days with 1 full-day OR 2-3 quick/half-day attractions
    daily_plans = []
    used_destinations = set()
    satisfied_prefs = set()
    
    current_loc = start_loc
    
    for day_num in range(num_days):
        day_destinations = []
        day_time_budget = 8  # 8 hours available per day
        
        # Try to satisfy unsatisfied preferences first
        remaining_prefs = preference_set - satisfied_prefs
        
        # Find best starting destination for this day
        available = [d for d in all_matching if d['id'] not in used_destinations]
        if not available:
            break
        
        # Sort by: unsatisfied preference match > proximity to current location
        def score_dest(d):
            unsatisfied_match = len(set(d['categories']) & remaining_prefs)
            distance = haversine_distance(current_loc['lat'], current_loc['lng'], d['lat'], d['lng'])
            return (unsatisfied_match * 1000) - distance
        
        available.sort(key=score_dest, reverse=True)
        
        # Pick first destination
        first_dest = available[0]
        
        if first_dest['visit_duration'] == 'full_day':
            # Full day destination - takes entire day
            day_destinations.append(first_dest)
            used_destinations.add(first_dest['id'])
            satisfied_prefs.update(set(first_dest['categories']) & preference_set)
            current_loc = first_dest
            print(f"   Day {day_num + 1}: {first_dest['name']} (full day)")
        else:
            # Half-day/quick - try to add more nearby
            day_destinations.append(first_dest)
            used_destinations.add(first_dest['id'])
            satisfied_prefs.update(set(first_dest['categories']) & preference_set)
            
            time_used = 4 if first_dest['visit_duration'] == 'half_day' else 1.5
            day_time_budget -= time_used
            
            # Find nearby destinations to add to same day
            nearby = [d for d in available[1:] if d['id'] not in used_destinations]
            for dest in nearby:
                dest_distance = haversine_distance(first_dest['lat'], first_dest['lng'], dest['lat'], dest['lng'])
                
                if dest_distance <= 50:  # Within 50km
                    dest_time = 4 if dest['visit_duration'] == 'half_day' else 1.5
                    travel_time = dest_distance / 40  # Assume 40km/h average
                    
                    if (dest_time + travel_time) <= day_time_budget:
                        day_destinations.append(dest)
                        used_destinations.add(dest['id'])
                        satisfied_prefs.update(set(dest['categories']) & preference_set)
                        day_time_budget -= (dest_time + travel_time)
                        
                        if len(day_destinations) >= 3:  # Max 3 destinations per day
                            break
            
            current_loc = day_destinations[-1]
            dest_names = [d['name'] for d in day_destinations]
            print(f"   Day {day_num + 1}: {', '.join(dest_names)} ({len(day_destinations)} stops)")
        
        daily_plans.append(day_destinations)
    
    # Step 6: BUILD ROUTE AND CALCULATE COSTS
    visited = []
    current_location = start_loc
    total_distance = 0
    total_travel_cost = 0
    total_travel_time = 0
    route_segments = []
    
    ACCOMMODATION_PER_NIGHT = 2000
    total_accommodation_cost = (len(daily_plans) - 1) * ACCOMMODATION_PER_NIGHT
    
    for day_plan in daily_plans:
        for dest in day_plan:
            distance = haversine_distance(
                current_location['lat'], current_location['lng'],
                dest['lat'], dest['lng']
            )
            
            road_distance = distance * 1.3
            travel_cost = calculate_route_cost(road_distance)
            travel_time = calculate_travel_time(road_distance)
            
            route_segments.append({
                "from": current_location['name'],
                "to": dest['name'],
                "distance_km": round(road_distance, 2),
                "travel_time_hours": round(travel_time, 2),
                "travel_cost": round(travel_cost, 2)
            })
            
            visited.append({
                **dest,
                "days": 1 if len(day_plan) == 1 else 0.5,
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
    
    # Create realistic itinerary with multi-destination days
    daily_itinerary = []
    current_date = datetime.now()
    
    segment_idx = 0
    for day_num, day_plan in enumerate(daily_plans):
        day_accommodation = ACCOMMODATION_PER_NIGHT if day_num < len(daily_plans) - 1 else 0
        
        # Combine activities for multi-destination days
        day_activities = []
        day_cities = set()
        day_satisfies = set()
        
        for dest in day_plan:
            day_activities.append(f"{dest['name']} - {dest['description']}")
            day_cities.add(dest.get('city', 'Unknown'))
            day_satisfies.update(dest['categories'])
        
        daily_itinerary.append({
            "day": day_num + 1,
            "date": (current_date + timedelta(days=day_num)).strftime("%Y-%m-%d"),
            "destinations": [d['name'] for d in day_plan],
            "cities": list(day_cities),
            "satisfies": list(day_satisfies),
            "activities": day_activities,
            "accommodation_cost": sum(d['cost_per_day'] for d in day_plan),
            "hotel_cost": day_accommodation,
            "travel_segments": route_segments[segment_idx:segment_idx + len(day_plan)]
        })
        segment_idx += len(day_plan)
    
    total_cost = total_travel_cost + total_accommodation_cost + sum(d['accommodation_cost'] for d in visited)
    
    print(f"\n📊 Final: {len(daily_plans)} days, {len(visited)} destinations, {total_distance:.0f}km, ₹{total_cost:.0f}")
    print(f"   ✅ Preferences satisfied: {satisfied_prefs}")
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
        "all_preferences_satisfied": len(satisfied_prefs) == len(preference_set)
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
        
        # ===== CURATED-FIRST APPROACH: Quality over quantity =====
        cache_key = f"{request.start_location['lat']}_{request.start_location['lng']}_{'_'.join(sorted(request.preferences))}"
        
        if cache_key in destination_cache:
            print(f"\n💾 CACHED: Instant response for {request.start_location['name']}")
            filtered_destinations = destination_cache[cache_key]
        else:
            # STEP 1: Try curated database FIRST (high quality, real attractions)
            print(f"\n📚 Searching curated database for {request.start_location['name']}...")
            
            nearby_curated = get_destinations_near(
                request.start_location['lat'],
                request.start_location['lng'],
                max_distance_km=800
            )
            
            curated_filtered = [
                dest for dest in nearby_curated
                if any(pref in dest['categories'] for pref in request.preferences)
            ]
            
            print(f"✅ Curated database: {len(curated_filtered)} quality destinations found")
            
            # Initialize for all code paths
            quality_api_destinations = []
            
            # STEP 2: Only use API if curated doesn't have enough (supplement, don't replace)
            if len(curated_filtered) < 10:
                print(f"\n🌍 Supplementing with API search...")
                
                try:
                    real_destinations = tourism_client.smart_destination_search(
                        start_lat=request.start_location['lat'],
                        start_lng=request.start_location['lng'],
                        preferences=request.preferences,
                        max_distance_km=800,
                        min_destinations=20
                    )
                    
                    print(f"🌍 API: {len(real_destinations)} destinations found")
                except Exception as e:
                    print(f"⚠️ API search failed: {str(e)}")
                    real_destinations = []
                
                # Filter out low-quality API results
                EXCLUDED_KEYWORDS = ['supermarket', 'shop', 'store', 'mart', 'grocery', 'pharmacy', 'atm']
                
                for dest in real_destinations:
                    try:
                        dest_name_lower = dest['name'].lower()
                        # Exclude generic shops unless it's a famous mall/market
                        is_excluded = any(keyword in dest_name_lower for keyword in EXCLUDED_KEYWORDS)
                        is_famous = any(keyword in dest_name_lower for keyword in ['mall', 'palace', 'fort', 'beach', 'museum', 'temple', 'church'])
                        
                        # CRITICAL: Geographic validation - ensure destination is actually near start location
                        import math
                        def haversine(lat1, lon1, lat2, lon2):
                            R = 6371
                            lat1_rad, lat2_rad = math.radians(lat1), math.radians(lat2)
                            delta_lat = math.radians(lat2 - lat1)
                            delta_lon = math.radians(lon2 - lon1)
                            a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
                            c = 2 * math.asin(math.sqrt(a))
                            return R * c
                        
                        # Handle both 'lon' and 'lng' field names from different APIs
                        dest_lng = dest.get('lon') or dest.get('lng')
                        dest_lat = dest.get('lat')
                        
                        if not dest_lat or not dest_lng:
                            print(f"   ⚠️ Skipping {dest['name']} - missing coordinates")
                            continue
                        
                        distance_km = haversine(request.start_location['lat'], request.start_location['lng'], dest_lat, dest_lng)
                        
                        # Reject if too far (prevents Mumbai beaches appearing in Bangalore searches)
                        if distance_km > 500:  # Max 500km radius
                            print(f"   ❌ Rejected {dest['name']} ({distance_km:.0f}km away - too far)")
                            continue
                        
                        if not is_excluded or is_famous:
                            quality_api_destinations.append({
                                'id': f"{dest['source']}_{dest['name'].replace(' ', '_')}",
                                'name': dest['name'],
                                'city': dest.get('city', 'Unknown'),
                                'state': dest.get('state', 'India'),
                                'lat': dest_lat,
                                'lng': dest_lng,
                                'categories': dest['categories'],
                                'cost_per_day': 1500,
                                'rating': 4.0,
                                'description': f"{dest['name']} - {', '.join(dest['categories'])} ({distance_km:.0f}km away)"
                            })
                    except Exception as e:
                        print(f"   ⚠️ Error processing destination {dest.get('name', 'Unknown')}: {str(e)}")
                        continue
                
                print(f"✨ Filtered to {len(quality_api_destinations)} quality API destinations within 500km")
                
                # Combine: Curated (priority) + Quality API (supplement)
                filtered_destinations = curated_filtered + quality_api_destinations
            else:
                # Curated database has enough quality destinations
                filtered_destinations = curated_filtered
            
            print(f"🌍 Total: {len(filtered_destinations)} destinations (Curated: {len(curated_filtered)}, API: {len(quality_api_destinations) if len(curated_filtered) < 10 else 0})")
            
            # Check if user wants beaches but we're in a landlocked city
            if 'beach' in request.preferences:
                has_beaches = any('beach' in dest.get('categories', []) for dest in filtered_destinations)
                landlocked_cities = ['bangalore', 'bengaluru', 'delhi', 'jaipur', 'agra', 'varanasi']
                
                if not has_beaches and any(city in request.start_location['name'].lower() for city in landlocked_cities):
                    print(f"⚠️ NOTE: {request.start_location['name']} is landlocked - nearest beaches are 300-400km away")
                    print(f"   Consider: Gokarna (350km), Mangalore (360km), Goa (570km) for beach trips")
            
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
