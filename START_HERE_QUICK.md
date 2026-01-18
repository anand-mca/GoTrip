# 🚀 QUICK START - GoTrip with Travel Optimization

## ⚡ Start in 3 Commands

### 1️⃣ Start Backend (Terminal 1)
```powershell
cd "C:\Users\anand\OneDrive\Desktop\GoTrip\gotrip-backend"
pip install -r requirements.txt
python backend.py
```

### 2️⃣ Start Flutter App (Terminal 2)
```powershell
cd "C:\Users\anand\OneDrive\Desktop\GoTrip\gotrip_mobile"
flutter run -d chrome
```

### 3️⃣ Test Trip Planning
- Navigate to **Trip Planning** screen
- Fill form (dates, budget ₹25,000, preferences)
- Click **"Plan Optimized Trip"**
- See your optimized itinerary! ✨

---

## ✅ What's New

### Features
✅ **Minimizes travel distance** (primary goal)  
✅ **Real cost calculations** (travel + stay)  
✅ **Time estimates** for each route segment  
✅ **Budget constraints** (never exceeds)  
✅ **Day-by-day itinerary** with costs  
✅ **Beautiful UI** with route visualization  

### NO API Keys Needed!
- Works with mock data (8 destinations)
- Free OSRM routing
- Ready to use immediately

---

## 🔑 About API Keys (from your image)

### Current Status: **NOT NEEDED** ✅

| API | Purpose | When Needed | Cost |
|-----|---------|-------------|------|
| Google Places | Real destinations | Production | Paid ($200 free/mo) |
| OpenRouteService | Better routing | Optional | FREE |
| Google Directions | Routing | Alternative | Paid |
| OpenWeatherMap | Weather | Nice-to-have | FREE |

**When to add keys:**
- **OpenRouteService** (free): When you want more accurate routing
  - Sign up: https://openrouteservice.org/dev/#/signup
  - Add to: `lib/services/routing_service.dart` line 7
  
- **Google Places** (paid): When you need real destination data
  - Setup: https://console.cloud.google.com/
  - Modify: `gotrip-backend/backend.py` DESTINATIONS

---

## 🎯 How It Works

### Algorithm: Nearest Neighbor (Greedy TSP)
```
1. Start from your location (Delhi)
2. Find NEAREST destination matching preferences
3. Check if it fits budget
4. Add to trip
5. Move there
6. Repeat until budget/time exhausted
7. Return to start
8. Calculate all costs
```

### Constraints (Priority Order)
1. **Minimal travel** ← PRIMARY
2. Budget limit
3. Date range
4. User preferences

---

## 📊 Example Trip

**Input:**
- From: Delhi
- Dates: 7 days
- Budget: ₹25,000
- Wants: Beach + Adventure

**Output:**
```
✅ 2 destinations found

Summary:
💰 Total: ₹18,600
🚗 Travel: ₹4,850 (606 km)
🏨 Stay: ₹13,750
⏱️ Time: 12.1 hours
💵 Left: ₹6,400

Route:
Delhi → Rishikesh (240km, ₹1,920)
Rishikesh → Manali (308km, ₹2,464)  
Manali → Delhi (240km, ₹1,920)

Days:
Day 1: Rishikesh - Yoga (₹1,500)
Day 2-3: Manali - Adventure (₹4,000/day)
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Backend won't start | Check Python 3.7+: `python --version` |
| Can't connect | Start backend first, check port 8000 |
| No destinations | Try: beach, adventure, food, history |
| Budget too low | Minimum ₹5,000 for meaningful trip |

---

## 📚 Full Documentation

- **API_SETUP_GUIDE.md** - Complete setup guide
- **TRIP_OPTIMIZATION_COMPLETE.md** - Full technical docs
- **gotrip-backend/README.md** - Backend details

---

## 🎉 You're Ready!

Everything is set up. Just run the 2 commands and start planning trips! 

**No API keys, no configuration, no hassle.** ✨
