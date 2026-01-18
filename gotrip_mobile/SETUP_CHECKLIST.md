# API Integration Checklist

## Pre-Integration (Before You Start)

### Flutter Setup
- [x] HTTP package installed (`flutter pub add http`)
- [x] Provider package installed (already in pubspec.yaml)
- [x] `api_service.dart` created
- [x] `destination_api_provider.dart` created
- [x] `main.dart` updated with new provider
- [x] Documentation ready

### Documentation Review
- [ ] Read `START_API_INTEGRATION.md` (overview)
- [ ] Read `BACKEND_SETUP_QUICK_START.md` (choose your backend)
- [ ] Read `IMPLEMENTATION_GUIDE.md` (how to update code)
- [ ] Keep `API_ARCHITECTURE.md` for reference

---

## Backend Setup (Choose One)

### Option A: Node.js + Express

```bash
# Step 1: Create folder
[ ] mkdir gotrip-backend
[ ] cd gotrip-backend

# Step 2: Initialize
[ ] npm init -y

# Step 3: Install dependencies
[ ] npm install express cors dotenv axios

# Step 4: Create files
[ ] Create server.js (copy from BACKEND_SETUP_QUICK_START.md)
[ ] Create routes/destinations.js
[ ] Create routes/hotels.js
[ ] Create routes/activities.js
[ ] Create routes/categories.js
[ ] Create .env file

# Step 5: Update package.json
[ ] Add start & dev scripts

# Step 6: Test
[ ] npm run dev
[ ] Should see: ✅ Backend running on http://localhost:8000
```

### Option B: Python + FastAPI

```bash
# Step 1: Create virtual environment
[ ] python -m venv venv
[ ] venv\Scripts\activate  (Windows)

# Step 2: Install dependencies
[ ] pip install fastapi uvicorn python-dotenv

# Step 3: Create main.py
[ ] Create main.py (copy from BACKEND_SETUP_QUICK_START.md)
[ ] Create .env file (optional)

# Step 4: Test
[ ] python main.py
[ ] Should see: Uvicorn running on http://127.0.0.1:8000
```

---

## Health Check

Backend should be responding:

```bash
# Test in terminal or browser
curl http://localhost:8000/api/health

# Expected response:
{"status":"Backend is running!"}
```

- [ ] Backend health check passes
- [ ] No connection refused errors
- [ ] Port 8000 is accessible

---

## Update Trip Planning Screen

### Step 1: Add Imports
File: `lib/screens/trip_planning_screen.dart`

```dart
[ ] import 'package:provider/provider.dart';
[ ] import '../providers/destination_api_provider.dart';
```

### Step 2: Add State Variable
```dart
[ ] Add: String? error; to _TripPlanningScreenState
```

### Step 3: Update _planTrip() Method
```dart
[ ] Replace entire _planTrip() method with one from IMPLEMENTATION_GUIDE.md
```

### Step 4: Add Helper Method (Optional)
```dart
[ ] Add _showErrorDialog() method from IMPLEMENTATION_GUIDE.md
```

### Step 5: Verify Imports in main.dart
```dart
[ ] Verify DestinationAPIProvider is imported
[ ] Verify DestinationAPIProvider is added to MultiProvider
```

---

## Test the Integration

### Step 1: Start Backend
```bash
[ ] Open Terminal
[ ] Navigate to gotrip-backend folder
[ ] Run: npm run dev (or: python main.py)
[ ] Wait for: ✅ Backend running message
```

### Step 2: Start Flutter App
```bash
[ ] Open new Terminal
[ ] Navigate to gotrip_mobile folder
[ ] Run: flutter run -d chrome
[ ] Wait for: App loads in browser
```

### Step 3: Test Form
```bash
[ ] Click on Plan Trip (map icon or bottom nav)
[ ] Form appears
[ ] Select start date: today
[ ] Select end date: today + 5 days
[ ] Enter budget: 15000
[ ] Select 2-3 preferences (beach, adventure, etc.)
[ ] Click "Plan My Trip"
```

### Step 4: Verify Results
```bash
[ ] Loading spinner appears
[ ] Wait 2-3 seconds
[ ] Recommendations display
[ ] See destination cards with:
    [ ] Name
    [ ] Cost
    [ ] Rating
    [ ] Distance
    [ ] Description
[ ] No errors in console
```

---

## Verification Points

### Flutter Console
- [ ] No connection errors
- [ ] No type errors
- [ ] No null reference exceptions
- [ ] Clean build output

### Backend Console
- [ ] Received POST request to /api/destinations/recommendations
- [ ] Returned 200 OK status
- [ ] Response contains destinations array
- [ ] No server errors (no 5xx status codes)

### Network Tab (Chrome DevTools)
- [ ] Request goes to http://localhost:8000/api/destinations/recommendations
- [ ] Method: POST
- [ ] Status: 200
- [ ] Response time: 200-500ms
- [ ] Response body: valid JSON with destinations

### Recommendations Quality
- [ ] All destinations match selected preferences
- [ ] All costs <= entered budget
- [ ] Ratings are between 1-5
- [ ] Distance values are reasonable (0-5000)
- [ ] Descriptions are meaningful

---

## Troubleshooting

### If Backend Won't Start
```
Issue: npm run dev fails
Solution:
[ ] npm install (missing dependencies)
[ ] Check Node.js version: node -v
[ ] Check npm version: npm -v
[ ] Delete node_modules & package-lock.json, reinstall

Issue: Port 8000 already in use
Solution:
[ ] Check what's using port 8000: netstat -ano | findstr :8000
[ ] Kill process: taskkill /PID <PID> /F
[ ] Use different port: change PORT in .env or code
```

### If Flutter Won't Connect
```
Issue: Connection error: Could not reach backend
Solution:
[ ] Verify backend is running
[ ] Check backend port is 8000
[ ] Test: http://localhost:8000/api/health in browser
[ ] Check CORS is enabled in backend
[ ] Restart Flutter app
[ ] Try: flutter clean && flutter run -d chrome
```

### If No Recommendations Show
```
Issue: "No destinations found" message
Solution:
[ ] Check if preferences match backend data
[ ] Try different preferences (beach, food, nature)
[ ] Increase budget (min 8000)
[ ] Check backend logs for errors
[ ] Test endpoint with Postman:
    POST http://localhost:8000/api/destinations/recommendations
    {
      "preferences": ["beach"],
      "max_budget": 15000,
      "days": 5,
      "location": "Delhi"
    }
```

### If App Crashes
```
Issue: App crashes on "Plan My Trip" click
Solution:
[ ] Check Flutter console for specific error
[ ] Verify all imports are correct
[ ] Verify provider is added to main.dart
[ ] Check trip_planning_screen.dart has _planTrip() method
[ ] Run: flutter pub get
[ ] Run: flutter clean && flutter pub get && flutter run -d chrome
```

---

## Performance Optimization (After Basic Setup)

- [ ] Add loading indicators
- [ ] Add error snackbars
- [ ] Cache recommendations
- [ ] Add pagination (10 at a time)
- [ ] Optimize images
- [ ] Add retry logic for failed requests

---

## Security Checklist (Before Production)

- [ ] Validate all user inputs
- [ ] Sanitize API responses
- [ ] Add rate limiting
- [ ] Use HTTPS endpoints
- [ ] Secure API keys in .env
- [ ] Add authentication
- [ ] Log all API calls

---

## Next Phase: Real Data

After basic integration is working:

- [ ] Connect Google Places API
- [ ] Add Amadeus API for hotels
- [ ] Set up Supabase database
- [ ] Implement caching
- [ ] Deploy backend to production
- [ ] Update API URL in production build

---

## Documentation References

If you get stuck, check these:

| Problem | Document |
|---------|----------|
| How do I set up a backend? | BACKEND_SETUP_QUICK_START.md |
| How does the system work? | API_ARCHITECTURE.md |
| How do I update the code? | IMPLEMENTATION_GUIDE.md |
| What endpoints are available? | API_INTEGRATION_GUIDE.md |
| What do I do next? | START_API_INTEGRATION.md |

---

## Sign-Off

### I Have Completed:
- [ ] Backend is running on localhost:8000
- [ ] /api/health returns success
- [ ] Flutter app updated with API calls
- [ ] Form validation works
- [ ] Recommendations display from API
- [ ] No console errors
- [ ] All preferences filter correctly
- [ ] Budget filtering works

### Status: ✅ READY FOR PRODUCTION

**Next Steps:**
1. Test with real user data
2. Optimize performance
3. Connect real data sources
4. Deploy backend to production
5. Update production URL

---

## Quick Links

- Backend Code: `/BACKEND_SETUP_QUICK_START.md`
- Frontend Code: `/IMPLEMENTATION_GUIDE.md`
- Architecture: `/API_ARCHITECTURE.md`
- Full Reference: `/API_INTEGRATION_GUIDE.md`

---

**Created**: January 2026  
**Status**: Ready for Implementation  
**Questions**: Refer to START_API_INTEGRATION.md

