-- IMPORTANT: Run this in Supabase SQL Editor to fix RLS on destinations table

-- Step 1: Disable RLS temporarily to allow all reads (you can enable it later with proper policies)
ALTER TABLE destinations DISABLE ROW LEVEL SECURITY;

-- Step 2: Verify data exists
SELECT COUNT(*) as total_destinations FROM destinations;

-- Step 3: Check a sample
SELECT 
  id, 
  title, 
  location, 
  category, 
  rating, 
  price, 
  latitude, 
  longitude 
FROM destinations 
LIMIT 3;

-- Step 3 (Alternative if you want RLS): Create public read policy
-- Uncomment these lines if you want to keep RLS enabled:
/*
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read" ON destinations;

CREATE POLICY "Allow public read" ON destinations
  FOR SELECT
  USING (true);

CREATE POLICY "Allow authenticated insert" ON destinations
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');
*/
