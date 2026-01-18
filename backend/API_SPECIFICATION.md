"""
API Specification Document
GoTrip - Smart Travel Planning Backend
"""

# API SPECIFICATION

## 1. BASE URL
- Development: http://localhost:8000
- Production: [Your production URL]

## 2. AUTHENTICATION
Currently no authentication required (demo mode)
Future: JWT tokens via Supabase

## 3. ENDPOINTS

### 3.1 POST /api/plan-trip
**Description:** Generate an optimized trip itinerary

**Method:** POST
**Content-Type:** application/json

**Request Schema:**
{
  "start_date": "YYYY-MM-DD",      // Required: Trip start date
  "end_date": "YYYY-MM-DD",        // Required: Trip end date (must be after start_date)
  "budget": 50000,                  // Required: Total budget (number, > 0)
  "preferences": [                  // Required: Array of place categories
    "beach",                         // Supported: beach, history, adventure, food, 
    "food"                           // shopping, nature, religious, cultural
  ],
  "latitude": 28.6139,             // Optional: Center latitude (-90 to 90)
  "longitude": 77.2090             // Optional: Center longitude (-180 to 180)
}

**Response Schema (Success - 200):**
{
  "trip_id": "uuid-string",         // Unique trip identifier
  "start_date": "2026-02-01",
  "end_date": "2026-02-05",
  "total_days": 5,
  "total_distance": 245.5,          // Total travel distance in km
  "total_estimated_cost": 49500,    // Total estimated cost
  "daily_itineraries": [
    {
      "day": 1,
      "date": "2026-02-01",
      "places": [
        {
          "id": "place-id",
          "name": "Marina Beach",
          "category": "beach",
          "latitude": 13.0499,
          "longitude": 80.2824,
          "rating": 4.2,            // 0-5 rating
          "reviews": 1250,          // Number of reviews
          "estimated_cost": 500,    // Estimated cost to visit
          "description": "Popular urban beach with scenic views",
          "photo_url": null,        // URL to place image (if available)
          "opening_hours": null     // Opening hours (if available)
        }
      ],
      "total_distance": 52.3,       // Distance for the day
      "total_time": 240,            // Time in minutes
      "estimated_budget": 9850      // Budget for the day
    }
  ],
  "algorithm_explanation": "Trip Plan Algorithm: ..."
}

**Error Response (4xx/5xx):**
{
  "detail": "Error message explaining what went wrong"
}

**Status Codes:**
- 200 OK: Trip successfully planned
- 400 Bad Request: Invalid input (validation error)
- 500 Internal Server Error: Server error

**Validation Rules:**
- start_date and end_date must be valid dates in YYYY-MM-DD format
- end_date must be after start_date
- budget must be > 0
- preferences list must contain 1-8 items
- latitude: -90 to 90 (inclusive)
- longitude: -180 to 180 (inclusive)

**Example Request:**
POST /api/plan-trip
Content-Type: application/json

{
  "start_date": "2026-02-01",
  "end_date": "2026-02-05",
  "budget": 50000,
  "preferences": ["beach", "food", "adventure"],
  "latitude": 28.6139,
  "longitude": 77.2090
}

**Example Response:**
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
  "algorithm_explanation": "Trip Plan Algorithm:\n1. Scoring: ..."
}

---

### 3.2 GET /api/health
**Description:** Health check endpoint

**Method:** GET

**Response:**
{
  "status": "healthy",
  "service": "trip-planning-api"
}

**Status Code:** 200 OK

---

### 3.3 GET /info
**Description:** Get API information and algorithm details

**Method:** GET

**Response:**
{
  "api_name": "GoTrip Smart Trip Planning API",
  "version": "1.0.0",
  "algorithms_used": {
    "scoring": "Multi-factor weighted scoring",
    "selection": "Greedy algorithm",
    "optimization": "Nearest Neighbor heuristic",
    "weather_integration": "Rule-based adjustment"
  },
  "features": [...],
  "api_sources": {...}
}

**Status Code:** 200 OK

---

## 4. DATA TYPES

### PreferenceEnum
Supported values: beach, history, adventure, food, shopping, nature, religious, cultural

### PlaceModel
- id: string (unique identifier)
- name: string (place name)
- category: PreferenceEnum
- latitude: number (-90 to 90)
- longitude: number (-180 to 180)
- rating: number (0-5)
- reviews: integer (≥0)
- estimated_cost: number (≥0)
- description: string
- photo_url: string or null
- opening_hours: string or null

### DayItinerary
- day: integer (1-based day number)
- date: string (YYYY-MM-DD)
- places: array of PlaceModel
- total_distance: number (kilometers)
- total_time: number (minutes)
- estimated_budget: number (currency units)

### TripItineraryResponse
- trip_id: string (UUID)
- start_date: string (YYYY-MM-DD)
- end_date: string (YYYY-MM-DD)
- total_days: integer
- total_distance: number
- total_estimated_cost: number
- daily_itineraries: array of DayItinerary
- algorithm_explanation: string

---

## 5. SCORING FORMULA

Score = (Rating × 0.3) + (Preference_Match × 0.4) + 
        (Popularity × 0.1) + (Distance_Bonus × 0.2)

Where:
- Rating: Normalized from 0-5 to 0-100
- Preference_Match: 100 if category in preferences, 50 otherwise
- Popularity: min(reviews / 1000, 1.0) × 100
- Distance_Bonus: max((max_distance - distance) / max_distance, 0) × 100

---

## 6. SELECTION ALGORITHM

Greedy Algorithm:
1. Sort places by score (descending)
2. For each place:
   - If (total_cost + place_cost ≤ budget) AND 
       (total_time + place_time ≤ available_time):
     - Add place to itinerary
     - Update budget and time
3. Return selected places

---

## 7. ROUTE OPTIMIZATION

Nearest Neighbor Algorithm:
1. Start at first place
2. While unvisited places exist:
   - Find nearest unvisited place
   - Move to that place
   - Add distance to total
3. Return total distance and optimized order

Complexity: O(n²)
Guarantee: Result ≤ 2× optimal (average case)

---

## 8. RATE LIMITING

Currently: No rate limiting
Future: Implement based on deployment needs

---

## 9. CORS POLICY

Currently: Allow all origins (*)
Production: Restrict to specific domains

---

## 10. ERROR CODES

### 400 Bad Request
Reasons:
- Invalid date format
- end_date before start_date
- Budget ≤ 0
- Empty preferences
- Out of range coordinates
- Missing required fields

Example:
{
  "detail": "end_date must be after start_date"
}

### 500 Internal Server Error
Server error occurred. Falls back to mock data.

Example:
{
  "detail": "An unexpected error occurred while planning the trip"
}

---

## 11. PERFORMANCE METRICS

- Average Response Time: < 500ms
- Time Complexity: O(n log n) [dominated by sorting]
- Space Complexity: O(n) [storing places]
- Max Places Processed: 1000+
- Supported Trip Duration: 1-365 days

---

## 12. CONTENT NEGOTIATION

Request:
- Accept: application/json (default)
- Content-Type: application/json (required for POST)

Response:
- Content-Type: application/json

---

## 13. CACHING RECOMMENDATIONS

Cache Headers (future implementation):
- Cache-Control: max-age=3600 (1 hour)
- ETag: Use request hash
- Last-Modified: Server response time

---

## 14. API VERSIONING

Current Version: 1.0.0

Future Versions:
- v2: With user preferences learning
- v3: With real-time traffic integration

URL Pattern (proposed):
- /api/v1/plan-trip
- /api/v2/plan-trip

---

## 15. USAGE EXAMPLES

### cURL
curl -X POST "http://localhost:8000/api/plan-trip" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 50000,
    "preferences": ["beach", "food"]
  }'

### Python (requests)
import requests

response = requests.post(
  'http://localhost:8000/api/plan-trip',
  json={
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
    'budget': 50000,
    'preferences': ['beach', 'food']
  }
)

### JavaScript (fetch)
fetch('http://localhost:8000/api/plan-trip', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    start_date: '2026-02-01',
    end_date: '2026-02-05',
    budget: 50000,
    preferences: ['beach', 'food']
  })
}).then(r => r.json()).then(console.log)

### Dart/Flutter
import 'package:http/http.dart' as http;
import 'dart:convert';

final response = await http.post(
  Uri.parse('http://localhost:8000/api/plan-trip'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
    'budget': 50000,
    'preferences': ['beach', 'food']
  })
);

---

## 16. CHANGELOG

### v1.0.0 (Current)
- Initial release
- Multi-factor scoring
- Greedy selection algorithm
- Nearest neighbor route optimization
- Weather integration
- Mock data provider
- REST API

### Planned
- v1.1.0: API key authentication
- v1.2.0: Google Places integration
- v2.0.0: Machine learning preferences
- v2.1.0: Real-time traffic data
