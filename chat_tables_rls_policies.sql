-- ============================================================
-- CHAT MODULE RLS POLICIES
-- Run this in Supabase SQL Editor after creating chat_threads and messages tables
-- ============================================================

-- Enable Row Level Security
ALTER TABLE chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- CHAT_THREADS POLICIES
-- ============================================================

-- Users can view threads they are part of (as restaurant or NGO)
CREATE POLICY "Users can view their chat threads" ON chat_threads
    FOR SELECT USING (
        auth.uid() = restaurant_id OR auth.uid() = ngo_id
    );

-- Users can create threads where they are a participant
CREATE POLICY "Users can create chat threads" ON chat_threads
    FOR INSERT WITH CHECK (
        auth.uid() = restaurant_id OR auth.uid() = ngo_id
    );

-- Users can update threads they are part of (for last_message_at, etc.)
CREATE POLICY "Users can update their chat threads" ON chat_threads
    FOR UPDATE USING (
        auth.uid() = restaurant_id OR auth.uid() = ngo_id
    );

-- ============================================================
-- MESSAGES POLICIES
-- ============================================================

-- Users can view messages in threads they are part of
CREATE POLICY "Users can view their messages" ON messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

-- Users can insert messages where they are the sender
CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id
    );

-- Users can update messages they received (for marking as read)
CREATE POLICY "Users can update received messages" ON messages
    FOR UPDATE USING (
        auth.uid() = receiver_id
    );

-- Users can delete messages they sent
CREATE POLICY "Users can delete their sent messages" ON messages
    FOR DELETE USING (
        auth.uid() = sender_id
    );

-- ============================================================
-- INDEXES (if not already created)
-- ============================================================

-- These should already exist from your schema, but including for completeness
CREATE INDEX IF NOT EXISTS chat_threads_restaurant_id_idx ON chat_threads(restaurant_id);
CREATE INDEX IF NOT EXISTS chat_threads_ngo_id_idx ON chat_threads(ngo_id);
CREATE INDEX IF NOT EXISTS chat_threads_donation_id_idx ON chat_threads(donation_id);
CREATE INDEX IF NOT EXISTS chat_threads_last_message_at_idx ON chat_threads(last_message_at DESC);

CREATE INDEX IF NOT EXISTS messages_thread_id_idx ON messages(thread_id);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_receiver_id_idx ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS messages_is_read_idx ON messages(is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS messages_thread_created_idx ON messages(thread_id, created_at DESC);

-- ============================================================
-- REALTIME PUBLICATION
-- ============================================================

-- Enable realtime for messages table (required for subscriptions)
-- Run in Supabase dashboard: Database > Replication
-- Or use this command:
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_threads;
