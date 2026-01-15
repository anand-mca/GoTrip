-- COPY AND RUN THIS IN SUPABASE SQL EDITOR RIGHT NOW

-- Step 1: Disable RLS on destinations table so everyone can read
ALTER TABLE destinations DISABLE ROW LEVEL SECURITY;

-- Step 2: Verify data is there
SELECT COUNT(*) as total_destinations FROM destinations;

-- Step 3: Check sample records
SELECT id, title, location, category, rating, latitude, longitude FROM destinations LIMIT 3;
