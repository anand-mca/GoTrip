-- =====================================================
-- FAVORITES TABLE FOR GOTRIP APPLICATION
-- =====================================================
-- Run this SQL in your Supabase SQL Editor to create
-- the favorites table for storing user's favorite destinations
-- =====================================================

-- Create the favorites table
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    destination_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a user can't favorite the same destination twice
    UNIQUE(user_id, destination_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_destination_id ON public.favorites(destination_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own favorites
CREATE POLICY "Users can view own favorites" ON public.favorites
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can insert their own favorites
CREATE POLICY "Users can insert own favorites" ON public.favorites
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own favorites
CREATE POLICY "Users can delete own favorites" ON public.favorites
    FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT ALL ON public.favorites TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES (Run after creating the table)
-- =====================================================

-- Check if table was created successfully:
-- SELECT * FROM information_schema.tables WHERE table_name = 'favorites';

-- Check if RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'favorites';

-- Test insert (replace with actual user_id and destination_id):
-- INSERT INTO favorites (user_id, destination_id) VALUES ('your-user-uuid', 'destination-1');

-- Test select:
-- SELECT * FROM favorites WHERE user_id = 'your-user-uuid';
