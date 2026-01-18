"""
Tourism API Integration Module
Fetches real POI data from multiple free APIs
"""
import requests
import time
from typing import List, Dict, Any, Optional
from math import radians, sin, cos, sqrt, atan2

class TourismAPIClient:
    """
    Integrates multiple tourism APIs to fetch real destination data
    """
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'GoTrip/1.0 (Trip Planning App)'
        })
    
    @staticmethod
    def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance in kilometers between two coordinates"""
        R = 6371  # Earth radius in km
        lat1_rad, lat2_rad = radians(lat1), radians(lat2)
        delta_lat = radians(lat2 - lat1)
        delta_lon = radians(lon2 - lon1)
        
        a = sin(delta_lat/2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon/2)**2
        c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    
    def fetch_opentripmap_places(self, lat: float, lon: float, radius_km: int, kinds: str, limit: int = 50) -> List[Dict]:
        """
        Fetch places from OpenTripMap API (FREE)
        
        Args:
            lat, lon: Center coordinates
            radius_km: Search radius in km
            kinds: Comma-separated categories (beaches, historic, museums, interesting_places, etc.)
            limit: Max results
        
        Returns:
            List of POI dictionaries
        """
        url = "https://api.opentripmap.com/0.1/en/places/radius"
        
        # Convert km to meters
        radius_m = radius_km * 1000
        
        params = {
            'radius': min(radius_m, 50000),  # Max 50km for free tier
            'lon': lon,
            'lat': lat,
            'kinds': kinds,
            'format': 'json',
            'limit': limit,
            'apikey': '5ae2e3f221c38a28845f05b61c4fb634c4e88f3f1a8dbfa7b7a1a5f3'  # Free tier key
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            places = []
            for item in data:
                if 'point' in item:
                    places.append({
                        'name': item.get('name', 'Unnamed Place'),
                        'lat': item['point']['lat'],
                        'lng': item['point']['lon'],
                        'kinds': item.get('kinds', '').split(','),
                        'source': 'opentripmap',
                        'xid': item.get('xid'),
                        'distance_km': round(self.haversine_distance(
                            lat, lon, 
                            item['point']['lat'], 
                            item['point']['lon']
                        ), 2)
                    })
            
            return places
        except Exception as e:
            print(f"⚠️ OpenTripMap API error: {e}")
            return []
    
    def fetch_overpass_places(self, lat: float, lon: float, radius_km: int, tags: Dict[str, List[str]]) -> List[Dict]:
        """
        Fetch places from Overpass API (OpenStreetMap) - COMPLETELY FREE
        
        Args:
            lat, lon: Center coordinates
            radius_km: Search radius in km
            tags: OSM tags dict, e.g., {'tourism': ['beach_resort', 'museum'], 'amenity': ['restaurant']}
        
        Returns:
            List of POI dictionaries
        """
        url = "https://overpass-api.de/api/interpreter"
        
        # Build Overpass query
        radius_m = radius_km * 1000
        query_parts = []
        
        for key, values in tags.items():
            for value in values:
                query_parts.append(f'node["{key}"="{value}"](around:{radius_m},{lat},{lon});')
                query_parts.append(f'way["{key}"="{value}"](around:{radius_m},{lat},{lon});')
        
        overpass_query = f"""
        [out:json][timeout:25];
        (
            {' '.join(query_parts)}
        );
        out center;
        """
        
        try:
            response = self.session.post(url, data={'data': overpass_query}, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            places = []
            seen_names = set()
            
            for element in data.get('elements', []):
                name = element.get('tags', {}).get('name')
                if not name or name in seen_names:
                    continue
                
                seen_names.add(name)
                
                # Get coordinates
                if 'lat' in element and 'lon' in element:
                    elem_lat, elem_lon = element['lat'], element['lon']
                elif 'center' in element:
                    elem_lat, elem_lon = element['center']['lat'], element['center']['lon']
                else:
                    continue
                
                tags_dict = element.get('tags', {})
                
                places.append({
                    'name': name,
                    'lat': elem_lat,
                    'lng': elem_lon,
                    'tags': tags_dict,
                    'source': 'osm',
                    'distance_km': round(self.haversine_distance(lat, lon, elem_lat, elem_lon), 2)
                })
            
            return places
        except Exception as e:
            print(f"⚠️ Overpass API error: {e}")
            return []
    
    def find_beach_cities_in_india(self, max_results: int = 10) -> List[Dict]:
        """
        Return major beach cities in India with coordinates
        """
        beach_cities = [
            {'name': 'Goa', 'lat': 15.2993, 'lng': 74.1240, 'state': 'Goa'},
            {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777, 'state': 'Maharashtra'},
            {'name': 'Chennai', 'lat': 13.0827, 'lng': 80.2707, 'state': 'Tamil Nadu'},
            {'name': 'Kochi', 'lat': 9.9312, 'lng': 76.2673, 'state': 'Kerala'},
            {'name': 'Visakhapatnam', 'lat': 17.6868, 'lng': 83.2185, 'state': 'Andhra Pradesh'},
            {'name': 'Puducherry', 'lat': 11.9416, 'lng': 79.8083, 'state': 'Puducherry'},
            {'name': 'Mangalore', 'lat': 12.9141, 'lng': 74.8560, 'state': 'Karnataka'},
            {'name': 'Puri', 'lat': 19.8135, 'lng': 85.8312, 'state': 'Odisha'},
            {'name': 'Kovalam', 'lat': 8.4004, 'lng': 76.9790, 'state': 'Kerala'},
            {'name': 'Varkala', 'lat': 8.7379, 'lng': 76.7163, 'state': 'Kerala'},
        ]
        return beach_cities[:max_results]
    
    def find_hill_stations_in_india(self, max_results: int = 10) -> List[Dict]:
        """
        Return major hill stations in India
        """
        hill_stations = [
            {'name': 'Shimla', 'lat': 31.1048, 'lng': 77.1734, 'state': 'Himachal Pradesh'},
            {'name': 'Manali', 'lat': 32.2432, 'lng': 77.1892, 'state': 'Himachal Pradesh'},
            {'name': 'Darjeeling', 'lat': 27.0410, 'lng': 88.2663, 'state': 'West Bengal'},
            {'name': 'Ooty', 'lat': 11.4102, 'lng': 76.6950, 'state': 'Tamil Nadu'},
            {'name': 'Munnar', 'lat': 10.0889, 'lng': 77.0595, 'state': 'Kerala'},
            {'name': 'Nainital', 'lat': 29.3803, 'lng': 79.4636, 'state': 'Uttarakhand'},
            {'name': 'Mussoorie', 'lat': 30.4598, 'lng': 78.0644, 'state': 'Uttarakhand'},
            {'name': 'Coorg', 'lat': 12.4244, 'lng': 75.7382, 'state': 'Karnataka'},
        ]
        return hill_stations[:max_results]
    
    def find_historical_cities_in_india(self, max_results: int = 10) -> List[Dict]:
        """
        Return major historical/cultural cities in India
        """
        cities = [
            {'name': 'Jaipur', 'lat': 26.9124, 'lng': 75.7873, 'state': 'Rajasthan'},
            {'name': 'Agra', 'lat': 27.1767, 'lng': 78.0081, 'state': 'Uttar Pradesh'},
            {'name': 'Varanasi', 'lat': 25.3176, 'lng': 82.9739, 'state': 'Uttar Pradesh'},
            {'name': 'Udaipur', 'lat': 24.5854, 'lng': 73.7125, 'state': 'Rajasthan'},
            {'name': 'Hampi', 'lat': 15.3350, 'lng': 76.4600, 'state': 'Karnataka'},
            {'name': 'Khajuraho', 'lat': 24.8318, 'lng': 79.9199, 'state': 'Madhya Pradesh'},
        ]
        return cities[:max_results]
    
    def categorize_preference_to_osm_tags(self, preference: str) -> Dict[str, List[str]]:
        """
        Map user preferences to OpenStreetMap tags - ENHANCED for real attractions
        """
        mapping = {
            'beach': {
                'natural': ['beach', 'coastline'],
                'leisure': ['beach_resort', 'water_park'],
                'tourism': ['beach_resort']
            },
            'food': {
                'amenity': ['restaurant', 'cafe', 'food_court'],
            },
            'shopping': {
                'shop': ['mall', 'supermarket', 'department_store'],
                'amenity': ['marketplace']
            },
            'adventure': {
                'tourism': ['attraction', 'viewpoint', 'theme_park'],
                'sport': ['climbing', 'diving', 'skiing', 'water_sports'],
                'leisure': ['park', 'sports_centre', 'trekking'],
                'natural': ['peak', 'waterfall', 'cave', 'rock']
            },
            'history': {
                'historic': ['monument', 'castle', 'memorial', 'archaeological_site', 'fort', 'ruins'],
                'tourism': ['museum', 'gallery']
            },
            'nature': {
                'leisure': ['park', 'nature_reserve', 'garden'],
                'natural': ['peak', 'waterfall', 'forest', 'tree', 'wood'],
                'tourism': ['viewpoint', 'attraction'],
                'landuse': ['forest', 'meadow'],
                'boundary': ['national_park', 'protected_area']
            },
            'religious': {
                'amenity': ['place_of_worship'],
                'building': ['temple', 'church', 'mosque']
            },
            'cultural': {
                'tourism': ['museum', 'gallery', 'artwork', 'attraction'],
                'amenity': ['theatre', 'arts_centre']
            }
        }
        return mapping.get(preference, {})
    
    def smart_destination_search(
        self, 
        start_lat: float, 
        start_lng: float, 
        preferences: List[str], 
        max_distance_km: int = 800,
        min_destinations: int = 20
    ) -> List[Dict]:
        """
        OPTIMIZED FAST SEARCH: Find destination clusters
        
        Strategy:
        1. Find 2-3 closest major cities based on preferences
        2. For each city, search 30km radius (not 50km - faster!)
        3. Limit to top matches only
        4. Return quickly with clustered results
        """
        
        print(f"\n🔍 FAST SEARCH: Looking for destinations matching {preferences}")
        
        all_destinations = []
        
        # Step 1: Identify base cities based on preferences (FASTER)
        base_cities = []
        
        if 'beach' in preferences:
            base_cities.extend(self.find_beach_cities_in_india(max_results=8))
        
        if 'adventure' in preferences or 'nature' in preferences:
            base_cities.extend(self.find_hill_stations_in_india(max_results=5))
        
        if 'history' in preferences or 'cultural' in preferences:
            base_cities.extend(self.find_historical_cities_in_india(max_results=4))
        
        # Remove duplicates
        seen_cities = set()
        unique_cities = []
        for city in base_cities:
            if city['name'] not in seen_cities:
                seen_cities.add(city['name'])
                unique_cities.append(city)
        
        # Step 2: Filter cities within max_distance from start
        nearby_cities = []
        for city in unique_cities:
            distance = self.haversine_distance(start_lat, start_lng, city['lat'], city['lng'])
            if distance <= max_distance_km:
                city['distance_from_start'] = round(distance, 2)
                nearby_cities.append(city)
        
        # Sort by distance
        nearby_cities.sort(key=lambda x: x['distance_from_start'])
        
        print(f"📍 Found {len(nearby_cities)} base cities within {max_distance_km}km")
        
        # OPTIMIZATION: Only search TOP 2 closest cities to save time
        for city in nearby_cities[:2]:
            print(f"🏙️ Searching {city['name']} ({city['distance_from_start']}km away)...")
            
            # Search within SMALLER 30km radius (faster than 50km)
            city_pois = []
            
            for pref in preferences:
                osm_tags = self.categorize_preference_to_osm_tags(pref)
                if osm_tags:
                    pois = self.fetch_overpass_places(
                        city['lat'], 
                        city['lng'], 
                        radius_km=30,  # REDUCED from 50km
                        tags=osm_tags
                    )
                    
                    # Limit POIs per preference to 10 (faster)
                    for poi in pois[:10]:
                        poi['category'] = pref
                        poi['base_city'] = city['name']
                        poi['region'] = city['state']
                        city_pois.append(poi)
            
            print(f"   ✓ Found {len(city_pois)} POIs in {city['name']}")
            all_destinations.extend(city_pois)
            
            # If we have enough, stop searching
            if len(all_destinations) >= min_destinations:
                break
        
        # Step 3: Deduplicate and enrich
        unique_destinations = []
        seen_names = set()
        
        for dest in all_destinations:
            if dest['name'] not in seen_names:
                seen_names.add(dest['name'])
                
                # Calculate cost estimate
                base_cost = 2000
                dest['cost_per_day'] = base_cost
                dest['rating'] = 4.0
                
                unique_destinations.append(dest)
        
        print(f"\n✅ Found {len(unique_destinations)} unique destinations in {len(nearby_cities[:2])} cities")
        
        return unique_destinations


if __name__ == "__main__":
    # Test the API client
    client = TourismAPIClient()
    
    # Test from Mumbai
    print("Testing from Mumbai (19.0760, 72.8777)")
    destinations = client.smart_destination_search(
        start_lat=19.0760,
        start_lng=72.8777,
        preferences=['beach', 'food', 'shopping'],
        max_distance_km=600
    )
    
    print(f"\n📊 Sample results:")
    for dest in destinations[:10]:
        print(f"- {dest['name']} in {dest.get('base_city', 'N/A')} ({dest.get('category', 'N/A')})")
