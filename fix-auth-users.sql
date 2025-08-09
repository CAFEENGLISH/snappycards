-- SnappyCards Authentication Fix
-- This script creates missing auth.users entries for existing user_profiles
-- Execute this in Supabase SQL Editor

DO $$
BEGIN
    RAISE NOTICE '=== SNAPPYCARDS AUTHENTICATION FIX ===';
    RAISE NOTICE 'Creating missing auth.users entries...';
    
    -- First, let's check what we're working with
    RAISE NOTICE 'Current user_profiles count: %', (SELECT COUNT(*) FROM user_profiles);
    RAISE NOTICE 'Current auth.users count: %', (SELECT COUNT(*) FROM auth.users);
END $$;

-- Create the missing auth.users entries
-- Note: We need to be very careful with the auth schema
-- These users exist in user_profiles but not in auth.users

-- User 1: zsolt.tasnadi@gmail.com (school_admin)
INSERT INTO auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change,
    phone_change_token,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_change_sent_at,
    email_change_sent_at,
    email_change_token_current_deadline,
    email_change_token_new_deadline,
    recovery_sent_at,
    invited_at,
    action_link,
    email_action_link,
    is_sso_user,
    deleted_at,
    is_anonymous
) VALUES (
    'af117cb0-e7b8-4f56-8e44-d8822462d95d',  -- Exact UUID from user_profiles
    'authenticated',
    'authenticated',
    'zsolt.tasnadi@gmail.com',
    crypt('Teaching123', gen_salt('bf')),  -- Password: Teaching123
    NOW(),  -- email_confirmed_at
    NULL,   -- phone_confirmed_at
    '',     -- confirmation_token
    '',     -- recovery_token
    '',     -- email_change_token_new
    '',     -- email_change
    '',     -- phone_change
    '',     -- phone_change_token
    '',     -- email_change_token_current
    0,      -- email_change_confirm_status
    NULL,   -- banned_until
    '{"provider": "email", "providers": ["email"]}',  -- raw_app_meta_data
    '{"first_name": "Zsolt", "user_role": "school_admin"}',  -- raw_user_meta_data
    false,  -- is_super_admin
    NOW(),  -- created_at
    NOW(),  -- updated_at
    NULL,   -- phone
    NULL,   -- phone_change_sent_at
    NULL,   -- email_change_sent_at
    NULL,   -- email_change_token_current_deadline
    NULL,   -- email_change_token_new_deadline
    NULL,   -- recovery_sent_at
    NULL,   -- invited_at
    NULL,   -- action_link
    NULL,   -- email_action_link
    false,  -- is_sso_user
    NULL,   -- deleted_at
    false   -- is_anonymous
) ON CONFLICT (id) DO NOTHING;

-- User 2: brad.pitt.budapest@gmail.com (teacher)
INSERT INTO auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change,
    phone_change_token,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_change_sent_at,
    email_change_sent_at,
    email_change_token_current_deadline,
    email_change_token_new_deadline,
    recovery_sent_at,
    invited_at,
    action_link,
    email_action_link,
    is_sso_user,
    deleted_at,
    is_anonymous
) VALUES (
    '54de9310-332d-481d-9b7e-b6cfaf0aacfa',  -- Exact UUID from user_profiles
    'authenticated',
    'authenticated',
    'brad.pitt.budapest@gmail.com',
    crypt('Teaching123', gen_salt('bf')),  -- Password: Teaching123
    NOW(),  -- email_confirmed_at
    NULL,   -- phone_confirmed_at
    '',     -- confirmation_token
    '',     -- recovery_token
    '',     -- email_change_token_new
    '',     -- email_change
    '',     -- phone_change
    '',     -- phone_change_token
    '',     -- email_change_token_current
    0,      -- email_change_confirm_status
    NULL,   -- banned_until
    '{"provider": "email", "providers": ["email"]}',  -- raw_app_meta_data
    '{"first_name": "Brad", "user_role": "teacher"}',  -- raw_user_meta_data
    false,  -- is_super_admin
    NOW(),  -- created_at
    NOW(),  -- updated_at
    NULL,   -- phone
    NULL,   -- phone_change_sent_at
    NULL,   -- email_change_sent_at
    NULL,   -- email_change_token_current_deadline
    NULL,   -- email_change_token_new_deadline
    NULL,   -- recovery_sent_at
    NULL,   -- invited_at
    NULL,   -- action_link
    NULL,   -- email_action_link
    false,  -- is_sso_user
    NULL,   -- deleted_at
    false   -- is_anonymous
) ON CONFLICT (id) DO NOTHING;

-- User 3: Test student (no email in user_profiles, so we'll use the UUID as identifier)
INSERT INTO auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    phone_confirmed_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change,
    phone_change_token,
    email_change_token_current,
    email_change_confirm_status,
    banned_until,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at,
    phone,
    phone_change_sent_at,
    email_change_sent_at,
    email_change_token_current_deadline,
    email_change_token_new_deadline,
    recovery_sent_at,
    invited_at,
    action_link,
    email_action_link,
    is_sso_user,
    deleted_at,
    is_anonymous
) VALUES (
    '5cc03a8e-21db-496f-b482-a28634d16d65',  -- Exact UUID from user_profiles
    'authenticated',
    'authenticated',
    'testuser@example.com',  -- Since no email in user_profiles, using a placeholder
    crypt('Teaching123', gen_salt('bf')),  -- Password: Teaching123
    NOW(),  -- email_confirmed_at
    NULL,   -- phone_confirmed_at
    '',     -- confirmation_token
    '',     -- recovery_token
    '',     -- email_change_token_new
    '',     -- email_change
    '',     -- phone_change
    '',     -- phone_change_token
    '',     -- email_change_token_current
    0,      -- email_change_confirm_status
    NULL,   -- banned_until
    '{"provider": "email", "providers": ["email"]}',  -- raw_app_meta_data
    '{"first_name": "Test", "user_role": "student"}',  -- raw_user_meta_data
    false,  -- is_super_admin
    NOW(),  -- created_at
    NOW(),  -- updated_at
    NULL,   -- phone
    NULL,   -- phone_change_sent_at
    NULL,   -- email_change_sent_at
    NULL,   -- email_change_token_current_deadline
    NULL,   -- email_change_token_new_deadline
    NULL,   -- recovery_sent_at
    NULL,   -- invited_at
    NULL,   -- action_link
    NULL,   -- email_action_link
    false,  -- is_sso_user
    NULL,   -- deleted_at
    false   -- is_anonymous
) ON CONFLICT (id) DO NOTHING;

-- Update the test user's email in user_profiles to match auth.users
UPDATE user_profiles 
SET email = 'testuser@example.com' 
WHERE id = '5cc03a8e-21db-496f-b482-a28634d16d65' 
AND (email IS NULL OR email = '');

-- Verification queries
DO $$
BEGIN
    RAISE NOTICE '=== VERIFICATION ===';
    RAISE NOTICE 'auth.users count after fix: %', (SELECT COUNT(*) FROM auth.users);
    RAISE NOTICE 'user_profiles count: %', (SELECT COUNT(*) FROM user_profiles);
    
    -- Check specific users
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = 'af117cb0-e7b8-4f56-8e44-d8822462d95d') THEN
        RAISE NOTICE '✅ zsolt.tasnadi@gmail.com exists in auth.users';
    ELSE
        RAISE NOTICE '❌ zsolt.tasnadi@gmail.com missing from auth.users';
    END IF;
    
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = '54de9310-332d-481d-9b7e-b6cfaf0aacfa') THEN
        RAISE NOTICE '✅ brad.pitt.budapest@gmail.com exists in auth.users';
    ELSE
        RAISE NOTICE '❌ brad.pitt.budapest@gmail.com missing from auth.users';
    END IF;
    
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = '5cc03a8e-21db-496f-b482-a28634d16d65') THEN
        RAISE NOTICE '✅ Test user exists in auth.users';
    ELSE
        RAISE NOTICE '❌ Test user missing from auth.users';
    END IF;
    
    RAISE NOTICE '=== FIX COMPLETE ===';
END $$;

-- Show the synchronized data
SELECT 'auth.users entries:' as table_name;
SELECT id, email, created_at, email_confirmed_at IS NOT NULL as email_confirmed
FROM auth.users 
WHERE id IN (
    'af117cb0-e7b8-4f56-8e44-d8822462d95d',
    '54de9310-332d-481d-9b7e-b6cfaf0aacfa', 
    '5cc03a8e-21db-496f-b482-a28634d16d65'
);

SELECT 'user_profiles entries:' as table_name;
SELECT id, email, first_name, user_role, created_at
FROM user_profiles 
WHERE id IN (
    'af117cb0-e7b8-4f56-8e44-d8822462d95d',
    '54de9310-332d-481d-9b7e-b6cfaf0aacfa', 
    '5cc03a8e-21db-496f-b482-a28634d16d65'
);

-- Test authentication queries (informational - doesn't actually test login)
SELECT '=== Authentication Test Info ===' as info;
SELECT 
    'You can now test login with these credentials:' as message,
    email as login_email,
    'Teaching123' as password,
    user_role
FROM user_profiles up
JOIN auth.users au ON up.id = au.id
WHERE up.id IN (
    'af117cb0-e7b8-4f56-8e44-d8822462d95d',
    '54de9310-332d-481d-9b7e-b6cfaf0aacfa', 
    '5cc03a8e-21db-496f-b482-a28634d16d65'
);