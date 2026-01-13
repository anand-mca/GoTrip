# Supabase Setup Guide for GoTrip

This guide will help you set up Supabase as the backend for the GoTrip Flutter application.

## Step 1: Create a Supabase Account

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project" or sign in if you have an account
3. Sign up with GitHub, Google, or email
4. Create a new organization (if needed)

## Step 2: Create a New Project

1. Click "New Project"
2. Enter project name: `gotrip`
3. Create a strong database password (you'll need this)
4. Select your region (closest to your users)
5. Click "Create new project" and wait for it to initialize

## Step 3: Get Your Credentials

1. Go to Settings → API (or Project Settings → API)
2. Find the following under "Project URL" and "API Keys":
   - **Project URL**: `https://YOUR_PROJECT_ID.supabase.co`
   - **Anon/Public Key**: Under "anon public"
   - **Service Role Key**: Under "service_role" (keep this secret!)

3. Copy these credentials and update `lib/config/supabase_config.dart`:

```dart
const String SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const String SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

## Step 4: Set Up Database Tables

1. Go to the SQL Editor in Supabase
2. Run the following SQL script to create all necessary tables:

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

-- Create indexes for better performance
CREATE INDEX idx_trips_location ON trips(location);
CREATE INDEX idx_trips_difficulty ON trips(difficulty);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_trip_id ON bookings(trip_id);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_trip_id ON favorites(trip_id);
```

3. Click "Run" to execute the script

## Step 5: Set Up Storage Buckets

1. Go to Storage in Supabase
2. Create two new public buckets:
   - **trips**: For trip images
   - **avatars**: For user profile pictures

3. For each bucket:
   - Click "Create Bucket"
   - Make it public
   - Click Create

## Step 6: Set Up Authentication

1. Go to Authentication → Users
2. Enable Email/Password authentication (should be enabled by default)
3. Go to Authentication → Policies
4. Configure Row Level Security (RLS) for tables:

### Enable RLS on all tables:

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read their own profile, update their own profile
CREATE POLICY "Users can read own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Trips: Anyone can read, only authenticated users can create
CREATE POLICY "Anyone can read trips" ON trips
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create trips" ON trips
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Bookings: Users can read own bookings
CREATE POLICY "Users can read own bookings" ON bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Favorites: Users can read, insert, and delete own favorites
CREATE POLICY "Users can read own favorites" ON favorites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites" ON favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON favorites
  FOR DELETE USING (auth.uid() = user_id);
```

## Step 7: Add Sample Data

1. Go to the SQL Editor
2. Run this SQL to add sample trips:

```sql
INSERT INTO trips (title, description, image, location, rating, reviews, price, duration, difficulty, highlights, amenities, group_size) VALUES
('Swiss Alps Adventure', 'Experience the majestic Swiss Alps with guided mountain tours', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop', 'Switzerland', 4.8, 234, 1299.99, 7, 'Moderate', ARRAY['Mountain Tours', 'Cable Cars', 'Alpine Lakes', 'Traditional Villages'], ARRAY['Hotel', 'Meals', 'Guide', 'Transportation'], 12),
('Tropical Paradise', 'Relax on pristine beaches and explore tropical wildlife', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop', 'Maldives', 4.9, 567, 1899.99, 5, 'Easy', ARRAY['Beach', 'Snorkeling', 'Water Sports', 'Sunset Cruise'], ARRAY['Resort', 'All Meals', 'Activities', 'Transfers'], 20),
('Ancient Wonders', 'Explore historical sites and ancient pyramids', 'https://images.unsplash.com/photo-1499856871957-5b8620a56b38?w=500&h=400&fit=crop', 'Egypt', 4.7, 345, 999.99, 6, 'Easy', ARRAY['Pyramids', 'Nile Cruise', 'Museums', 'Local Culture'], ARRAY['Hotel', 'Breakfast', 'Guide', 'Entrance Fees'], 15),
('Amazon Rainforest', 'Wildlife expedition through the Amazon', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=500&h=400&fit=crop', 'Brazil', 4.6, 289, 2499.99, 10, 'Hard', ARRAY['Jungle Trek', 'Wildlife Watching', 'River Expedition', 'Indigenous Culture'], ARRAY['Lodge', 'All Meals', 'Expert Guide', 'Equipment'], 8),
('Tokyo Modern', 'Blend of tradition and technology in Japan', 'https://images.unsplash.com/photo-1540959375944-7049f642e9f1?w=500&h=400&fit=crop', 'Japan', 4.8, 456, 1499.99, 7, 'Easy', ARRAY['City Tour', 'Temple Visit', 'Street Food', 'Tech Districts'], ARRAY['Hotel', 'Breakfast', 'Guide', 'Public Transport Pass'], 18);
```

## Step 8: Update Your App

1. Open `lib/config/supabase_config.dart`
2. Replace `YOUR_PROJECT_ID` and `YOUR_ANON_KEY` with your actual credentials
3. Run `flutter pub get` to install dependencies
4. Run your app with `flutter run`

## Step 9: Test the Backend

1. Try signing up with a test email
2. Check the Supabase Authentication panel to see the new user
3. Verify that trips are loading from the database

## Free Tier Limits

**Supabase Free Tier Includes:**
- Unlimited projects: 1 free project per day
- 500 MB database storage
- 1 GB file storage (perfect for trip images)
- 5 GB bandwidth per month
- Up to 50k REST API requests per month
- Real-time subscriptions

**Great for:**
- Development and testing
- MVP/Proof of concepts
- Small production apps

## Troubleshooting

### "Supabase initialization error"
- Check that SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Make sure quotes are straight, not curly quotes
- Verify the project is running on Supabase dashboard

### "Authentication failed"
- Make sure email/password auth is enabled
- Check user exists in Supabase Auth → Users
- Verify RLS policies are correct

### "Cannot upload image"
- Verify storage buckets exist (trips and avatars)
- Check they are set as public
- Ensure permissions allow uploads

### "Database connection timeout"
- Check your internet connection
- Verify Supabase project status is running
- Try in a different network

## Next Steps

1. Customize the database schema for your specific needs
2. Add more triggers and functions in Supabase
3. Set up custom authentication flows
4. Implement real-time features using Supabase subscriptions
5. Add backup strategies

For more help, visit: [https://supabase.com/docs](https://supabase.com/docs)
