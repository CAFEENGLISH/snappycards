-- =====================================================
-- CREATE MISSING TABLES IN NEW SUPABASE PROJECT
-- =====================================================
-- Run this in the NEW project: aeijlzokobuqcyznljvn.supabase.co
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. FAVICONS TABLE (6 columns with 1 row of data)
-- =====================================================
-- Based on the extracted data structure from the OLD project
CREATE TABLE IF NOT EXISTS favicons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    data_url TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Insert the favicon data from the OLD project
INSERT INTO favicons (id, name, data_url, mime_type, created_at, is_active) 
VALUES (
    '410ad964-fdee-4a87-8d72-1e359aa209c9',
    'SnappyCards Main Favicon',
    'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPCEtLSBCYWNrZ3JvdW5kIC0tPgo8cmVjdCB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHJ4PSI0IiBmaWxsPSIjNjM2NmYxIi8+CjwhLS0gQ2FyZCBTaGFwZSAtLT4KPHJlY3QgeD0iNCIgeT0iNiIgd2lkdGg9IjI0IiBoZWlnaHQ9IjE2IiByeD0iMyIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjZGRkZGRkIiBzdHJva2Utd2lkdGg9IjAuNSIvPgo8IS0tIFRleHQgUyAtLT4KPHRleHQgeD0iMTYiIHk9IjE4IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNjM2NmYxIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkb21pbmFudC1iYXNlbGluZT0iY2VudHJhbCI+UzwvdGV4dD4KPCEtLSBTbWFsbCBkb3RzIGZvciBmbGFzaGNhcmQgZWZmZWN0IC0tPgo8Y2lyY2xlIGN4PSI4IiBjeT0iMTAiIHI9IjEiIGZpbGw9IiM2MzY2ZjEiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIxOCIgcj0iMSIgZmlsbD0iIzYzNjZmMSIvPgo8L3N2Zz4K',
    'image/svg+xml',
    '2025-08-04T22:18:16.773773+00:00',
    true
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. CLASSROOM_DETAILS TABLE (11 columns - estimated structure)
-- =====================================================
-- This table likely contains additional metadata for classrooms
-- Based on common patterns in educational apps
CREATE TABLE IF NOT EXISTS classroom_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    subject TEXT,
    grade_level TEXT,
    academic_year TEXT,
    meeting_schedule TEXT,
    room_number TEXT,
    max_students INTEGER DEFAULT 30,
    description TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(classroom_id)
);

-- =====================================================
-- 3. CLASSROOM_MEMBERS TABLE (5 columns - junction table)
-- =====================================================
-- This table manages the many-to-many relationship between classrooms and students
CREATE TABLE IF NOT EXISTS classroom_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    UNIQUE(classroom_id, user_id)
);

-- =====================================================
-- ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE favicons ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE classroom_members ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES FOR FAVICONS
-- =====================================================

-- Allow all authenticated users to read active favicons
CREATE POLICY "Allow read access to active favicons" ON favicons
    FOR SELECT USING (is_active = true);

-- Only admins can modify favicons (for now, allow all authenticated users)
CREATE POLICY "Allow favicon management for authenticated users" ON favicons
    FOR ALL USING (auth.uid() IS NOT NULL);

-- =====================================================
-- RLS POLICIES FOR CLASSROOM_DETAILS
-- =====================================================

-- Teachers can read details of their own classrooms
CREATE POLICY "Teachers can read own classroom details" ON classroom_details
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_details.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Teachers can update their own classroom details
CREATE POLICY "Teachers can update own classroom details" ON classroom_details
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_details.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Teachers can insert details for their own classrooms
CREATE POLICY "Teachers can insert own classroom details" ON classroom_details
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_details.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- School admins can access classroom details in their school
CREATE POLICY "School admins can access school classroom details" ON classroom_details
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c, user_profiles admin_profile
            WHERE c.id = classroom_details.classroom_id
            AND admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND admin_profile.school_id = c.school_id
        )
    );

-- =====================================================
-- RLS POLICIES FOR CLASSROOM_MEMBERS
-- =====================================================

-- Students can read their own classroom memberships
CREATE POLICY "Students can read own classroom memberships" ON classroom_members
    FOR SELECT USING (user_id = auth.uid());

-- Teachers can read memberships of their classrooms
CREATE POLICY "Teachers can read their classroom memberships" ON classroom_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_members.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- Teachers can manage memberships of their classrooms
CREATE POLICY "Teachers can manage their classroom memberships" ON classroom_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM classrooms c
            WHERE c.id = classroom_members.classroom_id
            AND c.teacher_id = auth.uid()
        )
    );

-- School admins can access classroom memberships in their school
CREATE POLICY "School admins can access school classroom memberships" ON classroom_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM classrooms c, user_profiles admin_profile
            WHERE c.id = classroom_members.classroom_id
            AND admin_profile.id = auth.uid()
            AND admin_profile.user_role = 'school_admin'
            AND admin_profile.school_id = c.school_id
        )
    );

-- =====================================================
-- ADD UPDATED_AT TRIGGERS
-- =====================================================

-- Update classroom_details updated_at on change
CREATE TRIGGER update_classroom_details_updated_at
    BEFORE UPDATE ON classroom_details
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Classroom details indexes
CREATE INDEX IF NOT EXISTS idx_classroom_details_classroom ON classroom_details(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_details_grade ON classroom_details(grade_level);
CREATE INDEX IF NOT EXISTS idx_classroom_details_subject ON classroom_details(subject);

-- Classroom members indexes
CREATE INDEX IF NOT EXISTS idx_classroom_members_classroom ON classroom_members(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classroom_members_user ON classroom_members(user_id);
CREATE INDEX IF NOT EXISTS idx_classroom_members_status ON classroom_members(status);
CREATE INDEX IF NOT EXISTS idx_classroom_members_joined ON classroom_members(joined_at);

-- Favicons indexes
CREATE INDEX IF NOT EXISTS idx_favicons_active ON favicons(is_active);
CREATE INDEX IF NOT EXISTS idx_favicons_mime ON favicons(mime_type);

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON favicons TO authenticated;
GRANT ALL ON classroom_details TO authenticated;
GRANT ALL ON classroom_members TO authenticated;

-- =====================================================
-- TABLE COMMENTS
-- =====================================================

COMMENT ON TABLE favicons IS 'Application favicon storage with base64 encoded data';
COMMENT ON TABLE classroom_details IS 'Extended details and metadata for classrooms';
COMMENT ON TABLE classroom_members IS 'Junction table for classroom-student relationships';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if all tables were created successfully
SELECT 
    '✅ TABLE VERIFICATION' as info,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('favicons', 'classroom_details', 'classroom_members')
ORDER BY table_name;

-- Check if favicon data was inserted
SELECT 
    '✅ FAVICON DATA CHECK' as info,
    COUNT(*) as favicon_count
FROM favicons;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================
SELECT '🎉 Missing tables created successfully in NEW Supabase project!' as status;