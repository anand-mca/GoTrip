# API Integration Architecture Diagram & Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                          │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │     Trip Planning Screen                       │    │
│  │  (Collects preferences, budget, dates)         │    │
│  └────────────────────────────────────────────────┘    │
│                        │                                │
│                        ▼                                │
│  ┌────────────────────────────────────────────────┐    │
│  │  DestinationAPIProvider                        │    │
│  │  (Manages API state & data caching)            │    │
│  └────────────────────────────────────────────────┘    │
│                        │                                │
│                        ▼                                │
│  ┌────────────────────────────────────────────────┐    │
│  │  APIService                                    │    │
│  │  (Handles HTTP requests to backend)            │    │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
                         │
                         │ HTTP/REST
                         │ (JSON)
                         ▼
┌─────────────────────────────────────────────────────────┐
│              BACKEND SERVER (Port 8000)                 │
│           (Node.js or Python or Your Choice)            │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Route Handlers                                │    │
│  │  ├─ /api/health                                │    │
│  │  ├─ /api/destinations/recommendations          │    │
│  │  ├─ /api/destinations/search                   │    │
│  │  ├─ /api/hotels                                │    │
│  │  └─ /api/activities/search                     │    │
│  └────────────────────────────────────────────────┘    │
│                        │                                │
│                        ▼                                │
│  ┌────────────────────────────────────────────────┐    │
│  │  Business Logic                                │    │
│  │  ├─ Filter destinations by preferences         │    │
│  │  ├─ Filter by budget                           │    │
│  │  ├─ Calculate best options                     │    │
│  └────────────────────────────────────────────────┘    │
│                        │                                │
│                        ▼                                │
│  ┌────────────────────────────────────────────────┐    │
│  │  Data Sources (Choose One or Multiple)         │    │
│  │  ├─ Database (Supabase/PostgreSQL)             │    │
│  │  ├─ Google Places API                          │    │
│  │  ├─ Amadeus API                                │    │
│  │  ├─ Viator/ToursByLocals API                   │    │
│  │  └─ Mock Data (for testing)                    │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## API Request Flow

```
User Input (Trip Planning Screen)
    │
    │ dates: "2025-01-20" to "2025-01-25"
    │ budget: 15000
    │ preferences: ["beach", "adventure"]
    │
    ▼
┌─────────────────────────────────┐
│ Form Validation                 │
│ ✓ All fields filled?            │
│ ✓ Valid date range?             │
│ ✓ Preferences selected?         │
└─────────────────────────────────┘
    │
    ├─ No ──► Show error message
    │
    ▼ (Yes)
┌─────────────────────────────────┐
│ Call API:                       │
│ POST /recommendations           │
│ {                               │
│   preferences: ["beach", ...],  │
│   max_budget: 15000,            │
│   days: 6,                      │
│   location: "Delhi"             │
│ }                               │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Backend Processing:             │
│ 1. Parse request                │
│ 2. Query data sources           │
│ 3. Filter by category           │
│ 4. Filter by budget             │
│ 5. Sort by rating               │
│ 6. Return top 10                │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ API Response:                   │
│ {                               │
│   destinations: [               │
│     {                           │
│       id: "beach1",             │
│       name: "Goa Beach",        │
│       cost: 8000,               │
│       rating: 4.5,              │
│       ...                       │
│     },                          │
│     ...                         │
│   ]                             │
│ }                               │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Display Results:                │
│ Show cards for each destination │
│ ├─ Name                         │
│ ├─ Cost                         │
│ ├─ Rating                       │
│ ├─ Distance                     │
│ └─ Book Button                  │
└─────────────────────────────────┘
```

---

## Implementation Timeline

### Phase 1: Setup (Today) ⚡
```
✅ Create API service layer
✅ Create state management (Provider)
✅ Backend templates provided
⏱️  Estimated: 30 minutes
```

### Phase 2: Backend Setup (Today) ⚡
```
⏳ Choose Node.js or Python
⏳ Set up project structure
⏳ Implement endpoints
⏳ Test with Postman
⏱️  Estimated: 1-2 hours
```

### Phase 3: Integration (Today) ⚡
```
⏳ Update trip_planning_screen.dart
⏳ Connect to backend API
⏳ Test end-to-end
⏱️  Estimated: 30 minutes
```

### Phase 4: Real Data (Optional) 🚀
```
⏳ Integrate Google Places API
⏳ Add Amadeus API for hotels
⏳ Implement caching
⏳ Optimize performance
⏱️  Estimated: 2-3 hours
```

---

## Quick Start Decision Tree

```
                  START
                    │
        ┌───────────┴───────────┐
        │                       │
    Backend or    Already have
    Frontend?     backend?
        │              │
    BACKEND       YES  │   NO
        │              │   │
        │              │   ▼
        │              │  ┌──────────────┐
        │              │  │ Choose Stack │
        │              │  ├─ Node.js    │
        │              │  ├─ Python     │
        │              │  └─ Other      │
        │              │  └──────────────┘
        │              │   │
        │              └───┼───┐
        │                  │   │
        ▼                  ▼   ▼
    ┌──────────────────────────────┐
    │ Copy provided server code     │
    │ from BACKEND_SETUP file      │
    │ npm run dev / python main.py │
    └──────────────────────────────┘
        │
        ▼
    ┌──────────────────────────────┐
    │ Update Flutter:              │
    │ 1. Set _baseUrl              │
    │ 2. Replace mock with API     │
    │ 3. flutter run -d chrome     │
    └──────────────────────────────┘
        │
        ▼
    ┌──────────────────────────────┐
    │ TEST:                        │
    │ Fill trip form               │
    │ Click "Plan My Trip"         │
    │ See real recommendations!    │
    └──────────────────────────────┘
```

---

## Files Created/Modified

### New Files
```
lib/services/api_service.dart                    (150 lines)
lib/providers/destination_api_provider.dart      (120 lines)
API_INTEGRATION_GUIDE.md                         (Detailed)
BACKEND_SETUP_QUICK_START.md                     (Ready-to-use)
API_INTEGRATION_SUMMARY.md                       (This file)
API_ARCHITECTURE.md                              (This file)
```

### Modified Files
```
lib/main.dart                                    (+1 import, +1 provider)
pubspec.yaml                                     (+http package)
```

---

## Expected Response Format

All API endpoints return JSON in this format:

```json
{
  "success": true,
  "data": {
    "destinations": [
      {
        "id": "string",
        "name": "string",
        "category": "string",
        "latitude": number,
        "longitude": number,
        "cost": number,
        "days": number,
        "distance": number,
        "rating": number,
        "reviews": number,
        "description": "string",
        "image": "string (URL)"
      }
    ]
  },
  "timestamp": "ISO8601 string"
}
```

---

## Debugging Tips

### If you see: "Connection error: Could not reach backend"
1. Check if backend is running: `http://localhost:8000/api/health`
2. Verify port is 8000
3. Check CORS is enabled in backend

### If you see: "No destinations found"
1. Backend is running but returning empty array
2. Check if preferences match backend categories
3. Verify budget is reasonable

### If the app crashes
1. Check Flutter console for error message
2. Look at backend server logs
3. Ensure request format matches API spec

---

## Next Steps

1. **Read**: [BACKEND_SETUP_QUICK_START.md](./BACKEND_SETUP_QUICK_START.md)
2. **Choose**: Node.js or Python
3. **Setup**: Backend server (5-10 min)
4. **Test**: /api/health endpoint
5. **Update**: Flutter to use API
6. **Celebrate**: 🎉 Real data flowing!

---

