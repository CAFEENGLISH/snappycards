-- SUPABASE MIGRATION VERIFICATION SCRIPT
-- Run these queries after each migration step to verify success

-- ============================================
-- STEP 1: VERIFY FUNCTIONS
-- ============================================
-- Run after migrate-missing-functions.sql

SELECT 
  'FUNCTIONS CHECK' as check_type,
  proname as function_name,
  'FOUND' as status
FROM pg_proc 
WHERE proname IN (
  'handle_new_user', 
  'update_updated_at_column', 
  'create_classroom', 
  'generate_invite_code', 
  'join_classroom_with_code'
)
ORDER BY proname;

-- Should return 5 rows if all functions created successfully

-- ============================================
-- STEP 2: VERIFY TRIGGERS  
-- ============================================
-- Run after migrate-missing-triggers.sql

SELECT 
  'TRIGGERS CHECK' as check_type,
  t.tgname as trigger_name,
  c.relname as table_name,
  'FOUND' as status
FROM pg_trigger t 
JOIN pg_class c ON t.tgrelid = c.oid 
WHERE t.tgname IN ('on_auth_user_created', 'update_user_profiles_updated_at')
ORDER BY t.tgname;

-- Should return 2 rows if all triggers created successfully

-- ============================================
-- STEP 3: VERIFY RLS POLICIES
-- ============================================
-- Run after migrate-all-rls-policies.sql

-- Count total policies
SELECT 
  'RLS POLICIES COUNT' as check_type,
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) >= 44 THEN 'SUCCESS' 
    ELSE 'MISSING POLICIES' 
  END as status
FROM pg_policies 
WHERE schemaname IN ('public', 'auth', 'storage');

-- Detailed breakdown by schema and table
SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname IN ('public', 'auth', 'storage')
GROUP BY schemaname, tablename 
ORDER BY schemaname, tablename;

-- Check if RLS is enabled on all tables
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as status
FROM pg_tables 
WHERE schemaname IN ('public', 'auth', 'storage')
ORDER BY schemaname, tablename;

-- ============================================
-- STEP 4: VERIFY STORAGE
-- ============================================
-- Run after migrate-storage-data.sql

-- Check buckets
SELECT 
  'STORAGE BUCKETS' as check_type,
  name as bucket_name,
  public as is_public,
  CASE WHEN name = 'media' THEN 'SUCCESS' ELSE 'CHECK NEEDED' END as status
FROM storage.buckets
ORDER BY name;

-- Check objects count
SELECT 
  'STORAGE OBJECTS' as check_type,
  b.name as bucket_name,
  COUNT(o.id) as object_count,
  CASE 
    WHEN b.name = 'media' AND COUNT(o.id) = 44 THEN 'SUCCESS'
    WHEN b.name = 'media' AND COUNT(o.id) > 0 THEN 'PARTIAL'
    ELSE 'CHECK NEEDED'
  END as status
FROM storage.buckets b
LEFT JOIN storage.objects o ON b.id = o.bucket_id
GROUP BY b.name
ORDER BY b.name;

-- ============================================
-- OVERALL HEALTH CHECK
-- ============================================
-- Run this after all migrations complete

-- Critical functions exist
WITH function_check AS (
  SELECT COUNT(*) as count FROM pg_proc 
  WHERE proname IN ('handle_new_user', 'create_classroom', 'join_classroom_with_code')
),
-- Critical triggers exist  
trigger_check AS (
  SELECT COUNT(*) as count FROM pg_trigger 
  WHERE tgname IN ('on_auth_user_created', 'update_user_profiles_updated_at')
),
-- Sufficient policies exist
policy_check AS (
  SELECT COUNT(*) as count FROM pg_policies 
  WHERE schemaname IN ('public', 'auth', 'storage')
),
-- Storage bucket exists
storage_check AS (
  SELECT COUNT(*) as count FROM storage.buckets WHERE name = 'media'
)
SELECT 
  'MIGRATION HEALTH CHECK' as check_type,
  CASE 
    WHEN f.count >= 3 AND t.count >= 2 AND p.count >= 40 AND s.count >= 1 
    THEN '✅ MIGRATION SUCCESSFUL - System should be functional'
    ELSE '❌ MIGRATION INCOMPLETE - Check individual steps'
  END as overall_status,
  f.count as functions_found,
  t.count as triggers_found,
  p.count as policies_found,
  s.count as storage_buckets_found
FROM function_check f, trigger_check t, policy_check p, storage_check s;

-- ============================================
-- TROUBLESHOOTING QUERIES
-- ============================================

-- If functions are missing:
-- SELECT proname FROM pg_proc WHERE proowner = (SELECT usesysid FROM pg_user WHERE usename = current_user);

-- If triggers are missing:
-- SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('auth', 'public');

-- If policies are missing:
-- SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname IN ('public', 'auth', 'storage');

-- If storage is missing:
-- SELECT * FROM storage.buckets;