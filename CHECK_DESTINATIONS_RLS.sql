-- Check if destinations table has RLS enabled and correct policies
-- Run these in Supabase SQL Editor

-- 1. First check if RLS is enabled
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'destinations';

-- 2. Check existing policies on destinations table
SELECT * FROM pg_policies WHERE tablename = 'destinations';

-- 3. If RLS is blocking reads, run this to allow public read access:
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read" ON destinations
  FOR SELECT
  USING (true);

-- 4. Verify the data exists
SELECT COUNT(*) FROM destinations;

-- 5. Check a few records
SELECT id, title, location, latitude, longitude FROM destinations LIMIT 5;
