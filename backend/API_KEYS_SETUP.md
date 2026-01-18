# 🔑 API Keys Setup Guide - Complete

Your backend is now **running on http://127.0.0.1:8000** ✅

---

## 📊 CURRENT STATUS

| Feature | Status | API Key Needed |
|---------|--------|---|
| Smart Trip Planning | ✅ **WORKING** with Mock Data | Optional |
| Place Fetching | ✅ **WORKING** with Mock Data | Optional |
| Route Optimization | ✅ **WORKING** | ❌ No |
| Scoring Algorithm | ✅ **WORKING** | ❌ No |
| Weather Integration | ✅ **WORKING** with Mock Data | Optional |

---

## ✅ TEST WITHOUT API KEYS (USE MOCK DATA)

Your API is **fully functional** right now! It's using 16 sample places. Test it:

### Option 1: Interactive Testing (Easiest)
Open in browser: **http://127.0.0.1:8000/docs**

Click "Try it out" on `/api/plan-trip` endpoint and test!

### Option 2: Test Script
```bash
python test_api.py
```

### Option 3: cURL
```bash
curl -X POST "http://127.0.0.1:8000/api/plan-trip" \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2026-02-01",
    "end_date": "2026-02-05", 
    "budget": 50000,
    "preferences": ["beach", "food", "adventure"],
    "latitude": 28.6139,
    "longitude": 77.2090
  }'
```

**Example Response:**
```json
{
  "start_date": "2026-02-01",
  "end_date": "2026-02-05",
  "total_places": 10,
  "total_estimated_cost": 35000,
  "itinerary": [
    {
      "day": 1,
      "date": "2026-02-01",
      "places": [
        {
          "name": "Marina Beach",
          "type": "beach",
          "estimated_cost": 2000,
          "distance": 5.2,
          "estimated_time_minutes": 240
        }
      ],
      "daily_cost": 8500,
      "daily_distance": 28.3,
      "estimated_travel_time": 720
    }
  ]
}
```

---

## 🔌 ADDING REAL API KEYS (Optional for Enhanced Features)

### There are 3 Optional API Keys:

#### 1️⃣ Google Places API
**What it does:** Search for real places in user's city

**When you need it:** When mock data isn't enough

**How to get it:**
```
1. Go to: https://console.cloud.google.com
2. Create a new project
3. Enable "Places API" and "Maps API"
4. Create an API key (Credentials > API Key)
5. Restrict it to "HTTP referrers" with your backend URL
```

#### 2️⃣ Google Directions API
**What it does:** Calculate real travel routes and distances

**When you need it:** For accurate routing between places

**How to get it:**
```
Same project as above - enable "Directions API"
Use same API key or create a new one
```

#### 3️⃣ OpenWeather API
**What it does:** Get real weather data for smart filtering

**When you need it:** To avoid places during bad weather

**How to get it:**
```
1. Go to: https://openweathermap.org/api
2. Sign up (free tier available)
3. Go to API keys section
4. Copy your API key
```

---

## 📝 SETTING UP API KEYS

### Step 1: Copy the .env File
```bash
# In backend directory, create .env from template
copy .env.example .env

# Or on Mac/Linux:
cp .env.example .env
```

### Step 2: Add Your Keys to `.env`
Open `.env` file in VS Code:
```
# Leave as True to use mock data + real APIs when available
USE_MOCK_DATA=True
DEBUG=False

# Add your API keys here (leave empty to use mock data)
GOOGLE_PLACES_API_KEY=your_key_here
GOOGLE_DIRECTIONS_API_KEY=your_key_here
OPENWEATHER_API_KEY=your_key_here
```

### Step 3: Restart Server
```bash
# Stop current server (Ctrl+C in terminal)
# Start again
python "c:\Users\anand\OneDrive\Desktop\GoTrip\backend\start_server.py"
```

---

## 🚀 HOW THEY WORK TOGETHER

```
┌─────────────────────────────────────────┐
│         User Sends Request              │
│   (start_date, budget, preferences)     │
└────────────────┬────────────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │ Check Mock Data │ ✅ Always Available
        └─────────────────┘
                 │
                 ├─ Use It? ──────────► DONE (Fast, ~100ms)
                 │
                 └─ Need Real Data? ──┐
                                      │
                                      ▼
                        ┌──────────────────────────┐
                        │ Check if API Key exists? │
                        └──────────┬───────────────┘
                                   │
                ┌──────────────────┤
                │                  │
          YES ──▼              NO ──▼
      Call API      Fallback to Mock
      Get Real      (Still Works!)
      Data
                │                  │
                └──────────┬───────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Process Places  │
                  │ Score & Rank    │
                  │ Optimize Route  │
                  │ Return Result   │
                  └─────────────────┘
```

**Key Point:** Even without API keys, the system **works perfectly** with mock data!

---

## ✨ FEATURES WITH EACH API KEY

### With Google Places API:
- ✅ Search real places instead of mock data
- ✅ Get actual ratings and reviews
- ✅ Find places in user's actual city
- ✅ More accurate recommendations

### With Google Directions API:
- ✅ Calculate real travel distances
- ✅ Get actual travel times
- ✅ Better route optimization
- ✅ Account for real roads

### With OpenWeather API:
- ✅ Real weather predictions
- ✅ Smart filtering based on weather
- ✅ Avoid rainy beaches
- ✅ Skip adventure spots during storms

---

## 🔐 SECURITY BEST PRACTICES

### ❌ DON'T
```
- Don't commit .env file to git (already in .gitignore)
- Don't share your API keys publicly
- Don't use same key for multiple projects
- Don't keep high quota limits if not needed
```

### ✅ DO
```
- Use .env file only locally
- Rotate keys regularly
- Set spending limits on cloud console
- Use restricted keys (by referrer, IP, etc)
- Keep different keys per environment (dev, prod)
```

---

## 💰 COST ESTIMATES (As of Jan 2026)

### Google APIs
- **Places API:** $0 - $17 per 1000 requests (Free tier: $200/mo)
- **Directions API:** $0 - $5 per 1000 requests (Free tier: $200/mo)

### OpenWeather API
- **Free Tier:** Up to 1000 calls/day
- **Pro:** Starting $60/year

---

## 🧪 TESTING ALL SCENARIOS

### Test 1: Mock Data Only (Current)
```bash
# Already working!
# Open: http://127.0.0.1:8000/docs
# Use "Try it out" on /api/plan-trip
```

### Test 2: Real API Keys
```bash
# Add keys to .env
# Restart server
# Make same request
# Compare results with Test 1
```

### Test 3: Partial Keys
```bash
# Add only GOOGLE_PLACES_API_KEY
# Places are real, directions use mock
# Good for budget-conscious testing
```

---

## 📱 CONNECTING TO FLUTTER

Once API is working, connect your Flutter app:

### In Flutter (`lib/services/supabase_service.dart`):
```dart
import 'package:http/http.dart' as http;

Future<Map> planTrip({
  required String startDate,
  required String endDate,
  required int budget,
  required List<String> preferences,
  double latitude = 28.6139,
  double longitude = 77.2090,
}) async {
  const String backendUrl = 'http://127.0.0.1:8000/api/plan-trip';
  
  final response = await http.post(
    Uri.parse(backendUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'start_date': startDate,
      'end_date': endDate,
      'budget': budget,
      'preferences': preferences,
      'latitude': latitude,
      'longitude': longitude,
    }),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to plan trip');
  }
}
```

---

## 🛠️ TROUBLESHOOTING

### Problem: "API Key not working"
**Solution:**
- Check if key is correctly pasted (no extra spaces)
- Verify API is enabled in cloud console
- Check API quota hasn't exceeded
- Ensure key restrictions allow your backend URL

### Problem: "Getting mock data instead of real"
**Reasons:**
- API key not set (normal, falls back to mock) ✅
- API call failed, uses mock as fallback ✅
- Network error, uses mock ✅

### Problem: "Very slow responses"
**Reasons:**
- API is slower than mock (~200-500ms vs ~50ms)
- Too many API calls
- Rate limiting by API provider

---

## 📊 QUICK START SUMMARY

### Right Now (Mock Data):
1. ✅ Backend running at http://127.0.0.1:8000
2. ✅ API fully functional
3. ✅ No API keys needed
4. ✅ 16 sample places available

### Next Steps:
1. 📱 Connect Flutter frontend (see INTEGRATION_GUIDE.md)
2. 🔑 (Optional) Add real API keys
3. 🚀 Deploy to production

---

## 🎯 DO YOU REALLY NEED API KEYS?

| Use Case | Need Keys? |
|----------|-----------|
| Testing & Development | ❌ No |
| College Project | ❌ No |
| Showcase to Friends | ❌ No |
| Production App | ✅ Maybe |
| Real-time Weather | ✅ Yes |
| Accurate Routing | ✅ Yes |

---

## 🔗 Useful Links

- **Google Cloud Console:** https://console.cloud.google.com
- **OpenWeather API:** https://openweathermap.org/api
- **Your API Docs:** http://127.0.0.1:8000/docs
- **ReDoc Docs:** http://127.0.0.1:8000/redoc
- **Swagger Editor:** https://editor.swagger.io

---

## ✅ NEXT ACTION

**Your backend is ready to go!**

### Choose one:

**Option A: Test with Mock Data (Recommended for now)**
```
1. Open http://127.0.0.1:8000/docs
2. Click "Try it out" on the POST /api/plan-trip
3. Fill in the fields
4. See the result!
```

**Option B: Add API Keys Later**
```
1. Get API key from Google Cloud
2. Paste into .env
3. Restart server
4. Get real data instead of mock
```

**Option C: Connect Flutter Now**
```
1. See INTEGRATION_GUIDE.md
2. Copy the Dart code
3. Connect your Flutter app
4. It works immediately with mock data!
```

---

**You're all set! Backend is running with full test data.** 🎉

Any questions? Check INDEX.md for complete documentation links.
