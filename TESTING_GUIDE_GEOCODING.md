# Geocoding Feature - Quick Testing Guide

**Feature:** City Name to Coordinates Conversion  
**Status:** ✅ Ready for Testing  
**Date:** January 20, 2026

---

## Quick Start

### Step 1: Start Backend

```bash
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

**Expected Output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

**Verify:** Open http://localhost:8000/docs

### Step 2: Start Frontend

```bash
cd gotrip_mobile
flutter run -d chrome
```

**Navigate to:** Trip Planning Screen

---

## Test Case 1: Basic Geocoding (Hardcoded City)

### Input:
- **City:** Goa
- **Start Date:** 2026-02-01
- **End Date:** 2026-02-05
- **Budget:** 25,000
- **Preferences:** beach, food

### Expected Flow:
1. Frontend sends: `city_name: "Goa"`
2. Backend geocodes: Goa → (15.2993, 74.1240)
3. Backend plans trip from Goa coordinates
4. Frontend receives itinerary
5. Shows: "Trip planned successfully from Goa!"

### Testing via UI:
```
1. Go to "Trip Planning" screen
2. Enter Start Date: Feb 1, 2026
3. Enter End Date: Feb 5, 2026
4. Enter Budget: 25000
5. Enter City: Goa
6. Select Preferences: Beach ✓, Food ✓
7. Click "Plan Trip"
8. Wait for response (should show geocoded coordinates in logs)
```

### Testing via API (Swagger):
```
1. Open http://localhost:8000/docs
2. Expand POST /api/plan-trip
3. Click "Try it out"
4. Enter:
{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 25000,
    "preferences": ["beach", "food"],
    "city_name": "Goa"
}
5. Click "Execute"
6. Check Response: Look for "algorithm_explanation" with "starting from Goa"
```

### Expected Response:
```json
{
    "trip_id": "550e8400-...",
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "total_days": 5,
    "total_distance": 245.5,
    "total_estimated_cost": 24500,
    "algorithm_explanation": "Trip Plan Algorithm starting from Goa: ...",
    "daily_itineraries": [...]
}
```

### Backend Logs:
```
INFO     Received trip planning request: ...
INFO     Geocoded city 'Goa' to (15.2993, 74.1240)
INFO     Trip: 5 days, Budget: ₹25000 (₹5000/day), Preferences: ['beach', 'food'], Center: (15.2993, 74.1240)
INFO     Successfully planned trip: 550e8400-...
```

---

## Test Case 2: Different Hardcoded Cities

### Test Multiple Cities:

| City | Expected Lat | Expected Lon | Try It |
|------|--------------|--------------|--------|
| Mumbai | 19.0760 | 72.8777 | ✅ Test |
| Delhi | 28.6139 | 77.2090 | ✅ Test |
| Bangalore | 12.9716 | 77.5946 | ✅ Test |
| Jaipur | 26.9124 | 75.7873 | ✅ Test |
| Agra | 27.1767 | 78.0081 | ✅ Test |
| Varanasi | 25.3176 | 82.9739 | ✅ Test |
| Pondicherry | 11.9416 | 79.8083 | ✅ Test |

### Quick Test Script:

```bash
# Test Mumbai
curl -X POST http://localhost:8000/api/plan-trip \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2026-02-01",
    "end_date": "2026-02-03",
    "budget": 20000,
    "preferences": ["food", "shopping"],
    "city_name": "Mumbai"
  }' | jq '.algorithm_explanation'

# Expected: "Trip Plan Algorithm starting from Mumbai: ..."
```

---

## Test Case 3: API Fallback (Nominatim)

### Unlisted City (Will query Nominatim API):

```json
{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 50000,
    "preferences": ["adventure", "nature"],
    "city_name": "Leh"  // Not in hardcoded list
}
```

### Expected Flow:
1. Frontend sends: `city_name: "Leh"`
2. Backend tries hardcoded lookup → Not found
3. Backend queries Nominatim API
4. Nominatim returns: (34.1526, 77.5769)
5. Backend plans trip from Leh
6. Shows in logs: "Found Leh via Nominatim API: (34.1526, 77.5769)"

### Testing:
```
1. Open Swagger: http://localhost:8000/docs
2. Try different unlisted cities:
   - "Leh" (Ladakh)
   - "McLeodganj" (Himachal Pradesh)
   - "Khajuraho" (Madhya Pradesh)
3. Watch backend logs for "Found X via Nominatim API"
```

---

## Test Case 4: Error Handling

### Test 1: Invalid City Name

```json
{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 25000,
    "preferences": ["beach"],
    "city_name": "XYZInvalidCity123"
}
```

**Expected Response:**
```json
{
    "trip_id": "550e8400-...",
    "daily_itineraries": [],
    "algorithm_explanation": "Error: Could not find coordinates for city: XYZInvalidCity123"
}
```

**Backend Log:**
```
ERROR Geocoding error: Could not find coordinates for city: XYZInvalidCity123
```

### Test 2: Empty City Name

**UI:** Leave city field empty and click "Plan Trip"

**Expected:** Popup showing "Please enter a city name (e.g., "Goa", "Mumbai", "Delhi")"

### Test 3: No Preferences Selected

**UI:** Select city, dates, budget but don't select any preferences

**Expected:** Popup showing "Please select at least one preference"

---

## Test Case 5: Backward Compatibility (Old API)

### Old Method (Still Works):

```json
{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05",
    "budget": 25000,
    "preferences": ["beach"],
    "latitude": 15.2993,
    "longitude": 74.1240
}
```

**Expected:** Trip planned successfully using provided coordinates

**Note:** If both `city_name` and `latitude/longitude` provided, `city_name` takes priority

---

## Test Case 6: Case Insensitivity

### Test Different Cases:

```
"goa"       → Should work (lowercase)
"GOA"       → Should work (uppercase)
"Goa"       → Should work (mixed case)
"  Goa  "   → Should work (with spaces - auto-trimmed)
```

### Test via API:

```bash
# All should work
curl ... -d '{"city_name": "goa", ...}'
curl ... -d '{"city_name": "GOA", ...}'
curl ... -d '{"city_name": "Goa", ...}'
curl ... -d '{"city_name": "  goa  ", ...}'
```

---

## Performance Testing

### Measure Geocoding Speed:

```python
import time
import requests

response = requests.post(
    'http://localhost:8000/api/plan-trip',
    json={
        'start_date': '2026-02-01',
        'end_date': '2026-02-05',
        'budget': 25000,
        'preferences': ['beach'],
        'city_name': 'Goa'
    }
)

# Check backend logs for timing
# Expected: "Geocoded city 'Goa' to (...) in ~1ms (hardcoded)"
#           vs "Found Goa via Nominatim API in ~200-500ms"
```

---

## Logging & Debugging

### Enable Debug Logging:

**Backend logs show:**
```
INFO     Geocoding city: Goa
INFO     Found Goa in hardcoded list: (15.2993, 74.1240)
INFO     Geocoded city 'Goa' to (15.2993, 74.1240)
INFO     Trip: 5 days, Budget: ₹25000 (₹5000/day), Preferences: ['beach'], Center: (15.2993, 74.1240)
```

### Frontend Console Output:

```dart
// In lib/screens/trip_planning_screen.dart
print('Planning trip for city: Goa');
print('Preferences: [beach, food]');
print('Budget: 25000');
print('Duration: 5 days');
```

**Flutter logs show:**
```
I/flutter: Planning trip for city: Goa
I/flutter: Preferences: [beach, food]
I/flutter: Budget: 25000
I/flutter: Duration: 5 days
I/flutter: Response: {"trip_id": "...", ...}
```

---

## Integration Test Checklist

- [ ] **Hardcoded Lookup** - Goa, Mumbai, Delhi work instantly
- [ ] **API Fallback** - Unlisted cities work via Nominatim
- [ ] **Case Insensitivity** - "goa", "GOA", "Goa" all work
- [ ] **Whitespace Handling** - "  Goa  " works correctly
- [ ] **Error Handling** - Invalid city shows proper error
- [ ] **Backward Compatibility** - Old coordinate-based requests work
- [ ] **Response Format** - Response includes "algorithm_explanation"
- [ ] **Distance Calculations** - Distances calculated from geocoded coords
- [ ] **Daily Itineraries** - Places distributed across days correctly
- [ ] **UI Integration** - Frontend receives and displays itinerary
- [ ] **Error Messages** - User sees helpful error messages
- [ ] **Loading State** - UI shows loading spinner during request

---

## Common Issues & Fixes

### Issue 1: "Connection error: Could not reach backend"

**Cause:** Backend not running on http://localhost:8000

**Fix:**
```bash
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

### Issue 2: "City not found" error

**Cause:** City name not recognized by geocoding service

**Fix:** Check spelling, or use a nearby major city

### Issue 3: Long response time (>5 seconds)

**Cause:** Nominatim API is slow or unreachable

**Fix:** Use a city from the hardcoded list (instant response)

### Issue 4: No preferences selected error

**Cause:** User forgot to select at least one preference

**Fix:** Select at least one checkbox before clicking "Plan Trip"

### Issue 5: Dates in wrong order

**Cause:** End date is before start date

**Fix:** End date must be after start date

---

## Success Criteria

✅ **Test Passed When:**

1. User enters city name (e.g., "Goa")
2. City is converted to coordinates automatically
3. Trip is planned using those coordinates
4. User sees "Trip planned successfully from Goa!"
5. Response includes algorithm explanation mentioning geocoding
6. Distances calculated are reasonable
7. Daily itineraries show correct places
8. All error cases handled gracefully

---

## Resources

- **API Docs:** http://localhost:8000/docs
- **Hardcoded Cities:** `backend/app/integrations/geocoding_service.py`
- **Trip Planning Service:** `backend/app/services/trip_planning_service.py`
- **Frontend API Service:** `gotrip_mobile/lib/services/api_service.dart`
- **Trip Planning Screen:** `gotrip_mobile/lib/screens/trip_planning_screen.dart`

---

**Ready to Test? Start with Test Case 1! 🚀**
