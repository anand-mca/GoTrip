# GoTrip Backend - Quick Start

## Installation

```powershell
# Install dependencies
pip install -r requirements.txt
```

## Run Server

```powershell
python backend.py
```

Server starts at: **http://localhost:8000**

## Test Endpoints

### Health Check
```
GET http://localhost:8000/api/health
```

### Plan Trip
```
POST http://localhost:8000/api/plan-trip
Content-Type: application/json

{
  "start_location": {
    "name": "Delhi",
    "lat": 28.6139,
    "lng": 77.2090
  },
  "preferences": ["beach", "adventure"],
  "budget": 25000,
  "start_date": "2026-02-01T00:00:00Z",
  "end_date": "2026-02-07T00:00:00Z",
  "return_to_start": true
}
```

### Get Destinations
```
GET http://localhost:8000/api/destinations?preferences=beach,adventure
```

## API Documentation

Interactive docs available at: **http://localhost:8000/docs**

## Features

✅ Trip optimization with minimal travel distance  
✅ Budget constraint satisfaction  
✅ Time/date constraint handling  
✅ Real distance and cost calculations  
✅ Day-by-day itinerary generation  
✅ Route segment details  

## Mock Data

Currently includes 8 Indian destinations across categories:
- Beach (Goa)
- Adventure (Manali)
- History (Jaipur, Agra)
- Nature (Kerala)
- Food (Mumbai)
- Religious (Rishikesh)
- Cultural (Udaipur)

## Production Notes

To add real data:
1. Replace DESTINATIONS list with database
2. Integrate Google Places API for real POI data
3. Add OpenRouteService API key for better routing
4. Implement caching for performance
