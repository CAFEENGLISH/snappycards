-- SnappyCards Database Schema Setup
-- This script creates all necessary tables and RLS policies

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. SCHOOLS TABLE
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    contact_email TEXT,
    admin_user_id UUID REFERENCES auth.users(id),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. USER_PROFILES TABLE (This is critical for authentication)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL DEFAULT '',
    last_name TEXT DEFAULT '',
    email TEXT UNIQUE NOT NULL,
    user_role TEXT NOT NULL CHECK (user_role IN ('student', 'teacher', 'school_admin')) DEFAULT 'student',
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    language TEXT DEFAULT 'hu',
    country TEXT DEFAULT 'HU',
    phone TEXT,
    status TEXT DEFAULT 'active',
    note TEXT,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#7c3aed',
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. FLASHCARD_SETS TABLE
CREATE TABLE IF NOT EXISTS flashcard_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    language_a TEXT NOT NULL DEFAULT 'hu',
    language_b TEXT NOT NULL DEFAULT 'en',
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CARDS TABLE
CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    english_title TEXT NOT NULL,
    title_formatted TEXT,
    english_title_formatted TEXT,
    image_url TEXT NOT NULL,
    image_alt TEXT NOT NULL,
    media_type TEXT,
    media_url TEXT,
    category TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. CARD_CATEGORIES (Junction table)
CREATE TABLE IF NOT EXISTS card_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(card_id, category_id)
);

-- 7. FLASHCARD_SET_CARDS (Junction table)
CREATE TABLE IF NOT EXISTS flashcard_set_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    position INTEGER DEFAULT 0,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(set_id, card_id)
);

-- 8. FLASHCARD_SET_CATEGORIES (Junction table)
CREATE TABLE IF NOT EXISTS flashcard_set_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(set_id, category_id)
);

-- 9. CLASSROOMS TABLE
CREATE TABLE IF NOT EXISTS classrooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    teacher_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. CLASSROOM_SETS (Junction table)
CREATE TABLE IF NOT EXISTS classroom_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_mock BOOLEAN DEFAULT false,
    UNIQUE(classroom_id, set_id)
);

-- 11. STUDY_SESSIONS TABLE
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_data JSONB NOT NULL DEFAULT '{}',
    total_time INTEGER DEFAULT 0,
    cards_studied INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    uncertain_answers INTEGER DEFAULT 0,
    need_to_learn INTEGER DEFAULT 0,
    is_mock BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ======================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ======================

-- Enable RLS on all tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_set_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_set_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

-- ======================
-- USER_PROFILES POLICIES (Critical for auth!)
-- ======================

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Allow authenticated users to insert their own profile during signup
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- School admins can read profiles of users in their school
CREATE POLICY "School admins can read school profiles" ON user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile
            WHERE admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND admin_profile.school_id = user_profiles.school_id
        )
    );

-- ======================
-- SCHOOLS POLICIES
-- ======================

-- School admins can read their own school
CREATE POLICY "School admins can read own school" ON schools
    FOR SELECT USING (admin_user_id = auth.uid());

-- School admins can update their own school
CREATE POLICY "School admins can update own school" ON schools
    FOR UPDATE USING (admin_user_id = auth.uid());

-- Allow school creation during registration
CREATE POLICY "Allow school creation" ON schools
    FOR INSERT WITH CHECK (admin_user_id = auth.uid());

-- ======================
-- FLASHCARD_SETS POLICIES
-- ======================

-- Users can read their own sets
CREATE POLICY "Users can read own sets" ON flashcard_sets
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own sets
CREATE POLICY "Users can create own sets" ON flashcard_sets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own sets
CREATE POLICY "Users can update own sets" ON flashcard_sets
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own sets
CREATE POLICY "Users can delete own sets" ON flashcard_sets
    FOR DELETE USING (auth.uid() = user_id);

-- School admins can read sets from their school's teachers
CREATE POLICY "School admins can read school sets" ON flashcard_sets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles admin_profile, user_profiles teacher_profile
            WHERE admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND teacher_profile.id = flashcard_sets.user_id
            AND teacher_profile.school_id = admin_profile.school_id
        )
    );

-- ======================
-- CARDS POLICIES
-- ======================

-- Allow read access to all cards (for now - can be restricted later)
CREATE POLICY "Allow read access to cards" ON cards
    FOR SELECT USING (true);

-- Only authenticated users can create cards
CREATE POLICY "Authenticated users can create cards" ON cards
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ======================
-- STUDY_SESSIONS POLICIES
-- ======================

-- Users can read their own study sessions
CREATE POLICY "Users can read own study sessions" ON study_sessions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own study sessions
CREATE POLICY "Users can create own study sessions" ON study_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own study sessions
CREATE POLICY "Users can update own study sessions" ON study_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- ======================
-- FUNCTIONS AND TRIGGERS
-- ======================

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (id, email, first_name, user_role, language, country)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'user_role', 'student'),
        COALESCE(NEW.raw_user_meta_data->>'language', 'hu'),
        COALESCE(NEW.raw_user_meta_data->>'country', 'HU')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
CREATE TRIGGER create_user_profile_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_profile();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to tables that have updated_at column
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schools_updated_at
    BEFORE UPDATE ON schools
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flashcard_sets_updated_at
    BEFORE UPDATE ON flashcard_sets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_study_sessions_updated_at
    BEFORE UPDATE ON study_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ======================
-- INDEXES FOR PERFORMANCE
-- ======================

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(user_role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_school ON user_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- Flashcard sets indexes
CREATE INDEX IF NOT EXISTS idx_flashcard_sets_user ON flashcard_sets(user_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_sets_created ON flashcard_sets(created_at);

-- Study sessions indexes
CREATE INDEX IF NOT EXISTS idx_study_sessions_user ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_created ON study_sessions(created_at);

-- Classrooms indexes
CREATE INDEX IF NOT EXISTS idx_classrooms_teacher ON classrooms(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_school ON classrooms(school_id);

-- Junction table indexes
CREATE INDEX IF NOT EXISTS idx_flashcard_set_cards_set ON flashcard_set_cards(set_id);
CREATE INDEX IF NOT EXISTS idx_flashcard_set_cards_card ON flashcard_set_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_classroom_sets_classroom ON classroom_sets(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_sets_set ON classroom_sets(set_id);

-- ======================
-- TEST DATA (Optional)
-- ======================

-- Insert test user profile for vidamkos@gmail.com if it doesn't exist
-- This helps with the immediate login issue
DO $$
BEGIN
    -- Only run if the user exists in auth.users
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = 'vidamkos@gmail.com') THEN
        INSERT INTO user_profiles (id, email, first_name, user_role, language, country)
        SELECT 
            id,
            email,
            COALESCE(raw_user_meta_data->>'first_name', 'Admin'),
            COALESCE(raw_user_meta_data->>'user_role', 'school_admin'),
            COALESCE(raw_user_meta_data->>'language', 'hu'),
            COALESCE(raw_user_meta_data->>'country', 'HU')
        FROM auth.users 
        WHERE email = 'vidamkos@gmail.com'
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- Grant necessary permissions to authenticated role
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant necessary permissions to anon role for auth endpoints
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON user_profiles TO anon;

COMMENT ON TABLE user_profiles IS 'User profiles with role-based access control';
COMMENT ON TABLE schools IS 'School organizations with admin management';
COMMENT ON TABLE flashcard_sets IS 'Flashcard sets created by teachers';
COMMENT ON TABLE cards IS 'Individual flashcards with multilingual content';
COMMENT ON TABLE study_sessions IS 'User study session tracking and analytics';