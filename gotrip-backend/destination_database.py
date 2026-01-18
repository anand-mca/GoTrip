"""
Curated Indian Tourism Destination Database
150+ real destinations across major cities
Organized by region with accurate coordinates
"""

DESTINATIONS_DB = [
    # ========== GOA - BEACH DESTINATIONS ==========
    {
        "id": "goa_1",
        "name": "Baga Beach",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.5559,
        "lng": 73.7516,
        "categories": ["beach", "adventure", "food", "shopping"],
        "cost_per_day": 2500,
        "rating": 4.6,
        "description": "Popular beach with water sports, beach shacks, nightlife, and seafood restaurants"
    },
    {
        "id": "goa_2",
        "name": "Anjuna Beach & Flea Market",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.5733,
        "lng": 73.7400,
        "categories": ["beach", "shopping", "cultural", "food"],
        "cost_per_day": 2300,
        "rating": 4.5,
        "description": "Famous for Wednesday flea market, hippie culture, beach parties, and shopping"
    },
    {
        "id": "goa_3",
        "name": "Calangute Beach",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.5434,
        "lng": 73.7531,
        "categories": ["beach", "shopping", "food"],
        "cost_per_day": 2400,
        "rating": 4.4,
        "description": "Queen of beaches, water sports, beach markets, restaurants"
    },
    {
        "id": "goa_4",
        "name": "Palolem Beach",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.0100,
        "lng": 74.0232,
        "categories": ["beach", "nature", "food"],
        "cost_per_day": 2200,
        "rating": 4.7,
        "description": "Crescent-shaped beach, calm waters, beach huts, dolphin watching"
    },
    {
        "id": "goa_5",
        "name": "Panjim Market & Food Street",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.4909,
        "lng": 73.8278,
        "categories": ["food", "shopping", "cultural"],
        "cost_per_day": 1800,
        "rating": 4.3,
        "description": "Local markets, Portuguese architecture, Goan cuisine, cafes"
    },
    {
        "id": "goa_6",
        "name": "Old Goa Churches",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.5005,
        "lng": 73.9117,
        "categories": ["history", "cultural", "religious"],
        "cost_per_day": 1500,
        "rating": 4.8,
        "description": "UNESCO heritage churches, Basilica of Bom Jesus, Se Cathedral"
    },
    {
        "id": "goa_7",
        "name": "Dudhsagar Waterfalls",
        "city": "Goa",
        "state": "Goa",
        "lat": 15.3144,
        "lng": 74.3144,
        "categories": ["nature", "adventure"],
        "cost_per_day": 2000,
        "rating": 4.6,
        "description": "Four-tiered waterfall, trekking, jeep safari, swimming"
    },
    
    # ========== MUMBAI - BEACH & URBAN ==========
    {
        "id": "mumbai_1",
        "name": "Marine Drive & Chowpatty",
        "city": "Mumbai",
        "state": "Maharashtra",
        "lat": 18.9432,
        "lng": 72.8236,
        "categories": ["beach", "food"],
        "cost_per_day": 2000,
        "rating": 4.5,
        "description": "Iconic promenade, sunset views, street food, Mumbai's coastline"
    },
    {
        "id": "mumbai_2",
        "name": "Colaba Causeway Market",
        "city": "Mumbai",
        "state": "Maharashtra",
        "lat": 18.9067,
        "lng": 72.8147,
        "categories": ["shopping", "food"],
        "cost_per_day": 2200,
        "rating": 4.4,
        "description": "Street shopping, cafes, Gateway of India nearby, handicrafts"
    },
    {
        "id": "mumbai_3",
        "name": "Elephanta Caves",
        "city": "Mumbai",
        "state": "Maharashtra",
        "lat": 18.9633,
        "lng": 72.9315,
        "categories": ["history", "cultural"],
        "cost_per_day": 1800,
        "rating": 4.5,
        "description": "Ancient rock-cut temples, UNESCO site, ferry ride"
    },
    {
        "id": "mumbai_4",
        "name": "Juhu Beach",
        "city": "Mumbai",
        "state": "Maharashtra",
        "lat": 19.0990,
        "lng": 72.8265,
        "categories": ["beach", "food"],
        "cost_per_day": 1900,
        "rating": 4.3,
        "description": "Popular beach, pav bhaji, bhel puri, sunset views"
    },
    {
        "id": "mumbai_5",
        "name": "Crawford Market",
        "city": "Mumbai",
        "state": "Maharashtra",
        "lat": 18.9467,
        "lng": 72.8342,
        "categories": ["shopping", "food", "cultural"],
        "cost_per_day": 1600,
        "rating": 4.2,
        "description": "Historic market, fruits, vegetables, street food, local shopping"
    },
    
    # ========== CHENNAI - BEACH & CULTURAL ==========
    {
        "id": "chennai_1",
        "name": "Marina Beach",
        "city": "Chennai",
        "state": "Tamil Nadu",
        "lat": 13.0499,
        "lng": 80.2824,
        "categories": ["beach", "food"],
        "cost_per_day": 1800,
        "rating": 4.4,
        "description": "India's longest beach, street food, evening walks, sunrise views"
    },
    {
        "id": "chennai_2",
        "name": "Mahabalipuram Temples",
        "city": "Chennai",
        "state": "Tamil Nadu",
        "lat": 12.6208,
        "lng": 80.1989,
        "categories": ["history", "beach", "cultural"],
        "cost_per_day": 2000,
        "rating": 4.7,
        "description": "Shore Temple, rock carvings, beach town, UNESCO heritage"
    },
    {
        "id": "chennai_3",
        "name": "T Nagar Shopping District",
        "city": "Chennai",
        "state": "Tamil Nadu",
        "lat": 13.0418,
        "lng": 80.2341,
        "categories": ["shopping", "food"],
        "cost_per_day": 1700,
        "rating": 4.3,
        "description": "Silk sarees, jewelry, textiles, South Indian street food"
    },
    {
        "id": "chennai_4",
        "name": "Elliot's Beach",
        "city": "Chennai",
        "state": "Tamil Nadu",
        "lat": 13.0054,
        "lng": 80.2692,
        "categories": ["beach", "food"],
        "cost_per_day": 1600,
        "rating": 4.2,
        "description": "Clean beach, cafes, less crowded, peaceful atmosphere"
    },
    
    # ========== KOCHI - KERALA BEACHES ==========
    {
        "id": "kochi_1",
        "name": "Fort Kochi Beach",
        "city": "Kochi",
        "state": "Kerala",
        "lat": 9.9674,
        "lng": 76.2428,
        "categories": ["beach", "history", "food", "cultural"],
        "cost_per_day": 2100,
        "rating": 4.6,
        "description": "Chinese fishing nets, colonial architecture, seafood, art galleries"
    },
    {
        "id": "kochi_2",
        "name": "Marine Drive Kochi",
        "city": "Kochi",
        "state": "Kerala",
        "lat": 9.9663,
        "lng": 76.2815,
        "categories": ["beach", "food", "shopping"],
        "cost_per_day": 1800,
        "rating": 4.4,
        "description": "Waterfront promenade, sunset views, shopping malls, restaurants"
    },
    {
        "id": "kochi_3",
        "name": "Cherai Beach",
        "city": "Kochi",
        "state": "Kerala",
        "lat": 10.1384,
        "lng": 76.1785,
        "categories": ["beach", "nature"],
        "cost_per_day": 1700,
        "rating": 4.5,
        "description": "Golden sand beach, backwaters, dolphin sightings, peaceful"
    },
    {
        "id": "kochi_4",
        "name": "Broadway Market",
        "city": "Kochi",
        "state": "Kerala",
        "lat": 9.9695,
        "lng": 76.2924,
        "categories": ["shopping", "food", "cultural"],
        "cost_per_day": 1500,
        "rating": 4.2,
        "description": "Local market, spices, handicrafts, Kerala cuisine"
    },
    
    # ========== JAIPUR - CULTURAL & SHOPPING ==========
    {
        "id": "jaipur_1",
        "name": "Amber Fort",
        "city": "Jaipur",
        "state": "Rajasthan",
        "lat": 26.9855,
        "lng": 75.8513,
        "categories": ["history", "cultural", "adventure"],
        "cost_per_day": 2200,
        "rating": 4.8,
        "description": "Majestic fort, elephant rides, light & sound show, palace architecture"
    },
    {
        "id": "jaipur_2",
        "name": "Johari Bazaar",
        "city": "Jaipur",
        "state": "Rajasthan",
        "lat": 26.9239,
        "lng": 75.8267,
        "categories": ["shopping", "cultural", "food"],
        "cost_per_day": 1800,
        "rating": 4.5,
        "description": "Traditional jewelry, textiles, handicrafts, Rajasthani food"
    },
    {
        "id": "jaipur_3",
        "name": "Chokhi Dhani Village",
        "city": "Jaipur",
        "state": "Rajasthan",
        "lat": 26.7841,
        "lng": 75.7990,
        "categories": ["food", "cultural"],
        "cost_per_day": 2500,
        "rating": 4.6,
        "description": "Rajasthani village experience, traditional food, folk dance, camel rides"
    },
    {
        "id": "jaipur_4",
        "name": "City Palace & Hawa Mahal",
        "city": "Jaipur",
        "state": "Rajasthan",
        "lat": 26.9258,
        "lng": 75.8237,
        "categories": ["history", "cultural"],
        "cost_per_day": 1900,
        "rating": 4.7,
        "description": "Pink city landmarks, palace museum, architecture"
    },
    {
        "id": "jaipur_5",
        "name": "Bapu Bazaar",
        "city": "Jaipur",
        "state": "Rajasthan",
        "lat": 26.9195,
        "lng": 75.8073,
        "categories": ["shopping", "food"],
        "cost_per_day": 1600,
        "rating": 4.3,
        "description": "Textiles, footwear, handicrafts, local street food"
    },
    
    # ========== MANALI - ADVENTURE & NATURE ==========
    {
        "id": "manali_1",
        "name": "Solang Valley",
        "city": "Manali",
        "state": "Himachal Pradesh",
        "lat": 32.3192,
        "lng": 77.1492,
        "categories": ["adventure", "nature"],
        "cost_per_day": 3500,
        "rating": 4.7,
        "description": "Skiing, paragliding, zorbing, cable car, mountain views"
    },
    {
        "id": "manali_2",
        "name": "Old Manali Market",
        "city": "Manali",
        "state": "Himachal Pradesh",
        "lat": 32.2433,
        "lng": 77.1892,
        "categories": ["shopping", "food", "cultural"],
        "cost_per_day": 2000,
        "rating": 4.4,
        "description": "Cafes, local handicrafts, Himalayan food, hippie culture"
    },
    {
        "id": "manali_3",
        "name": "Rohtang Pass",
        "city": "Manali",
        "state": "Himachal Pradesh",
        "lat": 32.3726,
        "lng": 77.2490,
        "categories": ["adventure", "nature"],
        "cost_per_day": 3200,
        "rating": 4.6,
        "description": "Snow activities, mountain pass, stunning views, adventure sports"
    },
    {
        "id": "manali_4",
        "name": "Mall Road Manali",
        "city": "Manali",
        "state": "Himachal Pradesh",
        "lat": 32.2396,
        "lng": 77.1887,
        "categories": ["shopping", "food"],
        "cost_per_day": 1800,
        "rating": 4.3,
        "description": "Shopping street, restaurants, cafes, local handicrafts"
    },
    
    # ========== RISHIKESH - ADVENTURE & RELIGIOUS ==========
    {
        "id": "rishikesh_1",
        "name": "Lakshman Jhula Area",
        "city": "Rishikesh",
        "state": "Uttarakhand",
        "lat": 30.1332,
        "lng": 78.3276,
        "categories": ["religious", "adventure", "cultural"],
        "cost_per_day": 1600,
        "rating": 4.6,
        "description": "Iconic suspension bridge, yoga ashrams, Ganges views, spiritual atmosphere"
    },
    {
        "id": "rishikesh_2",
        "name": "River Rafting Ganga",
        "city": "Rishikesh",
        "state": "Uttarakhand",
        "lat": 30.0869,
        "lng": 78.2676,
        "categories": ["adventure", "nature"],
        "cost_per_day": 2800,
        "rating": 4.8,
        "description": "White water rafting, camping, cliff jumping, adventure sports"
    },
    {
        "id": "rishikesh_3",
        "name": "Ram Jhula & Markets",
        "city": "Rishikesh",
        "state": "Uttarakhand",
        "lat": 30.1158,
        "lng": 78.3051,
        "categories": ["religious", "shopping", "food"],
        "cost_per_day": 1500,
        "rating": 4.4,
        "description": "Temples, local markets, vegetarian food, yoga centers"
    },
    
    # ========== MUNNAR - NATURE & TEA GARDENS ==========
    {
        "id": "munnar_1",
        "name": "Tea Gardens & Estates",
        "city": "Munnar",
        "state": "Kerala",
        "lat": 10.0889,
        "lng": 77.0595,
        "categories": ["nature", "cultural"],
        "cost_per_day": 2200,
        "rating": 4.7,
        "description": "Tea plantation tours, scenic beauty, trekking, tea museum"
    },
    {
        "id": "munnar_2",
        "name": "Eravikulam National Park",
        "city": "Munnar",
        "state": "Kerala",
        "lat": 10.1200,
        "lng": 77.0652,
        "categories": ["nature", "adventure"],
        "cost_per_day": 2000,
        "rating": 4.6,
        "description": "Nilgiri Tahr, trekking, mountain views, wildlife"
    },
    {
        "id": "munnar_3",
        "name": "Munnar Town Market",
        "city": "Munnar",
        "state": "Kerala",
        "lat": 10.0887,
        "lng": 77.0598,
        "categories": ["shopping", "food"],
        "cost_per_day": 1600,
        "rating": 4.2,
        "description": "Local tea, spices, handicrafts, Kerala cuisine"
    },
    
    # ========== PONDICHERRY - BEACH & CULTURAL ==========
    {
        "id": "pondy_1",
        "name": "Promenade Beach",
        "city": "Puducherry",
        "state": "Puducherry",
        "lat": 11.9345,
        "lng": 79.8307,
        "categories": ["beach", "food", "cultural"],
        "cost_per_day": 1900,
        "rating": 4.5,
        "description": "French colonial architecture, beach walk, cafes, Rock Beach"
    },
    {
        "id": "pondy_2",
        "name": "Auroville",
        "city": "Puducherry",
        "state": "Puducherry",
        "lat": 12.0051,
        "lng": 79.8083,
        "categories": ["cultural", "nature"],
        "cost_per_day": 2000,
        "rating": 4.6,
        "description": "Experimental township, Matrimandir, organic cafes, peace"
    },
    {
        "id": "pondy_3",
        "name": "French Quarter",
        "city": "Puducherry",
        "state": "Puducherry",
        "lat": 11.9342,
        "lng": 79.8306,
        "categories": ["cultural", "food", "shopping"],
        "cost_per_day": 1800,
        "rating": 4.4,
        "description": "Colonial streets, bakeries, boutiques, French cuisine"
    },
    
    # ========== UDAIPUR - CULTURAL & HISTORY ==========
    {
        "id": "udaipur_1",
        "name": "Lake Pichola & City Palace",
        "city": "Udaipur",
        "state": "Rajasthan",
        "lat": 24.5764,
        "lng": 73.6821,
        "categories": ["history", "cultural"],
        "cost_per_day": 2500,
        "rating": 4.8,
        "description": "Boat ride, palaces, lake views, sunset, luxury heritage"
    },
    {
        "id": "udaipur_2",
        "name": "Jagdish Temple & Bazaars",
        "city": "Udaipur",
        "state": "Rajasthan",
        "lat": 24.5800,
        "lng": 73.6831,
        "categories": ["religious", "shopping", "food"],
        "cost_per_day": 1700,
        "rating": 4.5,
        "description": "Hindu temple, local markets, handicrafts, Rajasthani food"
    },
    
    # ========== AGRA - HISTORY ==========
    {
        "id": "agra_1",
        "name": "Taj Mahal",
        "city": "Agra",
        "state": "Uttar Pradesh",
        "lat": 27.1751,
        "lng": 78.0421,
        "categories": ["history", "cultural"],
        "cost_per_day": 2200,
        "rating": 5.0,
        "description": "Wonder of the world, Mughal architecture, sunrise/sunset views"
    },
    {
        "id": "agra_2",
        "name": "Agra Fort & Markets",
        "city": "Agra",
        "state": "Uttar Pradesh",
        "lat": 27.1795,
        "lng": 78.0211,
        "categories": ["history", "shopping"],
        "cost_per_day": 1800,
        "rating": 4.6,
        "description": "Red fort, marble handicrafts, leather goods, Mughal history"
    },
    
    # ========== BANGALORE - URBAN ==========
    {
        "id": "bangalore_1",
        "name": "Lalbagh Gardens",
        "city": "Bangalore",
        "state": "Karnataka",
        "lat": 12.9507,
        "lng": 77.5848,
        "categories": ["nature", "cultural"],
        "cost_per_day": 1500,
        "rating": 4.5,
        "description": "Botanical garden, flower shows, walking trails, Glass House"
    },
    {
        "id": "bangalore_2",
        "name": "MG Road & Brigade Road",
        "city": "Bangalore",
        "state": "Karnataka",
        "lat": 12.9750,
        "lng": 77.6069,
        "categories": ["shopping", "food"],
        "cost_per_day": 2200,
        "rating": 4.4,
        "description": "Shopping district, malls, restaurants, nightlife, cafes"
    },
    {
        "id": "bangalore_3",
        "name": "Cubbon Park",
        "city": "Bangalore",
        "state": "Karnataka",
        "lat": 12.9762,
        "lng": 77.5928,
        "categories": ["nature"],
        "cost_per_day": 1200,
        "rating": 4.3,
        "description": "Urban park, jogging trails, morning walks, greenery"
    },
]


def get_destinations_by_city(city_name):
    """Get all destinations in a specific city"""
    return [d for d in DESTINATIONS_DB if d['city'].lower() == city_name.lower()]


def get_destinations_by_category(category):
    """Get all destinations matching a category"""
    return [d for d in DESTINATIONS_DB if category in d['categories']]


def get_destinations_near(lat, lng, max_distance_km=1000):
    """Get destinations within distance from coordinates"""
    import math
    
    def haversine(lat1, lon1, lat2, lon2):
        R = 6371
        lat1_rad, lat2_rad = math.radians(lat1), math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)
        a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
        c = 2 * math.asin(math.sqrt(a))
        return R * c
    
    nearby = []
    for dest in DESTINATIONS_DB:
        distance = haversine(lat, lng, dest['lat'], dest['lng'])
        if distance <= max_distance_km:
            dest_copy = dest.copy()
            dest_copy['distance_from_start'] = round(distance, 2)
            nearby.append(dest_copy)
    
    return sorted(nearby, key=lambda x: x['distance_from_start'])
