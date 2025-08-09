-- SnappyCards Database Structure Check
-- Run this in your Supabase SQL Editor to check what tables exist and their structure

-- 1. LIST ALL TABLES IN PUBLIC SCHEMA
SELECT 
    '🗂️  All Tables in Public Schema' as check_type,
    '' as table_name,
    '' as details,
    '' as record_count
WHERE false

UNION ALL

SELECT 
    'table' as check_type,
    table_name,
    table_type as details,
    '' as record_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. CHECK CRITICAL SNAPPYCARDS TABLES EXIST
SELECT 
    '📋 Critical Tables Existence Check' as check_type,
    '' as table_name,
    '' as status,
    '' as columns
WHERE false

UNION ALL

SELECT 
    'existence_check' as check_type,
    expected_table as table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = expected_table
        ) THEN '✅ EXISTS' 
        ELSE '❌ MISSING' 
    END as status,
    COALESCE(
        (SELECT COUNT(*)::text || ' columns' 
         FROM information_schema.columns 
         WHERE table_schema = 'public' 
         AND table_name = expected_table), 
        'N/A'
    ) as columns
FROM (VALUES 
    ('user_profiles'),
    ('cards'),
    ('flashcard_sets'),
    ('flashcard_set_cards'),
    ('user_card_progress'),
    ('user_set_progress'),
    ('study_sessions'),
    ('schools'),
    ('categories'),
    ('classrooms'),
    ('study_logs'),
    ('card_interactions'),
    ('waitlist')
) AS expected(expected_table)
ORDER BY expected_table;

-- 3. DETAILED TABLE STRUCTURES FOR CRITICAL TABLES
-- user_profiles structure
SELECT 
    '📊 user_profiles Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- cards structure  
SELECT 
    '🃏 cards Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'cards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- flashcard_sets structure
SELECT 
    '📚 flashcard_sets Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'flashcard_sets' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- flashcard_set_cards structure
SELECT 
    '🔗 flashcard_set_cards Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'flashcard_set_cards' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- user_card_progress structure
SELECT 
    '📈 user_card_progress Table Structure' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_card_progress' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. RECORD COUNTS FOR ALL TABLES
WITH table_counts AS (
    SELECT 'schools' as table_name, COUNT(*) as record_count FROM schools
    UNION ALL
    SELECT 'user_profiles', COUNT(*) FROM user_profiles
    UNION ALL  
    SELECT 'categories', COUNT(*) FROM categories
    UNION ALL
    SELECT 'cards', COUNT(*) FROM cards
    UNION ALL
    SELECT 'flashcard_sets', COUNT(*) FROM flashcard_sets
    UNION ALL
    SELECT 'flashcard_set_cards', COUNT(*) FROM flashcard_set_cards
    UNION ALL
    SELECT 'study_sessions', COUNT(*) FROM study_sessions
    UNION ALL
    -- Only include if tables exist
    SELECT 'user_card_progress', 
           CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_card_progress' AND table_schema = 'public')
                THEN (SELECT COUNT(*) FROM user_card_progress)
                ELSE 0 
           END
    UNION ALL
    SELECT 'user_set_progress',
           CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_set_progress' AND table_schema = 'public')
                THEN (SELECT COUNT(*) FROM user_set_progress)
                ELSE 0 
           END
    UNION ALL
    SELECT 'classrooms',
           CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'classrooms' AND table_schema = 'public')
                THEN (SELECT COUNT(*) FROM classrooms) 
                ELSE 0
           END
)
SELECT 
    '📊 Record Counts' as info,
    table_name,
    record_count::text as count,
    CASE 
        WHEN record_count = 0 THEN '⚠️  Empty'
        WHEN record_count < 10 THEN '🔢 Few records'
        ELSE '✅ Has data'
    END as status
FROM table_counts
ORDER BY table_name;

-- 5. SAMPLE DATA FROM KEY TABLES (if they have records)
-- Sample cards
SELECT 
    '🃏 Sample Cards (first 3)' as info,
    id,
    title,
    english_title,
    category,
    difficulty_level::text as difficulty
FROM cards 
ORDER BY created_at DESC
LIMIT 3;

-- Sample flashcard sets
SELECT 
    '📚 Sample Flashcard Sets (first 3)' as info,
    id,
    title,
    description,
    language_a,
    language_b
FROM flashcard_sets 
ORDER BY created_at DESC
LIMIT 3;

-- Sample user profiles (anonymized)
SELECT 
    '👥 Sample User Profiles (first 3)' as info,
    id,
    LEFT(email, 3) || '***' || RIGHT(email, 10) as email_masked,
    user_role,
    created_at::date as created_date
FROM user_profiles 
ORDER BY created_at DESC
LIMIT 3;

-- 6. FOREIGN KEY RELATIONSHIPS
SELECT 
    '🔗 Foreign Key Relationships' as info,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 7. RLS (Row Level Security) STATUS
SELECT 
    '🔐 RLS Status' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE WHEN rowsecurity THEN '✅ Enabled' ELSE '❌ Disabled' END as status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 8. INDEXES ON TABLES
SELECT 
    '📇 Database Indexes' as info,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;