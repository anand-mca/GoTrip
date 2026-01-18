# Quick Reference Card

## 🎯 3-Step Implementation

### STEP 1️⃣: BACKEND (Pick One)
```bash
# Node.js
mkdir gotrip-backend && cd gotrip-backend
npm init -y
npm install express cors dotenv axios
# Copy: BACKEND_SETUP_QUICK_START.md > Option 1
npm run dev

# Python  
python -m venv venv && venv\Scripts\activate
pip install fastapi uvicorn
# Copy: BACKEND_SETUP_QUICK_START.md > Option 2
python main.py
```

### STEP 2️⃣: FLUTTER
1. Open `lib/screens/trip_planning_screen.dart`
2. Replace `_planTrip()` method (see IMPLEMENTATION_GUIDE.md)
3. Add imports from IMPLEMENTATION_GUIDE.md
4. Add state variable: `String? error;`

### STEP 3️⃣: TEST
```bash
# Terminal 1: Backend running ✅
# Terminal 2: Flutter app
flutter run -d chrome
# 💻 Browser: Plan a trip → See recommendations ✅
```

---

## 📁 File Map

```
gotrip_mobile/
├── lib/services/api_service.dart          ← API calls
├── lib/providers/destination_api_provider.dart  ← State
├── lib/screens/trip_planning_screen.dart  ← Update _planTrip()
├── lib/main.dart                          ← Provider added
│
├── 📖 START_API_INTEGRATION.md            ← 👈 START HERE
├── 📖 BACKEND_SETUP_QUICK_START.md        ← Backend code
├── 📖 IMPLEMENTATION_GUIDE.md             ← Code changes
├── 📖 API_ARCHITECTURE.md                 ← How it works
├── 📖 SETUP_CHECKLIST.md                  ← Verify setup
├── 📖 API_INTEGRATION_GUIDE.md            ← Full reference
├── 📖 STATUS_REPORT.md                    ← What's done
└── 📖 THIS_FILE                           ← You are here
```

---

## 🔌 API Endpoints

| Endpoint | Method | What It Does |
|----------|--------|--------------|
| `/health` | GET | Check if backend alive |
| `/destinations/recommendations` | POST | Get trip suggestions |
| `/destinations/search` | GET | Search destinations |
| `/hotels` | GET | Find hotels |
| `/activities/search` | POST | Find activities |

---

## 🧪 Test Commands

```bash
# Is backend running?
curl http://localhost:8000/api/health

# Get recommendations
curl -X POST http://localhost:8000/api/destinations/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "preferences":["beach","adventure"],
    "max_budget":15000,
    "days":5,
    "location":"Delhi"
  }'
```

---

## ⚠️ Common Issues & Fixes

| Error | Fix |
|-------|-----|
| "Could not reach backend" | `npm run dev` running? Check port 8000 |
| "Connection refused" | Backend crashed. Restart with `npm run dev` |
| "No destinations" | Try budget >= 8000, preferences = beach/food/nature |
| CORS error | Backend has CORS enabled (it does) |
| App crashes | Check Flutter console. Run `flutter clean` |

---

## ✅ Success Checklist

```
Backend Ready:
☐ npm run dev OR python main.py running
☐ http://localhost:8000/api/health returns success
☐ Port 8000 shows no errors

Flutter Updated:
☐ Imports added to trip_planning_screen.dart
☐ _planTrip() method updated
☐ String? error; added to state
☐ main.dart has DestinationAPIProvider

Testing:
☐ Flutter app loads: flutter run -d chrome
☐ Plan Trip screen opens
☐ Form accepts input
☐ Clicking "Plan My Trip" shows spinner
☐ Recommendations appear in 2-3 seconds
☐ Cards show name, cost, rating, distance
☐ No errors in console
```

---

## 📊 Architecture at a Glance

```
USER FILLS FORM
    ↓
FLUTTER CALLS API
    ↓
BACKEND PROCESSES
    ↓
RETURNS RECOMMENDATIONS
    ↓
FLUTTER DISPLAYS RESULTS
```

---

## 🔑 Key Variables in API Response

```json
{
  "id": "beach1",              ← Unique ID
  "name": "Goa Beach",         ← Display name
  "category": "beach",         ← Type of place
  "cost": 8000,                ← Price in ₹
  "days": 3,                   ← How many days
  "distance": 1800,            ← KM from Delhi
  "rating": 4.5,               ← Star rating
  "reviews": 2345,             ← Review count
  "description": "Beautiful"   ← Details
}
```

---

## 🛠️ Tools Needed

- ✅ Node.js + npm (if Node backend)
- ✅ Python 3 (if Python backend)
- ✅ Flutter
- ✅ Chrome browser
- ✅ Text editor (VS Code)

---

## 📞 Support Matrix

| Question | Answer | File |
|----------|--------|------|
| How to start? | Read 3-step guide above | START_API_INTEGRATION.md |
| Backend not running? | Check port, restart, read errors | BACKEND_SETUP_QUICK_START.md |
| Flutter code changes? | Copy method from guide | IMPLEMENTATION_GUIDE.md |
| How does it work? | See architecture & diagrams | API_ARCHITECTURE.md |
| All failing? | Follow checklist step by step | SETUP_CHECKLIST.md |
| Need reference? | See all endpoints & formats | API_INTEGRATION_GUIDE.md |

---

## ⏱️ Time Budget

| Task | Time |
|------|------|
| Read docs | 20 min |
| Create backend | 30 min |
| Update Flutter | 15 min |
| Test & debug | 30 min |
| **Total** | **~2 hours** |

---

## 🎓 Understand This First

**API** = Program that provides data  
**Backend** = Server that runs API  
**Endpoint** = Specific API feature  
**Request** = Frontend asks backend  
**Response** = Backend answers frontend  
**Mock Data** = Fake data for testing  
**Provider** = Flutter state management  

---

## 🚀 After It Works

1. **Optimize**: Add caching, reduce API calls
2. **Enhance**: Use real APIs (Google Places, Amadeus)
3. **Scale**: Deploy backend to cloud
4. **Monitor**: Track usage & errors
5. **Improve**: Add more features based on data

---

## 💾 Commands You'll Use

```bash
# Backend
npm init -y
npm install express cors
npm run dev

# Flutter
flutter pub add http
flutter run -d chrome
flutter clean
flutter pub get

# Testing
curl http://localhost:8000/api/health
```

---

## 🎯 Expected Output

### When Backend Starts:
```
✅ Backend running on http://localhost:8000
```

### When Health Check Works:
```
{"status":"Backend is running!"}
```

### When Flutter Gets Recommendations:
```
Found 5 destinations matching criteria
├─ Goa Beach (₹8,000, ⭐4.5)
├─ Himalayas (₹12,000, ⭐4.7)
└─ ... (3 more)
```

---

## 📝 Coding Pattern Used

```dart
// How API calls work in this project:
1. User fills form
2. Validate input
3. Get provider: context.read<DestinationAPIProvider>()
4. Call method: provider.fetchRecommendedDestinations()
5. Wait for result
6. Update UI with results
7. Handle errors gracefully
```

---

## 🏁 Finish Line

When you see this, you're done:
✅ Trip form filled  
✅ "Plan My Trip" clicked  
✅ Loading spinner shown  
✅ 2-3 seconds pass  
✅ **Recommendations appear!** 🎉  

---

## 📚 Documentation Hierarchy

**Read in this order:**
1. This file (quick overview)
2. START_API_INTEGRATION.md (full guide)
3. BACKEND_SETUP_QUICK_START.md (backend code)
4. IMPLEMENTATION_GUIDE.md (Flutter changes)
5. Others as needed for reference

---

**Status**: ✅ Ready  
**Your next action**: Open `START_API_INTEGRATION.md`  
**Difficulty**: Easy (templates provided)  
**Time to complete**: 2-3 hours  

Good luck! 🚀

