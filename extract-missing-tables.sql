-- =====================================================
-- EXTRACT MISSING TABLE STRUCTURES FROM OLD PROJECT
-- =====================================================
-- Run this SQL script in the OLD Supabase project: ycxqxdhaxehspypqbnpi.supabase.co
-- Copy the results and use them to recreate the missing tables in the new project
--
-- MISSING TABLES TO EXTRACT:
-- 1. classroom_details (11 columns)
-- 2. classroom_members (5 columns)  
-- 3. favicons (6 columns) - HAS 1 ROW OF DATA!
-- =====================================================

-- 1. GET DETAILED COLUMN STRUCTURE FOR ALL MISSING TABLES
SELECT 
    '📊 COLUMN STRUCTURES' as info,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY table_name, ordinal_position;

-- 2. GET ACTUAL DATA FROM FAVICONS TABLE (since it has 1 row)
SELECT 
    '🎨 FAVICONS DATA' as info,
    *
FROM favicons;

-- 3. GET DETAILED TABLE INFORMATION
SELECT 
    '📋 TABLE INFORMATION' as info,
    table_name,
    table_type,
    (
        SELECT COUNT(*) 
        FROM information_schema.columns 
        WHERE table_name = t.table_name 
        AND table_schema = 'public'
    ) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY table_name;

-- 4. GET PRIMARY KEYS AND CONSTRAINTS
SELECT 
    '🔑 PRIMARY KEYS AND CONSTRAINTS' as info,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY tc.table_name, tc.constraint_type;

-- 5. GET INDEXES ON THESE TABLES
SELECT 
    '📇 INDEXES' as info,
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename IN ('classroom_details', 'classroom_members', 'favicons')
ORDER BY tablename, indexname;

-- 6. GENERATE CREATE TABLE STATEMENTS (Manual Construction)
-- CLASSROOM_DETAILS
SELECT 
    '🏗️ CLASSROOM_DETAILS CREATE STATEMENT' as info,
    'CREATE TABLE IF NOT EXISTS classroom_details (' as start_statement;

SELECT 
    '  ' || column_name || ' ' ||
    CASE 
        WHEN data_type = 'character varying' THEN 
            CASE WHEN character_maximum_length IS NOT NULL 
                 THEN 'VARCHAR(' || character_maximum_length || ')'
                 ELSE 'TEXT' 
            END
        WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
        WHEN data_type = 'uuid' THEN 'UUID'
        WHEN data_type = 'boolean' THEN 'BOOLEAN'
        WHEN data_type = 'integer' THEN 'INTEGER'
        WHEN data_type = 'bigint' THEN 'BIGINT'
        WHEN data_type = 'text' THEN 'TEXT'
        WHEN data_type = 'numeric' THEN 'NUMERIC'
        WHEN data_type = 'date' THEN 'DATE'
        ELSE UPPER(data_type)
    END ||
    CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
    CASE 
        WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default 
        ELSE '' 
    END ||
    CASE 
        WHEN ordinal_position = (
            SELECT MAX(ordinal_position) 
            FROM information_schema.columns 
            WHERE table_name = 'classroom_details' 
            AND table_schema = 'public'
        ) THEN ''
        ELSE ','
    END as column_definition
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'classroom_details'
ORDER BY ordinal_position;

SELECT ');' as end_statement;

-- CLASSROOM_MEMBERS
SELECT 
    '🏗️ CLASSROOM_MEMBERS CREATE STATEMENT' as info,
    'CREATE TABLE IF NOT EXISTS classroom_members (' as start_statement;

SELECT 
    '  ' || column_name || ' ' ||
    CASE 
        WHEN data_type = 'character varying' THEN 
            CASE WHEN character_maximum_length IS NOT NULL 
                 THEN 'VARCHAR(' || character_maximum_length || ')'
                 ELSE 'TEXT' 
            END
        WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
        WHEN data_type = 'uuid' THEN 'UUID'
        WHEN data_type = 'boolean' THEN 'BOOLEAN'
        WHEN data_type = 'integer' THEN 'INTEGER'
        WHEN data_type = 'bigint' THEN 'BIGINT'
        WHEN data_type = 'text' THEN 'TEXT'
        WHEN data_type = 'numeric' THEN 'NUMERIC'
        WHEN data_type = 'date' THEN 'DATE'
        ELSE UPPER(data_type)
    END ||
    CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
    CASE 
        WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default 
        ELSE '' 
    END ||
    CASE 
        WHEN ordinal_position = (
            SELECT MAX(ordinal_position) 
            FROM information_schema.columns 
            WHERE table_name = 'classroom_members' 
            AND table_schema = 'public'
        ) THEN ''
        ELSE ','
    END as column_definition
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'classroom_members'
ORDER BY ordinal_position;

SELECT ');' as end_statement;

-- FAVICONS
SELECT 
    '🏗️ FAVICONS CREATE STATEMENT' as info,
    'CREATE TABLE IF NOT EXISTS favicons (' as start_statement;

SELECT 
    '  ' || column_name || ' ' ||
    CASE 
        WHEN data_type = 'character varying' THEN 
            CASE WHEN character_maximum_length IS NOT NULL 
                 THEN 'VARCHAR(' || character_maximum_length || ')'
                 ELSE 'TEXT' 
            END
        WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
        WHEN data_type = 'uuid' THEN 'UUID'
        WHEN data_type = 'boolean' THEN 'BOOLEAN'
        WHEN data_type = 'integer' THEN 'INTEGER'
        WHEN data_type = 'bigint' THEN 'BIGINT'
        WHEN data_type = 'text' THEN 'TEXT'
        WHEN data_type = 'numeric' THEN 'NUMERIC'
        WHEN data_type = 'date' THEN 'DATE'
        ELSE UPPER(data_type)
    END ||
    CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
    CASE 
        WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default 
        ELSE '' 
    END ||
    CASE 
        WHEN ordinal_position = (
            SELECT MAX(ordinal_position) 
            FROM information_schema.columns 
            WHERE table_name = 'favicons' 
            AND table_schema = 'public'
        ) THEN ''
        ELSE ','
    END as column_definition
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'favicons'
ORDER BY ordinal_position;

SELECT ');' as end_statement;

-- 7. GET RECORD COUNTS
SELECT 
    '📊 RECORD COUNTS' as info,
    'classroom_details' as table_name,
    (SELECT COUNT(*) FROM classroom_details) as record_count
UNION ALL
SELECT 
    'record_count' as info,
    'classroom_members' as table_name,
    (SELECT COUNT(*) FROM classroom_members) as record_count
UNION ALL
SELECT 
    'record_count' as info,
    'favicons' as table_name,
    (SELECT COUNT(*) FROM favicons) as record_count;

-- =====================================================
-- INSTRUCTIONS FOR USE:
-- =====================================================
-- 1. Copy this entire SQL script
-- 2. Go to your OLD Supabase project: ycxqxdhaxehspypqbnpi.supabase.co
-- 3. Navigate to SQL Editor
-- 4. Paste this script and run it
-- 5. Copy ALL the results
-- 6. Use the column structures and CREATE TABLE statements to recreate 
--    the missing tables in your NEW project: aeijlzokobuqcyznljvn.supabase.co
-- 7. Don't forget to copy the data from the favicons table!
-- =====================================================