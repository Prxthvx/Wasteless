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
CREATE POLICY IF NOT EXISTS "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY IF NOT EXISTS "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY IF NOT EXISTS "Users can update own profile" ON profiles
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

-- Inventory items owned by restaurant users
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL CHECK (quantity >= 0),
    unit TEXT NOT NULL, -- e.g., kg, g, L, pcs
    expiry_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Restaurants can manage only their items
CREATE POLICY IF NOT EXISTS inventory_select_own ON inventory_items
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY IF NOT EXISTS inventory_insert_own ON inventory_items
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY IF NOT EXISTS inventory_update_own ON inventory_items
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY IF NOT EXISTS inventory_delete_own ON inventory_items
    FOR DELETE USING (auth.uid() = owner_id);

CREATE INDEX IF NOT EXISTS inventory_owner_idx ON inventory_items(owner_id);
CREATE INDEX IF NOT EXISTS inventory_expiry_idx ON inventory_items(expiry_date);

-- Donation offers posted by restaurants
CREATE TABLE IF NOT EXISTS donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL CHECK (quantity > 0),
    unit TEXT NOT NULL,
    pickup_location TEXT NOT NULL,
    best_before TIMESTAMPTZ,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available','claimed','completed','cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view available donations
CREATE POLICY IF NOT EXISTS donations_public_select_available ON donations
    FOR SELECT USING (status = 'available');

-- Restaurant can view their own donations regardless of status
CREATE POLICY IF NOT EXISTS donations_restaurant_select_own ON donations
    FOR SELECT USING (auth.uid() = restaurant_id);

-- Restaurant can insert their own donation offers
CREATE POLICY IF NOT EXISTS donations_insert_own ON donations
    FOR INSERT WITH CHECK (auth.uid() = restaurant_id);

-- Restaurant can update their own donation offers
CREATE POLICY IF NOT EXISTS donations_update_own ON donations
    FOR UPDATE USING (auth.uid() = restaurant_id);

CREATE INDEX IF NOT EXISTS donations_status_idx ON donations(status);
CREATE INDEX IF NOT EXISTS donations_restaurant_idx ON donations(restaurant_id);
CREATE INDEX IF NOT EXISTS donations_best_before_idx ON donations(best_before);

-- Claims made by NGOs on donations
CREATE TABLE IF NOT EXISTS donation_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donation_id UUID NOT NULL REFERENCES donations(id) ON DELETE CASCADE,
    ngo_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    claim_status TEXT NOT NULL DEFAULT 'pending' CHECK (claim_status IN ('pending','approved','rejected','picked_up','cancelled')),
    message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (donation_id, ngo_id)
);

ALTER TABLE donation_claims ENABLE ROW LEVEL SECURITY;

-- NGOs can see claims they made; restaurants can see claims on their donations
CREATE POLICY IF NOT EXISTS donation_claims_select_self ON donation_claims
    FOR SELECT USING (
        auth.uid() = ngo_id OR auth.uid() IN (SELECT restaurant_id FROM donations WHERE donations.id = donation_id)
    );

-- NGOs can create claims
CREATE POLICY IF NOT EXISTS donation_claims_insert_self ON donation_claims
    FOR INSERT WITH CHECK (auth.uid() = ngo_id);

-- NGOs can update their own claims; restaurants can update claims on their donations (e.g., approve)
CREATE POLICY IF NOT EXISTS donation_claims_update_self_or_owner ON donation_claims
    FOR UPDATE USING (
        auth.uid() = ngo_id OR auth.uid() IN (SELECT restaurant_id FROM donations WHERE donations.id = donation_id)
    );

CREATE INDEX IF NOT EXISTS donation_claims_donation_idx ON donation_claims(donation_id);
CREATE INDEX IF NOT EXISTS donation_claims_ngo_idx ON donation_claims(ngo_id);
