-- =====================================================
-- SNAPPYCARDS COMPLETE DATABASE FIX
-- =====================================================
-- This script creates ALL missing tables required for the SnappyCards application
-- to work properly, especially for student login and flashcard study functionality.
--
-- INSTRUCTIONS:
-- 1. Login to your Supabase project: aeijlzokobuqcyznljvn.supabase.co
-- 2. Go to SQL Editor
-- 3. Copy and paste this ENTIRE script
-- 4. Click "Run" to execute
-- 5. Verify the results at the bottom
--
-- TABLES CREATED:
-- - user_card_progress (CRITICAL - tracks individual card learning progress)
-- - user_set_progress (tracks overall set study progress)
-- - study_logs (detailed analytics and spaced repetition data)
-- - card_interactions (real-time interaction tracking)
-- - waitlist (for landing page email collection)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. USER_CARD_PROGRESS TABLE (CRITICAL FOR STUDY FUNCTIONALITY)
-- =====================================================
-- This table tracks individual user progress on flashcards within specific sets and directions
-- WITHOUT THIS TABLE, STUDENTS CANNOT STUDY OR SAVE PROGRESS

CREATE TABLE IF NOT EXISTS user_card_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')), -- Language learning direction
    mastery_level INTEGER DEFAULT 1 CHECK (mastery_level >= 1 AND mastery_level <= 3), -- 1=tanulandó, 2=bizonytalan, 3=tudom
    last_reviewed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    next_review TIMESTAMP WITH TIME ZONE, -- For spaced repetition
    review_count INTEGER DEFAULT 1,
    correct_count INTEGER DEFAULT 0,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Composite unique constraint for user-card-set-direction combination
    UNIQUE(user_id, card_id, set_id, direction)
);

-- =====================================================
-- 2. USER_SET_PROGRESS TABLE
-- =====================================================
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

-- =====================================================
-- 3. STUDY_LOGS TABLE
-- =====================================================
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

-- =====================================================
-- 4. CARD_INTERACTIONS TABLE
-- =====================================================
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

-- =====================================================
-- 5. WAITLIST TABLE
-- =====================================================
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

-- =====================================================
-- ENABLE ROW LEVEL SECURITY ON ALL NEW TABLES
-- =====================================================

ALTER TABLE user_card_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_set_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES - USER_CARD_PROGRESS (CRITICAL)
-- =====================================================

-- Users can read their own progress
CREATE POLICY "Users can read own card progress" ON user_card_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own progress records
CREATE POLICY "Users can create own card progress" ON user_card_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress records  
CREATE POLICY "Users can update own card progress" ON user_card_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Teachers can read progress on their own sets
CREATE POLICY "Teachers can read progress on own sets" ON user_card_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = user_card_progress.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - USER_SET_PROGRESS
-- =====================================================

CREATE POLICY "Users can read own set progress" ON user_set_progress
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own set progress" ON user_set_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own set progress" ON user_set_progress
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Teachers can read set progress on own sets" ON user_set_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = user_set_progress.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - STUDY_LOGS
-- =====================================================

CREATE POLICY "Users can read own study logs" ON study_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own study logs" ON study_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Teachers can read logs for own sets" ON study_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = study_logs.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - CARD_INTERACTIONS
-- =====================================================

CREATE POLICY "Users can read own card interactions" ON card_interactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM study_sessions ss
            WHERE ss.id = card_interactions.session_id
            AND ss.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own card interactions" ON card_interactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM study_sessions ss
            WHERE ss.id = card_interactions.session_id
            AND ss.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - WAITLIST
-- =====================================================

CREATE POLICY "Public can join waitlist" ON waitlist
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Authenticated users can read waitlist" ON waitlist
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- =====================================================
-- CREATE PERFORMANCE INDEXES
-- =====================================================

-- user_card_progress indexes (CRITICAL for performance)
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user ON user_card_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_card ON user_card_progress(card_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_set ON user_card_progress(set_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_direction ON user_card_progress(direction);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user_set ON user_card_progress(user_id, set_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user_set_direction ON user_card_progress(user_id, set_id, direction);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_mastery ON user_card_progress(mastery_level);

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

-- card_interactions indexes  
CREATE INDEX IF NOT EXISTS idx_card_interactions_session ON card_interactions(session_id);
CREATE INDEX IF NOT EXISTS idx_card_interactions_card ON card_interactions(card_id);

-- waitlist indexes
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_status ON waitlist(status);

-- =====================================================
-- ADD UPDATED_AT TRIGGERS
-- =====================================================

CREATE TRIGGER update_user_card_progress_updated_at
    BEFORE UPDATE ON user_card_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_set_progress_updated_at
    BEFORE UPDATE ON user_set_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_waitlist_updated_at
    BEFORE UPDATE ON waitlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant permissions to authenticated users
GRANT ALL ON user_card_progress TO authenticated;
GRANT ALL ON user_set_progress TO authenticated;
GRANT ALL ON study_logs TO authenticated;  
GRANT ALL ON card_interactions TO authenticated;
GRANT ALL ON waitlist TO authenticated;

-- Grant permissions to anonymous users for waitlist
GRANT INSERT ON waitlist TO anon;

-- =====================================================
-- TABLE DOCUMENTATION
-- =====================================================

COMMENT ON TABLE user_card_progress IS 'CRITICAL: Tracks individual user progress on flashcards within specific sets and learning directions';
COMMENT ON COLUMN user_card_progress.mastery_level IS '1=tanulandó (need to learn), 2=bizonytalan (uncertain), 3=tudom (mastered)';
COMMENT ON COLUMN user_card_progress.direction IS 'Learning direction: hu-en (Hungarian to English) or en-hu (English to Hungarian)';

COMMENT ON TABLE user_set_progress IS 'Tracks user progress and study metrics for entire flashcard sets';
COMMENT ON TABLE study_logs IS 'Detailed study session logs for analytics and spaced repetition algorithms';
COMMENT ON TABLE card_interactions IS 'Real-time card interaction tracking for advanced learning analytics';
COMMENT ON TABLE waitlist IS 'Email waitlist for landing page and user acquisition';

-- =====================================================
-- VERIFICATION AND RESULTS
-- =====================================================

-- Check that all tables were created successfully
SELECT 
    '🎉 DATABASE FIX COMPLETED SUCCESSFULLY!' as status,
    'All missing tables have been created with proper RLS policies and indexes.' as details;

-- Show table creation results
SELECT 
    table_name,
    'CREATED' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_card_progress', 'user_set_progress', 'study_logs', 'card_interactions', 'waitlist')
ORDER BY table_name;

-- Show existing record counts (should be 0 for new tables)
SELECT 
    'Table record counts:' as info,
    (SELECT count(*) FROM user_card_progress) as user_card_progress_records,
    (SELECT count(*) FROM user_set_progress) as user_set_progress_records,
    (SELECT count(*) FROM study_logs) as study_logs_records,
    (SELECT count(*) FROM card_interactions) as card_interactions_records,
    (SELECT count(*) FROM waitlist) as waitlist_records;

-- =====================================================
-- NEXT STEPS
-- =====================================================
SELECT 
    '✅ NEXT STEPS:' as instructions,
    '1. Test student login at your application' as step_1,
    '2. Try studying flashcards to verify progress saving works' as step_2,
    '3. Check if slot-machine.html loads cards properly' as step_3,
    '4. Verify that progress is saved between sessions' as step_4;