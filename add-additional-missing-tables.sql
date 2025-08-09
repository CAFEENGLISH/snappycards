-- SnappyCards Additional Missing Tables Fix
-- This script creates additional tables referenced in the codebase but missing from the current schema

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ======================
-- 1. USER_SET_PROGRESS TABLE
-- ======================
-- Tracks user progress on entire flashcard sets (study time, last studied, etc.)
CREATE TABLE IF NOT EXISTS user_set_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    total_time_spent INTEGER DEFAULT 0, -- Total study time in seconds
    last_studied TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cards_studied INTEGER DEFAULT 0,
    cards_mastered INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint for user-set combination
    UNIQUE(user_id, set_id)
);

-- ======================
-- 2. STUDY_LOGS TABLE  
-- ======================
-- Detailed logs for analytics and spaced repetition algorithms
CREATE TABLE IF NOT EXISTS study_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('tudom', 'bizonytalan', 'tanulandó', 'easy', 'medium', 'hard')),
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')),
    reaction_time INTEGER, -- Milliseconds
    mastery_level_before INTEGER,
    mastery_level_after INTEGER,
    review_interval INTEGER, -- Days until next review
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ======================
-- 3. CARD_INTERACTIONS TABLE
-- ======================
-- Real-time card interaction tracking for advanced analytics
CREATE TABLE IF NOT EXISTS card_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')),
    reaction_time INTEGER, -- Milliseconds
    feedback_type TEXT CHECK (feedback_type IN ('tudom', 'bizonytalan', 'tanulandó')),
    interaction_type TEXT DEFAULT 'view' CHECK (interaction_type IN ('view', 'flip', 'feedback', 'skip')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ======================
-- 4. WAITLIST TABLE
-- ======================
-- For landing page email collection
CREATE TABLE IF NOT EXISTS waitlist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT,
    language TEXT DEFAULT 'hu',
    source TEXT DEFAULT 'landing_page',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'invited', 'registered')),
    invite_sent_at TIMESTAMP WITH TIME ZONE,
    registered_at TIMESTAMP WITH TIME ZONE,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ======================
-- ENABLE RLS ON ALL NEW TABLES
-- ======================
ALTER TABLE user_set_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- ======================
-- RLS POLICIES - USER_SET_PROGRESS
-- ======================

-- Users can read their own set progress
CREATE POLICY "Users can read own set progress" ON user_set_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own set progress
CREATE POLICY "Users can create own set progress" ON user_set_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own set progress  
CREATE POLICY "Users can update own set progress" ON user_set_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Teachers can read progress on their own sets
CREATE POLICY "Teachers can read set progress on own sets" ON user_set_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = user_set_progress.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- ======================
-- RLS POLICIES - STUDY_LOGS
-- ======================

-- Users can read their own study logs
CREATE POLICY "Users can read own study logs" ON study_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own study logs
CREATE POLICY "Users can create own study logs" ON study_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Teachers can read logs for their own sets
CREATE POLICY "Teachers can read logs for own sets" ON study_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = study_logs.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- School admins can read logs for their school's users
CREATE POLICY "School admins can read school study logs" ON study_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile, user_profiles user_profile
            WHERE admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND user_profile.id = study_logs.user_id
            AND user_profile.school_id = admin_profile.school_id
        )
    );

-- ======================
-- RLS POLICIES - CARD_INTERACTIONS
-- ======================

-- Users can read their own card interactions (through study_sessions)
CREATE POLICY "Users can read own card interactions" ON card_interactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM study_sessions ss
            WHERE ss.id = card_interactions.session_id
            AND ss.user_id = auth.uid()
        )
    );

-- Users can create card interactions for their own sessions
CREATE POLICY "Users can create own card interactions" ON card_interactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM study_sessions ss
            WHERE ss.id = card_interactions.session_id
            AND ss.user_id = auth.uid()
        )
    );

-- ======================
-- RLS POLICIES - WAITLIST
-- ======================

-- Public can insert into waitlist (for landing page)
CREATE POLICY "Public can join waitlist" ON waitlist
    FOR INSERT WITH CHECK (true);

-- Only authenticated users can read waitlist (admin functionality)
CREATE POLICY "Authenticated users can read waitlist" ON waitlist
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Only authenticated users can update waitlist status
CREATE POLICY "Authenticated users can update waitlist" ON waitlist
    FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ======================
-- INDEXES FOR PERFORMANCE
-- ======================

-- user_set_progress indexes
CREATE INDEX IF NOT EXISTS idx_user_set_progress_user ON user_set_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_set_progress_set ON user_set_progress(set_id);
CREATE INDEX IF NOT EXISTS idx_user_set_progress_last_studied ON user_set_progress(last_studied);

-- study_logs indexes
CREATE INDEX IF NOT EXISTS idx_study_logs_user ON study_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_card ON study_logs(card_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_set ON study_logs(set_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_session ON study_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_created ON study_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_study_logs_feedback ON study_logs(feedback_type);
CREATE INDEX IF NOT EXISTS idx_study_logs_direction ON study_logs(direction);

-- card_interactions indexes  
CREATE INDEX IF NOT EXISTS idx_card_interactions_session ON card_interactions(session_id);
CREATE INDEX IF NOT EXISTS idx_card_interactions_card ON card_interactions(card_id);
CREATE INDEX IF NOT EXISTS idx_card_interactions_timestamp ON card_interactions(timestamp);
CREATE INDEX IF NOT EXISTS idx_card_interactions_direction ON card_interactions(direction);

-- waitlist indexes
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_status ON waitlist(status);
CREATE INDEX IF NOT EXISTS idx_waitlist_created ON waitlist(created_at);

-- ======================
-- TRIGGERS
-- ======================

-- Add updated_at triggers
CREATE TRIGGER update_user_set_progress_updated_at
    BEFORE UPDATE ON user_set_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_waitlist_updated_at
    BEFORE UPDATE ON waitlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ======================
-- PERMISSIONS
-- ======================

-- Grant necessary permissions to authenticated role
GRANT ALL ON user_set_progress TO authenticated;
GRANT ALL ON study_logs TO authenticated;  
GRANT ALL ON card_interactions TO authenticated;
GRANT ALL ON waitlist TO authenticated;

-- Grant permissions to anonymous role for waitlist
GRANT INSERT ON waitlist TO anon;

-- ======================
-- TABLE COMMENTS
-- ======================

COMMENT ON TABLE user_set_progress IS 'Tracks user progress and study metrics for entire flashcard sets';
COMMENT ON TABLE study_logs IS 'Detailed study session logs for analytics and spaced repetition algorithms';
COMMENT ON TABLE card_interactions IS 'Real-time card interaction tracking for advanced learning analytics';
COMMENT ON TABLE waitlist IS 'Email waitlist for landing page and user acquisition';

-- ======================
-- VERIFY TABLE CREATION
-- ======================

SELECT 
    'Additional tables created successfully!' as result,
    (SELECT count(*) FROM user_set_progress) as user_set_progress_records,
    (SELECT count(*) FROM study_logs) as study_logs_records,
    (SELECT count(*) FROM card_interactions) as card_interactions_records,
    (SELECT count(*) FROM waitlist) as waitlist_records;