-- Create profiles table for WasteLess app
-- Run this in your Supabase SQL editor

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('restaurant', 'ngo')),
    location TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles table
-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Note: Profile creation is handled in the Flutter app
    -- This function can be used for additional logic if needed
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS profiles_role_idx ON profiles(role);
CREATE INDEX IF NOT EXISTS profiles_location_idx ON profiles(location);
CREATE INDEX IF NOT EXISTS profiles_created_at_idx ON profiles(created_at);

-- ============================================================
-- Inventory and Donations Schema
-- ============================================================

-- Create inventory_items table
CREATE TABLE IF NOT EXISTS inventory_items (
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

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurants can view own inventory" ON inventory_items
    FOR SELECT USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can insert own inventory" ON inventory_items
    FOR INSERT WITH CHECK (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can update own inventory" ON inventory_items
    FOR UPDATE USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can delete own inventory" ON inventory_items
    FOR DELETE USING (auth.uid() = restaurant_id);

-- Create donations table
CREATE TABLE IF NOT EXISTS donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL, -- Link to inventory item
    restaurant_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    quantity TEXT NOT NULL,
    expiry_date DATE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'claimed', 'completed', 'cancelled')),
    posted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    claimed_by UUID REFERENCES profiles(id) ON DELETE SET NULL, -- NGO who claimed it
    claimed_at TIMESTAMP WITH TIME ZONE,
    claim_message TEXT,
    completed_at TIMESTAMP WITH TIME ZONE
);

ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view donations" ON donations
    FOR SELECT USING (auth.role() = 'authenticated'); -- All authenticated users can see available donations

CREATE POLICY "Restaurants can insert own donations" ON donations
    FOR INSERT WITH CHECK (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can update own donations" ON donations
    FOR UPDATE USING (auth.uid() = restaurant_id);

CREATE POLICY "Restaurants can delete own donations" ON donations
    FOR DELETE USING (auth.uid() = restaurant_id);

-- Create donation_claims table (for tracking claims by NGOs)
CREATE TABLE IF NOT EXISTS donation_claims (
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

ALTER TABLE donation_claims ENABLE ROW LEVEL SECURITY;

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
