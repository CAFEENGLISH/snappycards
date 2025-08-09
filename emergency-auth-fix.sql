-- EMERGENCY AUTH FIX for SnappyCards
-- Copy and paste this entire script into Supabase SQL Editor

-- First, check if the user exists in auth.users
DO $$
BEGIN
    RAISE NOTICE '=== SUPABASE AUTH FIX FOR VIDAMKOS@GMAIL.COM ===';
    
    -- Check auth.users
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = 'vidamkos@gmail.com') THEN
        RAISE NOTICE '✅ User exists in auth.users table';
    ELSE
        RAISE NOTICE '❌ User does NOT exist in auth.users table - register first!';
    END IF;
    
    -- Check user_profiles table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles') THEN
        RAISE NOTICE '✅ user_profiles table exists';
    ELSE
        RAISE NOTICE '❌ user_profiles table does NOT exist - run full setup script!';
    END IF;
    
END $$;

-- Temporarily disable RLS to check data
ALTER TABLE IF EXISTS user_profiles DISABLE ROW LEVEL SECURITY;

-- Check current user_profiles data
SELECT 'Current user_profiles data:' as info;
SELECT id, email, first_name, user_role, created_at 
FROM user_profiles 
WHERE email = 'vidamkos@gmail.com';

-- Insert user profile if missing (using known UUID or finding from auth.users)
INSERT INTO user_profiles (id, email, first_name, user_role, language, country, is_mock)
SELECT 
    au.id,
    'vidamkos@gmail.com',
    'Vidam',
    'student',
    'hu',
    'HU',
    false
FROM auth.users au
WHERE au.email = 'vidamkos@gmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM user_profiles up 
    WHERE up.id = au.id
  );

-- Alternative: Insert with known UUID (if you know it)
-- INSERT INTO user_profiles (id, email, first_name, user_role, language, country, is_mock)
-- VALUES (
--     '9802312d-e7ce-4005-994b-ee9437fb5326',
--     'vidamkos@gmail.com',
--     'Vidam', 
--     'student',
--     'hu',
--     'HU',
--     false
-- ) ON CONFLICT (id) DO NOTHING;

-- Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Ensure RLS policies exist
CREATE POLICY IF NOT EXISTS "Users can read own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Verify the fix
SELECT 'Final verification - user_profiles:' as info;
SELECT id, email, first_name, user_role 
FROM user_profiles 
WHERE email = 'vidamkos@gmail.com';

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON user_profiles TO authenticated;

SELECT '=== FIX COMPLETE - Test authentication now ===' as result;