# Database Seeding Guide - Indian Destinations

## Overview
This guide explains how to populate your GoTrip app database with 10+ Indian tourist destinations automatically.

## What's Been Created

### 1. **Seed Data (10 Indian Destinations)**
Located in: `/assets/data/indian_destinations.json`

Includes destinations like:
- Taj Mahal, Agra
- Kerala Backwaters
- Goa Beaches
- Himalayan Treks
- Jaipur City Palace
- Varanasi Ghats
- Udaipur Lakes
- Munnar Tea Plantations
- Andaman Islands
- Manali

Each destination includes:
- Title, location, description
- High-quality images (Unsplash URLs)
- Ratings and reviews count
- Price and duration
- Difficulty level (easy/medium/hard)
- Highlights and amenities
- Group size capacity

### 2. **Seed Function**
Location: `lib/services/supabase_service.dart`
Method: `seedIndianDestinations()`

This function inserts all 10 destinations into your Supabase `trips` table.

### 3. **Updated Screens**
- **HomeScreen**: Now displays real trips from Supabase instead of mock data
- **TripProvider**: Already configured to fetch from database

---

## How to Seed Your Database

### **Step 1: Create a Test Button in Home Screen** (Temporary)

Add a button to run the seed function. You can later remove this.

In `lib/screens/home_screen.dart`, add this button to the AppBar:

```dart
AppBar(
  title: const Text('GoTrip'),
  actions: [
    TextButton(
      onPressed: () async {
        final supabaseService = SupabaseService();
        try {
          await supabaseService.seedIndianDestinations();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destinations seeded successfully!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      },
      child: const Text('Seed Data'),
    ),
  ],
)
```

### **Step 2: Run the App**

```bash
cd c:\Users\anand\OneDrive\Desktop\GoTrip\gotrip_mobile
flutter run -d chrome
```

### **Step 3: Click "Seed Data" Button**

1. Launch the app on Chrome
2. After login, tap the "Seed Data" button in the top-right
3. Wait for the snackbar: "Destinations seeded successfully!"

### **Step 4: Verify in Supabase**

1. Go to: https://app.supabase.com → GoTrip project
2. Click **Table Editor** → select **trips** table
3. You should see all 10 destinations with their data!

### **Step 5: Check the Home Screen**

Refresh the Home page and you should now see real Indian destinations instead of mock data!

---

## Verify Data in Supabase

Run this SQL query to verify:

```sql
SELECT id, title, location, rating, price FROM trips ORDER BY created_at DESC;
```

You should see output like:
```
Taj Mahal            | Agra, Uttar Pradesh        | 4.9 | 250
Kerala Backwaters    | Kochi, Kerala              | 4.8 | 3500
Goa Beaches          | Goa                        | 4.7 | 2000
...
```

---

## Manual Seeding (Alternative)

If you want to seed without clicking a button, create a separate script:

1. Create a new file: `lib/scripts/seed_data.dart`
2. Copy the `seedIndianDestinations()` logic
3. Run it from `main.dart` during initialization (only once)

---

## Adding More Destinations

To add more Indian destinations:

1. Edit `assets/data/indian_destinations.json`
2. Add a new entry with the same structure
3. Re-run the seed function

Or manually insert in Supabase:

```sql
INSERT INTO trips (title, location, description, image, rating, reviews, price, duration, difficulty, highlights, amenities, groupSize, category, created_by, created_at)
VALUES (
  'Your Destination',
  'Location, State',
  'Description here',
  'Image URL',
  4.5,
  100,
  1500,
  '3 days',
  'easy',
  'Highlight1, Highlight2',
  'Amenity1, Amenity2',
  30,
  'Category',
  'admin',
  NOW()
);
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Button doesn't appear | Check HomeScreen AppBar code was added correctly |
| Seeding fails with RLS error | Run the RLS fix SQL from SUPABASE_SETUP.md |
| Trips don't show on home | Refresh page, check TripProvider is loading |
| Destinations not in Supabase | Check browser console for error messages |

---

## Next Steps

Once seeding is complete:

1. ✅ Home screen shows real Indian destinations
2. ✅ Explore screen can search these destinations
3. ✅ Users can view trip details and book
4. ✅ Add more destinations as needed

Remove the "Seed Data" button after initial setup.
