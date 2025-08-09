-- SnappyCards Missing Table Fix: user_card_progress
-- This script creates the missing user_card_progress table required for student study functionality

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- CREATE user_card_progress TABLE
-- This table tracks individual user progress on flashcards within specific sets and directions
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

-- Enable RLS on user_card_progress table
ALTER TABLE user_card_progress ENABLE ROW LEVEL SECURITY;

-- ======================
-- RLS POLICIES for user_card_progress
-- ======================

-- Users can read their own progress
CREATE POLICY "Users can read own card progress" ON user_card_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own progress records
CREATE POLICY "Users can create own card progress" ON user_card_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress records  
CREATE POLICY "Users can update own card progress" ON user_card_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own progress records
CREATE POLICY "Users can delete own card progress" ON user_card_progress
    FOR DELETE USING (auth.uid() = user_id);

-- School admins can read progress of users in their school (through flashcard_sets)
CREATE POLICY "School admins can read school user progress" ON user_card_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile, user_profiles user_profile, flashcard_sets fs
            WHERE admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND user_profile.id = user_card_progress.user_id
            AND user_profile.school_id = admin_profile.school_id
            AND fs.id = user_card_progress.set_id
        )
    );

-- Teachers can read progress on their own sets
CREATE POLICY "Teachers can read progress on own sets" ON user_card_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = user_card_progress.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- ======================
-- INDEXES for Performance
-- ======================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user ON user_card_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_card ON user_card_progress(card_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_set ON user_card_progress(set_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_direction ON user_card_progress(direction);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user_set ON user_card_progress(user_id, set_id);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_user_set_direction ON user_card_progress(user_id, set_id, direction);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_mastery ON user_card_progress(mastery_level);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_last_reviewed ON user_card_progress(last_reviewed);
CREATE INDEX IF NOT EXISTS idx_user_card_progress_next_review ON user_card_progress(next_review);

-- ======================
-- TRIGGERS
-- ======================

-- Add updated_at trigger for user_card_progress
CREATE TRIGGER update_user_card_progress_updated_at
    BEFORE UPDATE ON user_card_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ======================
-- PERMISSIONS
-- ======================

-- Grant necessary permissions to authenticated role
GRANT ALL ON user_card_progress TO authenticated;
GRANT USAGE ON SEQUENCE user_card_progress_id_seq TO authenticated;

-- ======================
-- TABLE COMMENT
-- ======================

COMMENT ON TABLE user_card_progress IS 'Tracks individual user progress on flashcards within specific sets and learning directions';
COMMENT ON COLUMN user_card_progress.mastery_level IS '1=tanulandó (need to learn), 2=bizonytalan (uncertain), 3=tudom (mastered)';
COMMENT ON COLUMN user_card_progress.direction IS 'Learning direction: hu-en (Hungarian to English) or en-hu (English to Hungarian)';
COMMENT ON COLUMN user_card_progress.next_review IS 'Calculated next review time for spaced repetition algorithm';

-- ======================
-- VERIFY TABLE CREATION
-- ======================

-- Check if table was created successfully
SELECT 
    'user_card_progress table created successfully!' as result,
    count(*) as existing_records
FROM user_card_progress;

-- Show table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_card_progress' 
ORDER BY ordinal_position;