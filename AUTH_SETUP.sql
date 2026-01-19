-- COMPLETE AUTH SETUP FOR GOTRIP

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  name TEXT,
  email TEXT,
  phone TEXT,
  bio TEXT,
  profile_image TEXT,
  saved_trips TEXT[],
  booked_trips TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for profiles
-- Allow users to read their own profile
CREATE POLICY "Users can read own profile" ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to create their own profile
CREATE POLICY "Users can create own profile" ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4. Enable email authentication
-- Go to: Authentication → Providers → Email (make sure it's enabled)

-- 5. Verify destinations table has proper RLS
ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;

-- Allow public read access to destinations (no login required)
CREATE POLICY "Allow public read access" ON public.destinations
  FOR SELECT
  USING (true);

-- 6. Test queries
SELECT COUNT(*) as profile_count FROM public.profiles;
SELECT COUNT(*) as destinations_count FROM public.destinations;
