-- ============================================================
-- WASTELESS DATABASE CLEANUP AND SETUP (SIMPLE VERSION)
-- ============================================================
-- This script will clean up existing tables and recreate them properly
-- Run this in your Supabase SQL Editor

-- ============================================================
-- STEP 1: DROP ALL EXISTING TABLES WITH CASCADE
-- ============================================================

-- This will automatically drop all policies, indexes, and dependencies
DROP TABLE IF EXISTS donation_claims CASCADE;
DROP TABLE IF EXISTS donations CASCADE;
DROP TABLE IF EXISTS inventory_items CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================
-- STEP 2: DROP EXISTING FUNCTIONS AND TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- ============================================================
-- STEP 3: CREATE TABLES WITH CORRECT SCHEMA
-- ============================================================

-- Create profiles table
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('restaurant', 'ngo')),
    location TEXT NOT NULL,
    phone_number TEXT, -- Optional phone number
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create inventory_items table (with category column)
CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    quantity TEXT NOT NULL, -- e.g., "5 kg", "10 loaves", "30 units"
    category TEXT NOT NULL DEFAULT 'Other', -- e.g., "Fruits", "Vegetables", "Dairy"
    expiry_date DATE NOT NULL,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'donated', 'wasted')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create donations table
CREATE TABLE donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    quantity TEXT NOT NULL,
    expiry_date DATE NOT NULL,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'claimed', 'completed', 'cancelled')),
    posted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    claimed_by UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NGO who claimed it
    claimed_at TIMESTAMP WITH TIME ZONE,
    claim_message TEXT,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create donation_claims table
CREATE TABLE donation_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID REFERENCES donations(id) ON DELETE CASCADE NOT NULL,
    ngo_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    claim_message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    claimed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    UNIQUE (donation_id, ngo_id) -- An NGO can only claim a specific donation once
);

-- ============================================================
-- STEP 4: ENABLE ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE donation_claims ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 5: CREATE POLICIES
-- ============================================================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Inventory items policies
CREATE POLICY "Restaurants can view own inventory" ON inventory_items
    FOR SELECT USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can insert own inventory" ON inventory_items
    FOR INSERT WITH CHECK (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can update own inventory" ON inventory_items
    FOR UPDATE USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can delete own inventory" ON inventory_items
    FOR DELETE USING (auth.uid() = restaurant_id);

-- Donations policies
CREATE POLICY "Authenticated users can view donations" ON donations
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Restaurants can insert own donations" ON donations
    FOR INSERT WITH CHECK (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can update own donations" ON donations
    FOR UPDATE USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can delete own donations" ON donations
    FOR DELETE USING (auth.uid() = restaurant_id);

-- Donation claims policies
CREATE POLICY "NGOs can view own claims" ON donation_claims
    FOR SELECT USING (auth.uid() = ngo_id);

CREATE POLICY "NGOs can insert own claims" ON donation_claims
    FOR INSERT WITH CHECK (auth.uid() = ngo_id);

CREATE POLICY "NGOs can update own claims" ON donation_claims
    FOR UPDATE USING (auth.uid() = ngo_id);

CREATE POLICY "Restaurants can view claims for their donations" ON donation_claims
    FOR SELECT USING (EXISTS (SELECT 1 FROM donations WHERE donations.id = donation_id AND donations.restaurant_id = auth.uid()));

CREATE POLICY "Restaurants can update claims for their donations" ON donation_claims
    FOR UPDATE USING (EXISTS (SELECT 1 FROM donations WHERE donations.id = donation_id AND donations.restaurant_id = auth.uid()));

-- ============================================================
-- STEP 6: CREATE INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX profiles_role_idx ON profiles(role);
CREATE INDEX profiles_location_idx ON profiles(location);
CREATE INDEX profiles_created_at_idx ON profiles(created_at);
CREATE INDEX inventory_items_restaurant_id_idx ON inventory_items(restaurant_id);
CREATE INDEX inventory_items_expiry_date_idx ON inventory_items(expiry_date);
CREATE INDEX donations_restaurant_id_idx ON donations(restaurant_id);
CREATE INDEX donations_status_idx ON donations(status);
CREATE INDEX donation_claims_ngo_id_idx ON donation_claims(ngo_id);
CREATE INDEX donation_claims_donation_id_idx ON donation_claims(donation_id);

-- ============================================================
-- STEP 7: CREATE HELPER FUNCTIONS
-- ============================================================

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Profile creation is handled in the Flutter app
    -- This function can be used for additional logic if needed
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- STEP 8: VERIFICATION
-- ============================================================

-- Display table information
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'inventory_items', 'donations', 'donation_claims')
ORDER BY table_name, ordinal_position;

-- Display policy information
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
