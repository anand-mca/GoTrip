# GoTrip Backend Setup - Quick Start Guide

## Overview
This app uses **Supabase** as the backend with:
- PostgreSQL Database for storing trips, bookings, and user data
- Authentication (Email/Password)
- Storage for trip images and user avatars
- Real-time capabilities

## What's Already Set Up in Your Code

✅ **Supabase Integration**
- `lib/services/supabase_service.dart` - Core service for all database operations
- `lib/providers/auth_provider.dart` - Authentication state management
- `lib/providers/trip_provider.dart` - Trip data management
- `lib/models/trip_model.dart` - Trip data model
- `lib/models/user_model.dart` - User data model
- `lib/config/supabase_config.dart` - Configuration file (needs credentials)

✅ **Features Ready to Use**
- User authentication (signup, login, logout)
- Trip management (CRUD operations)
- Image upload support
- Favorites/bookmarks system
- Search and filter functionality
- Booking system

## Quick Setup Instructions

### 1. Create Supabase Project (2 minutes)
```
1. Go to https://supabase.com
2. Click "Start your project"
3. Sign up with GitHub/Google/Email
4. Click "New Project"
5. Enter name: "gotrip"
6. Set password (important!)
7. Select region
8. Click "Create new project"
9. Wait for project to initialize
```

### 2. Get Your Credentials (1 minute)
```
1. Go to Settings → API
2. Copy "Project URL" (looks like: https://xxxxx.supabase.co)
3. Copy "anon public" key from "API Keys"
```

### 3. Add Credentials to Your App (1 minute)
```
Edit: lib/config/supabase_config.dart

Replace:
- SUPABASE_URL with your Project URL
- SUPABASE_ANON_KEY with your anon public key
```

### 4. Set Up Database (3 minutes)
```
1. In Supabase, go to "SQL Editor"
2. Click "New Query"
3. Copy the SQL from the "SQL SCRIPT" section below
4. Paste it in the editor
5. Click "Run"
6. Wait for success message
```

### 5. Create Storage Buckets (2 minutes)
```
1. Go to "Storage" in Supabase
2. Click "Create a new bucket"
3. Name it "trips" and make it public
4. Repeat for "avatars" bucket
```

### 6. Run Your App (1 minute)
```bash
flutter pub get
flutter run
```

---

## SQL SCRIPT

Copy and paste this entire script into Supabase SQL Editor:

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  bio text,
  profile_image text,
  saved_trips text[] DEFAULT '{}',
  booked_trips text[] DEFAULT '{}',
  created_at timestamp with time zone DEFAULT current_timestamp,
  updated_at timestamp with time zone DEFAULT current_timestamp
);

-- Create trips table
CREATE TABLE IF NOT EXISTS trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  image text NOT NULL,
  location text NOT NULL,
  rating float8 DEFAULT 0,
  reviews integer DEFAULT 0,
  price float8 NOT NULL,
  duration integer NOT NULL,
  difficulty text DEFAULT 'Easy',
  highlights text[] DEFAULT '{}',
  amenities text[] DEFAULT '{}',
  group_size integer DEFAULT 0,
  created_by uuid REFERENCES profiles(id),
  created_at timestamp with time zone DEFAULT current_timestamp,
  updated_at timestamp with time zone DEFAULT current_timestamp
);

-- Create bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  status text DEFAULT 'pending',
  booking_date timestamp with time zone NOT NULL,
  number_of_people integer NOT NULL,
  total_price float8 NOT NULL,
  special_requests text,
  created_at timestamp with time zone DEFAULT current_timestamp,
  updated_at timestamp with time zone DEFAULT current_timestamp
);

-- Create favorites table
CREATE TABLE IF NOT EXISTS favorites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  created_at timestamp with time zone DEFAULT current_timestamp,
  UNIQUE(user_id, trip_id)
);

-- Create indexes
CREATE INDEX idx_trips_location ON trips(location);
CREATE INDEX idx_trips_difficulty ON trips(difficulty);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_trip_id ON bookings(trip_id);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_trip_id ON favorites(trip_id);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- RLS Policies for trips
CREATE POLICY "Anyone can read trips" ON trips
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create trips" ON trips
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for bookings
CREATE POLICY "Users can read own bookings" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for favorites
CREATE POLICY "Users can read own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);

-- Insert sample trips
INSERT INTO trips (title, description, image, location, rating, reviews, price, duration, difficulty, highlights, amenities, group_size) VALUES
('Swiss Alps Adventure', 'Experience the majestic Swiss Alps with guided mountain tours', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop', 'Switzerland', 4.8, 234, 1299.99, 7, 'Moderate', ARRAY['Mountain Tours', 'Cable Cars', 'Alpine Lakes', 'Traditional Villages'], ARRAY['Hotel', 'Meals', 'Guide', 'Transportation'], 12),
('Tropical Paradise', 'Relax on pristine beaches and explore tropical wildlife', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop', 'Maldives', 4.9, 567, 1899.99, 5, 'Easy', ARRAY['Beach', 'Snorkeling', 'Water Sports', 'Sunset Cruise'], ARRAY['Resort', 'All Meals', 'Activities', 'Transfers'], 20),
('Ancient Wonders', 'Explore historical sites and ancient pyramids', 'https://images.unsplash.com/photo-1499856871957-5b8620a56b38?w=500&h=400&fit=crop', 'Egypt', 4.7, 345, 999.99, 6, 'Easy', ARRAY['Pyramids', 'Nile Cruise', 'Museums', 'Local Culture'], ARRAY['Hotel', 'Breakfast', 'Guide', 'Entrance Fees'], 15),
('Amazon Rainforest', 'Wildlife expedition through the Amazon', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=500&h=400&fit=crop', 'Brazil', 4.6, 289, 2499.99, 10, 'Hard', ARRAY['Jungle Trek', 'Wildlife Watching', 'River Expedition', 'Indigenous Culture'], ARRAY['Lodge', 'All Meals', 'Expert Guide', 'Equipment'], 8),
('Tokyo Modern', 'Blend of tradition and technology in Japan', 'https://images.unsplash.com/photo-1540959375944-7049f642e9f1?w=500&h=400&fit=crop', 'Japan', 4.8, 456, 1499.99, 7, 'Easy', ARRAY['City Tour', 'Temple Visit', 'Street Food', 'Tech Districts'], ARRAY['Hotel', 'Breakfast', 'Guide', 'Public Transport Pass'], 18);
```

---

## Testing Your Setup

After setup, test these features in your app:

1. **Signup**: Create new account with email/password
2. **Login**: Login with your credentials
3. **View Trips**: Should see 5 sample trips
4. **Search**: Search for trips by location
5. **Save Favorite**: Click heart to save trips
6. **Logout**: Click logout in profile

---

## File Structure

```
lib/
├── config/
│   └── supabase_config.dart          ← Add your credentials here
├── services/
│   └── supabase_service.dart         ← Core backend service
├── providers/
│   ├── auth_provider.dart            ← Auth state management
│   └── trip_provider.dart            ← Trip state management
├── models/
│   ├── trip_model.dart               ← Trip data model
│   └── user_model.dart               ← User data model
├── screens/
│   ├── login_screen.dart             ← Update to use auth_provider
│   ├── signup_screen.dart            ← Update to use auth_provider
│   ├── home_screen.dart              ← Update to use trip_provider
│   └── ... (other screens)
└── main.dart                         ← Already configured for Supabase
```

---

## Common Issues & Solutions

### Issue: "Supabase initialization error"
**Solution**: 
- Check SUPABASE_URL and SUPABASE_ANON_KEY in supabase_config.dart
- Make sure URL starts with "https://"
- Verify the project is running in Supabase dashboard

### Issue: "Authentication failed" when logging in
**Solution**:
- Verify user exists in Supabase Auth → Users
- Check email is exactly correct (case-sensitive)
- Ensure email/password auth is enabled in Authentication settings

### Issue: "Cannot upload image"
**Solution**:
- Verify "trips" and "avatars" buckets exist in Storage
- Check buckets are set to "Public"
- Make sure you have write permissions

### Issue: "No trips showing"
**Solution**:
- Check if SQL script ran successfully
- Go to SQL Editor → Execute the SELECT query
- Verify 5 sample trips appear in results

---

## Next Steps

1. ✅ Complete the setup above
2. Update login/signup screens to use `AuthProvider`
3. Update home/explore screens to use `TripProvider`
4. Add image upload functionality using `supabase_service.uploadImage()`
5. Test booking functionality
6. Deploy to production

---

## Supabase Free Tier

**Includes:**
- 500 MB database storage
- 1 GB file storage (great for images!)
- 5 GB bandwidth/month
- Up to 50,000 API requests/month

**Perfect for:**
- Development & testing
- MVP/Proof of concept
- Small production apps

---

## Useful Links

- Supabase Docs: https://supabase.com/docs
- SQL Tutorial: https://www.postgresql.org/docs/current/tutorial.html
- Flutter Supabase: https://supabase.com/docs/reference/dart/introduction
- Project Dashboard: https://app.supabase.com

---

**Total Setup Time: ~15 minutes**

Need help? Check the SUPABASE_SETUP.md file for detailed instructions.
