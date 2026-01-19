-- =====================================================
-- GoTrip Destinations Table for Trip Planning Feature
-- =====================================================

-- Drop table if exists (use with caution in production)
DROP TABLE IF EXISTS destinations CASCADE;

-- Create destinations table with comprehensive attributes
CREATE TABLE destinations (
    -- Primary identification
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    
    -- Geographic information
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    
    -- Categorization
    categories TEXT[] NOT NULL DEFAULT '{}', -- ['beach', 'history', 'food', 'shopping', 'nature', 'adventure', 'religious', 'cultural']
    sub_categories TEXT[] DEFAULT '{}',      -- ['mall', 'temple', 'museum', 'waterfall', etc.]
    tags TEXT[] DEFAULT '{}',                 -- ['family_friendly', 'budget_friendly', 'luxury', 'offbeat', etc.]
    
    -- Cost and ratings
    cost_per_day INTEGER DEFAULT 1500,       -- Average cost in INR
    rating DECIMAL(2, 1) DEFAULT 4.0,        -- 0.0 to 5.0
    
    -- Visit information
    description TEXT,
    visit_duration_hours INTEGER DEFAULT 3,  -- 1-8 hours (for multi-destination planning)
    best_time_to_visit TEXT DEFAULT 'year_round', -- 'year_round', 'summer', 'winter', 'monsoon', 'oct-mar', etc.
    
    -- Media and references
    photos TEXT[] DEFAULT '{}',               -- Array of image URLs
    website_url TEXT,
    google_maps_url TEXT,
    
    -- Practical information
    opening_hours TEXT,                       -- e.g., "9:00 AM - 6:00 PM"
    entry_fee INTEGER DEFAULT 0,              -- Entry fee in INR (0 for free)
    is_active BOOLEAN DEFAULT true,           -- For soft delete/enable-disable
    
    -- Additional metadata
    nearby_attractions TEXT[] DEFAULT '{}',   -- IDs of nearby destinations
    facilities TEXT[] DEFAULT '{}',           -- ['parking', 'restroom', 'wheelchair_access', 'food_available', etc.]
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Indexes for performance optimization
-- =====================================================

-- Index for city-based queries (most common)
CREATE INDEX idx_destinations_city ON destinations(city);

-- Index for state-based queries
CREATE INDEX idx_destinations_state ON destinations(state);

-- GIN index for category array searches
CREATE INDEX idx_destinations_categories ON destinations USING GIN(categories);

-- GIN index for tags array searches
CREATE INDEX idx_destinations_tags ON destinations USING GIN(tags);

-- Index for active destinations
CREATE INDEX idx_destinations_active ON destinations(is_active) WHERE is_active = true;

-- Composite index for geographic queries
CREATE INDEX idx_destinations_location ON destinations(latitude, longitude);

-- Index for rating-based sorting
CREATE INDEX idx_destinations_rating ON destinations(rating DESC);

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;

-- Allow public read access (anyone can view destinations)
CREATE POLICY "Allow public read access" ON destinations
    FOR SELECT
    USING (is_active = true);

-- Allow authenticated users to insert (for future user-contributed destinations)
CREATE POLICY "Allow authenticated insert" ON destinations
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to update their own contributed destinations
-- (You can customize this based on your auth setup)
CREATE POLICY "Allow authenticated update" ON destinations
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- =====================================================
-- Trigger for automatic updated_at timestamp
-- =====================================================

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER update_destinations_updated_at
    BEFORE UPDATE ON destinations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Helper function for distance calculation (Haversine)
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL, lon1 DECIMAL, 
    lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    R CONSTANT DECIMAL := 6371; -- Earth's radius in kilometers
    dlat DECIMAL;
    dlon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);
    
    a := SIN(dlat/2) * SIN(dlat/2) + 
         COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * 
         SIN(dlon/2) * SIN(dlon/2);
    
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- Sample query to find destinations near a location
-- =====================================================

-- Example: Find beach destinations within 300km of Kochi
-- SELECT 
--     id, name, city, categories, rating,
--     calculate_distance(9.9312, 76.2673, latitude, longitude) as distance_km
-- FROM destinations
-- WHERE 
--     is_active = true
--     AND 'beach' = ANY(categories)
--     AND calculate_distance(9.9312, 76.2673, latitude, longitude) <= 300
-- ORDER BY distance_km, rating DESC
-- LIMIT 20;

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE destinations IS 'Curated tourism destinations for GoTrip trip planning feature';
COMMENT ON COLUMN destinations.id IS 'Unique identifier (e.g., mumbai_1, kochi_beach_5)';
COMMENT ON COLUMN destinations.categories IS 'Primary categories: beach, history, food, shopping, nature, adventure, religious, cultural';
COMMENT ON COLUMN destinations.visit_duration_hours IS 'Estimated time to spend: 1=quick stop, 3-4=half day, 6-8=full day';
COMMENT ON COLUMN destinations.cost_per_day IS 'Average cost in INR including transport, entry, food';
COMMENT ON COLUMN destinations.rating IS 'User rating from 0.0 to 5.0';

-- =====================================================
-- Grant permissions (adjust based on your Supabase setup)
-- =====================================================

-- Grant all privileges to authenticated users
GRANT ALL ON destinations TO authenticated;

-- Grant select to anonymous users (public read)
GRANT SELECT ON destinations TO anon;

-- =====================================================
-- Table created successfully!
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Verify table creation in Table Editor
-- 3. Insert data from destination_database.py or use AI to generate comprehensive dataset
-- =====================================================
