-- =====================================================
-- SNAPPYCARDS COMPLETE MISSING TABLES CREATION
-- =====================================================
-- This script creates ALL 13 missing tables in the correct dependency order
-- Based on the analysis, these tables are missing from the NEW project:
-- 1. categories, 2. card_categories, 3. flashcard_set_categories,
-- 4. classrooms, 5. classroom_details, 6. classroom_members, 7. classroom_sets,
-- 8. study_sessions, 9. study_logs, 10. card_interactions, 11. user_set_progress,
-- 12. favicons, 13. waitlist
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CATEGORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '#3B82F6',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. CARD_CATEGORIES TABLE (Junction)
-- =====================================================
CREATE TABLE IF NOT EXISTS card_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(card_id, category_id)
);

-- =====================================================
-- 3. FLASHCARD_SET_CATEGORIES TABLE (Junction)
-- =====================================================
CREATE TABLE IF NOT EXISTS flashcard_set_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(set_id, category_id)
);

-- =====================================================
-- 4. CLASSROOMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS classrooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    teacher_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    access_code TEXT UNIQUE,
    is_active BOOLEAN DEFAULT true,
    max_students INTEGER DEFAULT 30,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. CLASSROOM_DETAILS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS classroom_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE NOT NULL UNIQUE,
    subject TEXT,
    grade_level TEXT,
    academic_year TEXT,
    meeting_schedule TEXT,
    additional_info JSONB DEFAULT '{}',
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 6. CLASSROOM_MEMBERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS classroom_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role TEXT DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'assistant')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(classroom_id, user_id)
);

-- =====================================================
-- 7. CLASSROOM_SETS TABLE (Junction)
-- =====================================================
CREATE TABLE IF NOT EXISTS classroom_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    assigned_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    is_required BOOLEAN DEFAULT true,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(classroom_id, set_id)
);

-- =====================================================
-- 8. STUDY_SESSIONS TABLE (Required by other tables)
-- =====================================================
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')),
    session_type TEXT DEFAULT 'study' CHECK (session_type IN ('study', 'practice', 'test', 'review')),
    cards_studied INTEGER DEFAULT 0,
    cards_correct INTEGER DEFAULT 0,
    cards_incorrect INTEGER DEFAULT 0,
    total_time INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    is_completed BOOLEAN DEFAULT false,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 9. USER_SET_PROGRESS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_set_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    total_time_spent INTEGER DEFAULT 0,
    last_studied TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cards_studied INTEGER DEFAULT 0,
    cards_mastered INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, set_id)
);

-- =====================================================
-- 10. STUDY_LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS study_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE NOT NULL,
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('tudom', 'bizonytalan', 'tanulandó', 'easy', 'medium', 'hard')),
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')),
    reaction_time INTEGER,
    mastery_level_before INTEGER,
    mastery_level_after INTEGER,
    review_interval INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 11. CARD_INTERACTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS card_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES study_sessions(id) ON DELETE CASCADE NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE NOT NULL,
    direction TEXT NOT NULL DEFAULT 'hu-en' CHECK (direction IN ('hu-en', 'en-hu')),
    reaction_time INTEGER,
    feedback_type TEXT CHECK (feedback_type IN ('tudom', 'bizonytalan', 'tanulandó')),
    interaction_type TEXT DEFAULT 'view' CHECK (interaction_type IN ('view', 'flip', 'feedback', 'skip')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 12. FAVICONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS favicons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    domain TEXT NOT NULL UNIQUE,
    favicon_url TEXT NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    fetch_attempts INTEGER DEFAULT 0,
    last_fetch_attempt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 13. WAITLIST TABLE
-- =====================================================
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
-- ENABLE ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_set_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_set_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE favicons ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES - CATEGORIES
-- =====================================================
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create categories" ON categories
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own categories" ON categories
    FOR UPDATE USING (auth.uid() = created_by);

-- =====================================================
-- RLS POLICIES - CARD_CATEGORIES
-- =====================================================
CREATE POLICY "Card categories viewable by everyone" ON card_categories
    FOR SELECT USING (true);

CREATE POLICY "Teachers can manage card categories" ON card_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM cards c
            JOIN flashcard_sets fs ON c.id = ANY(
                SELECT card_id FROM flashcard_set_cards WHERE set_id = fs.id
            )
            WHERE c.id = card_categories.card_id
            AND fs.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - FLASHCARD_SET_CATEGORIES
-- =====================================================
CREATE POLICY "Set categories viewable by everyone" ON flashcard_set_categories
    FOR SELECT USING (true);

CREATE POLICY "Teachers can manage set categories" ON flashcard_set_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM flashcard_sets fs
            WHERE fs.id = flashcard_set_categories.set_id
            AND fs.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - CLASSROOMS
-- =====================================================
CREATE POLICY "Teachers can manage own classrooms" ON classrooms
    FOR ALL USING (auth.uid() = teacher_id);

CREATE POLICY "Students can view classrooms they belong to" ON classrooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classroom_members cm
            WHERE cm.classroom_id = classrooms.id
            AND cm.user_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - CLASSROOM_DETAILS
-- =====================================================
CREATE POLICY "Classroom details follow classroom access" ON classroom_details
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_details.classroom_id
            AND (c.teacher_id = auth.uid() OR EXISTS (
                SELECT 1 FROM classroom_members cm
                WHERE cm.classroom_id = c.id AND cm.user_id = auth.uid()
            ))
        )
    );

CREATE POLICY "Teachers can update classroom details" ON classroom_details
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_details.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - CLASSROOM_MEMBERS
-- =====================================================
CREATE POLICY "Classroom members viewable by classroom participants" ON classroom_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_members.classroom_id
            AND (c.teacher_id = auth.uid() OR EXISTS (
                SELECT 1 FROM classroom_members cm2
                WHERE cm2.classroom_id = c.id AND cm2.user_id = auth.uid()
            ))
        )
    );

CREATE POLICY "Teachers can manage classroom members" ON classroom_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_members.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - CLASSROOM_SETS
-- =====================================================
CREATE POLICY "Classroom sets viewable by participants" ON classroom_sets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_sets.classroom_id
            AND (c.teacher_id = auth.uid() OR EXISTS (
                SELECT 1 FROM classroom_members cm
                WHERE cm.classroom_id = c.id AND cm.user_id = auth.uid()
            ))
        )
    );

CREATE POLICY "Teachers can manage classroom sets" ON classroom_sets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_sets.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- =====================================================
-- RLS POLICIES - STUDY_SESSIONS
-- =====================================================
CREATE POLICY "Users can read own study sessions" ON study_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own study sessions" ON study_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study sessions" ON study_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Teachers can read classroom study sessions" ON study_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = study_sessions.classroom_id
            AND c.teacher_id = auth.uid()
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

CREATE POLICY "Teachers can read progress on own sets" ON user_set_progress
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
-- RLS POLICIES - FAVICONS
-- =====================================================
CREATE POLICY "Favicons are publicly readable" ON favicons
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage favicons" ON favicons
    FOR ALL WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- RLS POLICIES - WAITLIST
-- =====================================================
CREATE POLICY "Public can join waitlist" ON waitlist
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Authenticated users can read waitlist" ON waitlist
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Categories indexes
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active);

-- Card categories indexes
CREATE INDEX IF NOT EXISTS idx_card_categories_card ON card_categories(card_id);
CREATE INDEX IF NOT EXISTS idx_card_categories_category ON card_categories(category_id);

-- Flashcard set categories indexes
CREATE INDEX IF NOT EXISTS idx_flashcard_set_categories_set ON flashcard_set_categories(set_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_set_categories_category ON flashcard_set_categories(category_id);

-- Classrooms indexes
CREATE INDEX IF NOT EXISTS idx_classrooms_teacher ON classrooms(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_school ON classrooms(school_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_access_code ON classrooms(access_code);

-- Classroom members indexes
CREATE INDEX IF NOT EXISTS idx_classroom_members_classroom ON classroom_members(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_members_user ON classroom_members(user_id);
CREATE INDEX IF NOT EXISTS idx_classroom_members_role ON classroom_members(role);

-- Study sessions indexes
CREATE INDEX IF NOT EXISTS idx_study_sessions_user ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_set ON study_sessions(set_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_classroom ON study_sessions(classroom_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_started ON study_sessions(started_at);

-- User set progress indexes
CREATE INDEX IF NOT EXISTS idx_user_set_progress_user ON user_set_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_set_progress_set ON user_set_progress(set_id);
CREATE INDEX IF NOT EXISTS idx_user_set_progress_last_studied ON user_set_progress(last_studied);

-- Study logs indexes
CREATE INDEX IF NOT EXISTS idx_study_logs_user ON study_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_card ON study_logs(card_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_set ON study_logs(set_id);
CREATE INDEX IF NOT EXISTS idx_study_logs_session ON study_logs(session_id);

-- Card interactions indexes
CREATE INDEX IF NOT EXISTS idx_card_interactions_session ON card_interactions(session_id);
CREATE INDEX IF NOT EXISTS idx_card_interactions_card ON card_interactions(card_id);

-- Favicons indexes
CREATE INDEX IF NOT EXISTS idx_favicons_domain ON favicons(domain);
CREATE INDEX IF NOT EXISTS idx_favicons_active ON favicons(is_active);

-- Waitlist indexes
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_status ON waitlist(status);

-- =====================================================
-- ADD UPDATED_AT TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at columns
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classrooms_updated_at
    BEFORE UPDATE ON classrooms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classroom_details_updated_at
    BEFORE UPDATE ON classroom_details
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
GRANT ALL ON categories TO authenticated;
GRANT ALL ON card_categories TO authenticated;
GRANT ALL ON flashcard_set_categories TO authenticated;
GRANT ALL ON classrooms TO authenticated;
GRANT ALL ON classroom_details TO authenticated;
GRANT ALL ON classroom_members TO authenticated;
GRANT ALL ON classroom_sets TO authenticated;
GRANT ALL ON study_sessions TO authenticated;
GRANT ALL ON user_set_progress TO authenticated;
GRANT ALL ON study_logs TO authenticated;
GRANT ALL ON card_interactions TO authenticated;
GRANT ALL ON favicons TO authenticated;
GRANT ALL ON waitlist TO authenticated;

-- Grant specific permissions to anonymous users
GRANT INSERT ON waitlist TO anon;
GRANT SELECT ON favicons TO anon;

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
SELECT 
    'Migration completed! All 13 missing tables have been created.' as status,
    COUNT(*) as total_tables_created
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'categories', 'card_categories', 'flashcard_set_categories',
    'classrooms', 'classroom_details', 'classroom_members', 'classroom_sets',
    'study_sessions', 'user_set_progress', 'study_logs', 'card_interactions',
    'favicons', 'waitlist'
);