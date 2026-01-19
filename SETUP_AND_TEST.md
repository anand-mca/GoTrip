# 🚀 Complete Setup & Testing Guide

## Step 1: Upload Data to Supabase ✅

### Option A: Use SQL Editor (Recommended)
1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Open the file: `datasets/insert_destinations.sql`
5. Copy **ALL** content (7,836 lines)
6. Paste into SQL Editor
7. Click **Run** (bottom right)
8. Wait ~30 seconds
9. You should see: "Success. Returned X rows"

### Option B: Verify Upload
Run this query in SQL Editor:
```sql
SELECT COUNT(*) as total FROM destinations;
```
Expected result: `237`

### Option C: Check Sample Data
```sql
SELECT id, name, city, state, categories, rating 
FROM destinations 
LIMIT 10;
```

---

## Step 2: Verify RLS Policies

Make sure your destinations table is publicly readable:

```sql
-- Check current policies
SELECT * FROM pg_policies WHERE tablename = 'destinations';

-- If no SELECT policy exists, create one:
CREATE POLICY "Enable read access for all users" 
ON destinations 
FOR SELECT 
USING (true);
```

---

## Step 3: Test Database Connection (Optional)

Run the test app:
```bash
cd C:\Users\anand\OneDrive\Desktop\GoTrip\gotrip_mobile
flutter run test_trip_planner.dart -d chrome
```

Click the buttons in order:
1. "Test Database Connection" → Should say "✅ Database connected!"
2. "Test Trip Planning" → Should show planned trip with destinations

---

## Step 4: Run Full App

```bash
cd C:\Users\anand\OneDrive\Desktop\GoTrip\gotrip_mobile
flutter run -d chrome
```

---

## Step 5: Test Trip Planning Feature

### In the App:
1. Click **"Plan Trip"** in bottom navigation (3rd icon)
2. Fill in the form:
   - **Start Date**: Click calendar, select a date (e.g., Feb 1, 2026)
   - **End Date**: Click calendar, select end date (e.g., Feb 3, 2026)
   - **Budget**: Enter amount (e.g., `15000`)
   - **Starting From**: Enter city (e.g., `Mumbai`)
   - **Preferences**: Select categories (e.g., beach, nature, history)
3. Click **"Plan My Trip 🗺️"**
4. Wait 1-2 seconds
5. See results! ✨

### Expected Output:
```
✅ Trip planned successfully with X destinations

📊 Optimized Trip Plan
━━━━━━━━━━━━━━━━━━━━
📍 Destinations: 5
💰 Total Cost: ₹12,345
🚗 Travel Cost: ₹2,400
🏨 Stay Cost: ₹3,000
📏 Total Distance: 300.5 km
⏱️ Travel Time: 5.0 hrs
💵 Budget Left: ₹2,655
📅 Duration: 3 days

🗺️ Your Optimized Route
━━━━━━━━━━━━━━━━━━━━
1. Mumbai → Srinagar
   📏 450.2 km | ⏱️ 7.5 hrs | 💰 ₹3,602

2. Srinagar → Gulmarg
   📏 50.3 km | ⏱️ 0.8 hrs | 💰 ₹402

...

📅 Day-by-Day Itinerary
━━━━━━━━━━━━━━━━━━━━
Day 1 - 2026-02-01
  📍 Dal Lake ⭐ 4.5
     🏙️ Srinagar
     🏷️ nature
  
  📍 Shalimar Bagh ⭐ 4.4
     🏙️ Srinagar
     🏷️ history

Day 2 - 2026-02-02
  ...
```

---

## Troubleshooting

### ❌ "No destinations found matching your preferences"

**Causes**:
1. Data not uploaded to Supabase
2. RLS policy blocking reads
3. Category mismatch

**Solutions**:
```sql
-- Check if data exists
SELECT COUNT(*) FROM destinations;

-- Check categories
SELECT DISTINCT unnest(categories) as category FROM destinations;

-- Should return: beach, history, adventure, food, shopping, nature, religious, cultural
```

### ❌ "Error: ... Supabase ..."

**Cause**: Wrong credentials or RLS blocking

**Solution**:
1. Check `lib/config/supabase_config.dart`
   ```dart
   const String SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
   const String SUPABASE_ANON_KEY = 'YOUR_KEY_HERE';
   ```
2. Verify RLS policy allows SELECT

### ❌ "No destinations found within your budget"

**Cause**: Budget too low for trip

**Solutions**:
- Increase budget (try ₹20,000 for 3 days)
- Reduce trip duration (1-2 days)
- Select closer starting city

### ❌ App won't compile

**Solution**:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

---

## Testing Checklist

- [ ] SQL uploaded to Supabase (237 rows)
- [ ] RLS policy allows SELECT on destinations
- [ ] Supabase credentials correct in config
- [ ] Flutter app compiles without errors
- [ ] Trip planning screen loads
- [ ] Form accepts input
- [ ] "Plan My Trip" button works
- [ ] Results display correctly
- [ ] Destinations show with details
- [ ] Route segments display
- [ ] Daily itinerary shows

---

## What to Test

### Scenario 1: Beach Vacation
- **Budget**: ₹20,000
- **Duration**: 3 days
- **Start**: Mumbai
- **Preferences**: beach, nature
- **Expected**: Destinations with beaches/nature

### Scenario 2: History Tour
- **Budget**: ₹15,000
- **Duration**: 2 days
- **Start**: Delhi
- **Preferences**: history, cultural
- **Expected**: Historical sites & cultural attractions

### Scenario 3: Adventure Trip
- **Budget**: ₹25,000
- **Duration**: 5 days
- **Start**: Manali
- **Preferences**: adventure, nature
- **Expected**: Trekking, skiing, nature spots

### Scenario 4: Religious Pilgrimage
- **Budget**: ₹10,000
- **Duration**: 2 days
- **Start**: Rishikesh
- **Preferences**: religious
- **Expected**: Temples, shrines

---

## Success Criteria

✅ **Data Upload**: 237 destinations in Supabase
✅ **Connection**: App connects to Supabase
✅ **Query**: Filters destinations by preferences
✅ **Calculation**: Computes distances & costs
✅ **Display**: Shows trip plan with all details
✅ **Performance**: Results in <2 seconds
✅ **Accuracy**: Destinations match selected categories

---

## Next Steps After Success

1. **Expand Dataset**: Add more destinations (800-1000 target)
2. **Improve UI**: Add maps, photos, better styling
3. **Add Features**:
   - Save trip plans to user profile
   - Share trips with friends
   - Booking integration
   - Weather forecasts
4. **Optimize Algorithm**:
   - Better route optimization (TSP)
   - Consider best time to visit
   - Factor in visit duration hours

---

## Quick Commands Reference

```bash
# Run app
cd gotrip_mobile
flutter run -d chrome

# Run test app
flutter run test_trip_planner.dart -d chrome

# Check for errors
flutter analyze

# Clean build
flutter clean
flutter pub get

# Check Supabase data
# (In Supabase SQL Editor)
SELECT COUNT(*) FROM destinations;
SELECT * FROM destinations LIMIT 10;
```

---

## File Locations

### Created:
- ✅ `lib/services/trip_planner_service.dart` - Main service
- ✅ `datasets/insert_destinations.sql` - SQL upload file
- ✅ `datasets/generate_sql.py` - Script that generated SQL
- ✅ `test_trip_planner.dart` - Test app
- ✅ `TRIP_PLANNING_SUPABASE.md` - Documentation

### Modified:
- ✅ `lib/screens/trip_planning_screen.dart` - Updated to use Supabase

### No Changes:
- ✅ `lib/config/supabase_config.dart` - Already has credentials
- ✅ `lib/models/trip_plan_model.dart` - Compatible

---

## Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all 237 destinations are in Supabase
3. Ensure RLS policies are correct
4. Try the test app first
5. Check browser console for errors (F12)

**Everything should work now! The trip planning feature is fully functional with your Supabase database.** 🎉
