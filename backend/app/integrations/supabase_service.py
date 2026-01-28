"""
Supabase integration for fetching real destination data.
"""
import os
from typing import List, Optional
from app.models.schemas import PlaceModel, PreferenceEnum
from app.utils.logger import get_logger

logger = get_logger(__name__)

# Supabase connection (use environment variables)
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://ycwsyqxkszzasbuwzwho.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inljd3N5cXhrc3p6YXNidXd6d2hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDM4MjE5OTcsImV4cCI6MjAxOTM5Nzk5N30.mHjfK7wMwcLowHPMEAJhyV5_KSECYnZQyPCYX45xLPE")


def get_supabase_client():
    """Get Supabase client."""
    try:
        from supabase import create_client
        return create_client(SUPABASE_URL, SUPABASE_KEY)
    except ImportError:
        logger.error("Supabase client not installed. Install with: pip install supabase")
        return None


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two coordinates using Haversine formula.
    
    Args:
        lat1, lon1: Starting coordinates
        lat2, lon2: Ending coordinates
    
    Returns:
        Distance in kilometers
    """
    from math import radians, sin, cos, sqrt, atan2
    
    R = 6371  # Earth's radius in km
    
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = sin(dlat / 2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    
    return R * c


def fetch_destinations_from_supabase(
    preferences: Optional[List[str]] = None,
    limit: int = 50,
    center_lat: Optional[float] = None,
    center_lon: Optional[float] = None,
    radius_km: float = 500
) -> List[PlaceModel]:
    """
    Fetch destinations from Supabase database.
    
    Args:
        preferences: List of preference categories to filter by
        limit: Maximum number of destinations to return
        center_lat, center_lon: Center location for distance calculation
        radius_km: Search radius in kilometers
    
    Returns:
        List of PlaceModel instances
    """
    try:
        client = get_supabase_client()
        if not client:
            logger.error("Could not connect to Supabase")
            return []
        
        # Query Supabase destinations table
        print(f"\n🔗 SUPABASE: Fetching destinations (limit={limit}, radius={radius_km}km)")
        print(f"   Center: ({center_lat}, {center_lon}), Preferences: {preferences}")
        
        query = client.table('destinations').select('*')
        
        # No category filtering here - we'll filter results client-side
        # because Supabase array contains() operator is complex
        
        response = query.limit(limit).execute()
        
        if not response.data:
            print(f"⚠️  SUPABASE: No destinations found in Supabase database!")
            return []
        
        print(f"✅ SUPABASE: Fetched {len(response.data)} destinations from Supabase table")
        
        # Convert to PlaceModel instances
        places = []
        all_places_count = 0
        for dest in response.data:
            all_places_count += 1
            try:
                # Map Supabase columns to PlaceModel
                # Get the primary category from the categories array
                categories_from_db = dest.get('categories', [])
                primary_category = PreferenceEnum.NATURE  # Default fallback
                
                # If categories is a list, use first matching preference
                if categories_from_db:
                    if isinstance(categories_from_db, list):
                        # Try to find first category that matches PreferenceEnum
                        for cat in categories_from_db:
                            try:
                                primary_category = PreferenceEnum(cat.lower())
                                break
                            except ValueError:
                                continue
                    else:
                        # If it's a string, try to parse it
                        try:
                            primary_category = PreferenceEnum(categories_from_db.lower())
                        except ValueError:
                            pass
                
                place = PlaceModel(
                    id=str(dest.get('id', '')),
                    name=dest.get('name', 'Unknown'),
                    category=primary_category,
                    latitude=float(dest.get('latitude', 0)),
                    longitude=float(dest.get('longitude', 0)),
                    rating=float(dest.get('rating', 4.0)),
                    reviews=int(dest.get('reviews', 0)),
                    estimated_cost=float(dest.get('estimated_cost', 0)),
                    description=dest.get('description', ''),
                    city=dest.get('city', None),
                    state=dest.get('state', None),
                    photo_url=dest.get('photo_url', None),
                    opening_hours=dest.get('opening_hours', None)
                )
                
                # Calculate distance if center coordinates provided
                if center_lat is not None and center_lon is not None:
                    distance = haversine_distance(
                        center_lat, center_lon,
                        place.latitude, place.longitude
                    )
                    
                    # Filter by radius
                    if distance <= radius_km:
                        places.append(place)
                    else:
                        logger.debug(f"Place {place.name} too far: {distance:.0f}km > {radius_km}km")
                else:
                    places.append(place)
                    
            except Exception as e:
                logger.warning(f"Error parsing destination: {str(e)}")
                continue
        
        print(f"📊 SUPABASE: Parsed {all_places_count} destinations, {len(places)} within {radius_km}km radius")
        
        # Filter by preferences if provided
        if preferences:
            filtered_places = []
            for place in places:
                # Check if place category matches any of the requested preferences
                if place.category.value in [p.lower() for p in preferences]:
                    filtered_places.append(place)
            
            print(f"🏷️  SUPABASE: Preferences filter: {preferences}, matched {len(filtered_places)} out of {len(places)}")
            
            # If some matches found, use filtered results; otherwise use all (fallback)
            if filtered_places:
                places = filtered_places
            else:
                print(f"⚠️  SUPABASE: No destinations matching preferences {preferences}. Using all {len(places)} nearby destinations.")
        
        print(f"📤 SUPABASE: Returning {len(places)} destinations to trip planner")
        return places
        
    except Exception as e:
        logger.error(f"Error fetching from Supabase: {str(e)}")
        return []


def get_destinations_by_category(
    category: str,
    limit: int = 50
) -> List[PlaceModel]:
    """
    Fetch destinations by category from Supabase.
    
    Args:
        category: Place category/type
        limit: Maximum number of destinations
    
    Returns:
        List of PlaceModel instances
    """
    try:
        client = get_supabase_client()
        if not client:
            return []
        
        logger.info(f"Fetching destinations by category: {category}")
        
        # Query by category column (adjust field name based on schema)
        response = client.table('destinations').select('*').eq('category', category).limit(limit).execute()
        
        places = []
        for dest in response.data:
            try:
                place = PlaceModel(
                    id=str(dest.get('id', '')),
                    name=dest.get('name', ''),
                    category=PreferenceEnum.NATURE,
                    latitude=float(dest.get('latitude', 0)),
                    longitude=float(dest.get('longitude', 0)),
                    rating=float(dest.get('rating', 4.0)),
                    reviews=int(dest.get('reviews', 0)),
                    estimated_cost=float(dest.get('estimated_cost', 0)),
                    description=dest.get('description', ''),
                    photo_url=dest.get('photo_url', None)
                )
                places.append(place)
            except Exception as e:
                logger.warning(f"Error parsing destination: {str(e)}")
                continue
        
        logger.info(f"Fetched {len(places)} destinations by category")
        return places
        
    except Exception as e:
        logger.error(f"Error fetching destinations by category: {str(e)}")
        return []
