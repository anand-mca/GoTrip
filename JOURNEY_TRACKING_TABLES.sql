-- =========================================
-- GoTrip Journey Tracking Database Tables
-- =========================================
-- Run this SQL in your Supabase SQL Editor
-- These tables track user journeys and visited destinations

-- 1. User Trips Table
-- Stores the main trip information
CREATE TABLE IF NOT EXISTS user_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_name VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_city VARCHAR(100) NOT NULL,
    total_budget DECIMAL(10,2) DEFAULT 0,
    total_distance_km DECIMAL(10,2) DEFAULT 0,
    preferences TEXT[], -- Array of preferences like ['beach', 'adventure']
    status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Trip Days Table
-- Stores day-wise breakdown of the trip
CREATE TABLE IF NOT EXISTS trip_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID REFERENCES user_trips(id) ON DELETE CASCADE,
    day_number INT NOT NULL,
    date DATE,
    total_distance_km DECIMAL(10,2) DEFAULT 0,
    estimated_budget DECIMAL(10,2) DEFAULT 0,
    actual_spent DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(trip_id, day_number)
);

-- 3. Trip Destinations Table
-- Stores each destination in a trip day
CREATE TABLE IF NOT EXISTS trip_destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_day_id UUID REFERENCES trip_days(id) ON DELETE CASCADE,
    destination_id TEXT REFERENCES destinations(id) ON DELETE SET NULL, -- Reference to main destinations table (TEXT to match destinations.id type)
    destination_name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    category VARCHAR(50),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    actual_cost DECIMAL(10,2) DEFAULT 0,
    visit_order INT NOT NULL, -- Order of visit in the day
    is_visited BOOLEAN DEFAULT FALSE,
    visited_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    rating_given INT CHECK (rating_given >= 1 AND rating_given <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Destination Check-ins Table
-- Detailed check-in history for each destination
CREATE TABLE IF NOT EXISTS destination_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_destination_id UUID REFERENCES trip_destinations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    weather_data JSONB, -- Store weather data at check-in time
    photos TEXT[], -- Array of photo URLs
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Destination Recommendations Table
-- Store recommendations for restaurants, hotels, attractions near each destination
CREATE TABLE IF NOT EXISTS destination_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id TEXT REFERENCES destinations(id) ON DELETE CASCADE, -- TEXT to match destinations.id type
    recommendation_type VARCHAR(50) NOT NULL CHECK (recommendation_type IN ('restaurant', 'hotel', 'attraction', 'activity')),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    price_range VARCHAR(20), -- e.g., '$', '$$', '$$$', '$$$$'
    rating DECIMAL(2,1),
    reviews_count INT DEFAULT 0,
    contact_info JSONB, -- Store phone, email, website etc.
    operating_hours JSONB, -- Store opening hours
    photos TEXT[],
    external_id VARCHAR(100), -- ID from external API (Google Places, Zomato, etc.)
    external_source VARCHAR(50), -- Source API name
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. User Saved Recommendations Table
-- Track user's saved/bookmarked recommendations
CREATE TABLE IF NOT EXISTS user_saved_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    recommendation_id UUID REFERENCES destination_recommendations(id) ON DELETE CASCADE,
    trip_destination_id UUID REFERENCES trip_destinations(id) ON DELETE SET NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    UNIQUE(user_id, recommendation_id)
);

-- =========================================
-- Indexes for better query performance
-- =========================================
CREATE INDEX IF NOT EXISTS idx_user_trips_user_id ON user_trips(user_id);
CREATE INDEX IF NOT EXISTS idx_user_trips_status ON user_trips(status);
CREATE INDEX IF NOT EXISTS idx_trip_days_trip_id ON trip_days(trip_id);
CREATE INDEX IF NOT EXISTS idx_trip_destinations_trip_day_id ON trip_destinations(trip_day_id);
CREATE INDEX IF NOT EXISTS idx_trip_destinations_visited ON trip_destinations(is_visited);
CREATE INDEX IF NOT EXISTS idx_destination_checkins_user ON destination_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_destination_recommendations_dest ON destination_recommendations(destination_id);
CREATE INDEX IF NOT EXISTS idx_destination_recommendations_type ON destination_recommendations(recommendation_type);

-- =========================================
-- Row Level Security (RLS) Policies
-- =========================================

-- Enable RLS on all tables
ALTER TABLE user_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE destination_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_saved_recommendations ENABLE ROW LEVEL SECURITY;

-- User Trips Policies
CREATE POLICY "Users can view their own trips"
    ON user_trips FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own trips"
    ON user_trips FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trips"
    ON user_trips FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own trips"
    ON user_trips FOR DELETE
    USING (auth.uid() = user_id);

-- Trip Days Policies
CREATE POLICY "Users can view their trip days"
    ON trip_days FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM user_trips 
        WHERE user_trips.id = trip_days.trip_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can create trip days for their trips"
    ON trip_days FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM user_trips 
        WHERE user_trips.id = trip_days.trip_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can update their trip days"
    ON trip_days FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM user_trips 
        WHERE user_trips.id = trip_days.trip_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete their trip days"
    ON trip_days FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM user_trips 
        WHERE user_trips.id = trip_days.trip_id 
        AND user_trips.user_id = auth.uid()
    ));

-- Trip Destinations Policies
CREATE POLICY "Users can view their trip destinations"
    ON trip_destinations FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM trip_days 
        JOIN user_trips ON user_trips.id = trip_days.trip_id
        WHERE trip_days.id = trip_destinations.trip_day_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can create trip destinations"
    ON trip_destinations FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM trip_days 
        JOIN user_trips ON user_trips.id = trip_days.trip_id
        WHERE trip_days.id = trip_destinations.trip_day_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can update their trip destinations"
    ON trip_destinations FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM trip_days 
        JOIN user_trips ON user_trips.id = trip_days.trip_id
        WHERE trip_days.id = trip_destinations.trip_day_id 
        AND user_trips.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete their trip destinations"
    ON trip_destinations FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM trip_days 
        JOIN user_trips ON user_trips.id = trip_days.trip_id
        WHERE trip_days.id = trip_destinations.trip_day_id 
        AND user_trips.user_id = auth.uid()
    ));

-- Destination Check-ins Policies
CREATE POLICY "Users can view their own check-ins"
    ON destination_checkins FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own check-ins"
    ON destination_checkins FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Destination Recommendations - Public read access
CREATE POLICY "Anyone can view recommendations"
    ON destination_recommendations FOR SELECT
    TO authenticated
    USING (true);

-- User Saved Recommendations Policies
CREATE POLICY "Users can view their saved recommendations"
    ON user_saved_recommendations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can save recommendations"
    ON user_saved_recommendations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their saved recommendations"
    ON user_saved_recommendations FOR DELETE
    USING (auth.uid() = user_id);

-- =========================================
-- Helpful Functions
-- =========================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update trigger to relevant tables
CREATE TRIGGER update_user_trips_updated_at
    BEFORE UPDATE ON user_trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trip_days_updated_at
    BEFORE UPDATE ON trip_days
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trip_destinations_updated_at
    BEFORE UPDATE ON trip_destinations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_destination_recommendations_updated_at
    BEFORE UPDATE ON destination_recommendations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =========================================
-- Sample Queries for Reference
-- =========================================

-- Get all trips for current user
-- SELECT * FROM user_trips WHERE user_id = auth.uid() ORDER BY created_at DESC;

-- Get trip with all days and destinations
-- SELECT 
--     ut.*,
--     td.day_number,
--     td.date as day_date,
--     td.status as day_status,
--     tdest.destination_name,
--     tdest.is_visited,
--     tdest.visited_at
-- FROM user_trips ut
-- LEFT JOIN trip_days td ON td.trip_id = ut.id
-- LEFT JOIN trip_destinations tdest ON tdest.trip_day_id = td.id
-- WHERE ut.id = 'YOUR_TRIP_ID'
-- ORDER BY td.day_number, tdest.visit_order;

-- Mark a destination as visited
-- UPDATE trip_destinations 
-- SET is_visited = true, visited_at = NOW() 
-- WHERE id = 'DESTINATION_ID';

-- Get recommendations near a destination
-- SELECT * FROM destination_recommendations
-- WHERE destination_id = 'DEST_ID'
-- ORDER BY recommendation_type, rating DESC;

-- =========================================
-- End of Schema
-- =========================================
