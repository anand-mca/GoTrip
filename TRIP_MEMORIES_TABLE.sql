-- Trip Memories Table for storing user photos/snaps during their journey
-- Supabase supports image uploads via Supabase Storage!

-- Create trip_memories table
CREATE TABLE IF NOT EXISTS trip_memories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    trip_id UUID REFERENCES user_trips(id) ON DELETE CASCADE NOT NULL,
    trip_destination_id UUID REFERENCES trip_destinations(id) ON DELETE SET NULL,
    
    -- Image data
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Metadata
    caption TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_name TEXT,
    
    -- Timestamps
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Additional fields
    is_favorite BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE -- For future social sharing feature
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_trip_memories_user_id ON trip_memories(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_memories_trip_id ON trip_memories(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_memories_destination ON trip_memories(trip_destination_id);
CREATE INDEX IF NOT EXISTS idx_trip_memories_captured_at ON trip_memories(captured_at);

-- Enable Row Level Security
ALTER TABLE trip_memories ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own memories
CREATE POLICY "Users can view own memories" ON trip_memories
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own memories
CREATE POLICY "Users can insert own memories" ON trip_memories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own memories
CREATE POLICY "Users can update own memories" ON trip_memories
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own memories
CREATE POLICY "Users can delete own memories" ON trip_memories
    FOR DELETE USING (auth.uid() = user_id);

-- Optional: View public memories (for future social features)
CREATE POLICY "Anyone can view public memories" ON trip_memories
    FOR SELECT USING (is_public = TRUE);

-- =====================================================
-- SUPABASE STORAGE SETUP FOR IMAGES
-- =====================================================
-- Run this in the SQL Editor or use the Supabase Dashboard:

-- Create a storage bucket for trip memories
-- Note: You need to create this bucket via Supabase Dashboard or CLI:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Click "New bucket"
-- 3. Name it: trip-memories
-- 4. Make it public or private based on your needs
-- 5. Set up the following policies:

-- For Supabase Storage policies (run in Storage section):
-- 
-- Policy for uploads (authenticated users can upload to their own folder):
-- CREATE POLICY "Users can upload memories"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--     bucket_id = 'trip-memories' AND
--     auth.uid()::text = (storage.foldername(name))[1]
-- );
-- 
-- Policy for viewing own images:
-- CREATE POLICY "Users can view own memories"
-- ON storage.objects FOR SELECT
-- USING (
--     bucket_id = 'trip-memories' AND
--     auth.uid()::text = (storage.foldername(name))[1]
-- );
-- 
-- Policy for deleting own images:
-- CREATE POLICY "Users can delete own memories"
-- ON storage.objects FOR DELETE
-- USING (
--     bucket_id = 'trip-memories' AND
--     auth.uid()::text = (storage.foldername(name))[1]
-- );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get memory count for a trip
CREATE OR REPLACE FUNCTION get_trip_memory_count(p_trip_id UUID)
RETURNS INTEGER
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT COUNT(*)::INTEGER FROM trip_memories WHERE trip_id = p_trip_id;
$$;

-- Function to get recent memories for a user
CREATE OR REPLACE FUNCTION get_recent_memories(p_user_id UUID, p_limit INTEGER DEFAULT 10)
RETURNS SETOF trip_memories
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT * FROM trip_memories 
    WHERE user_id = p_user_id 
    ORDER BY captured_at DESC 
    LIMIT p_limit;
$$;
