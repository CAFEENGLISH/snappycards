-- EMERGENCY FIX: Create missing auth.users entries (Simplified Version)
-- Run this in Supabase SQL Editor

-- Temporarily disable RLS to work with data
ALTER TABLE IF EXISTS user_profiles DISABLE ROW LEVEL SECURITY;

-- Check current user_profiles data
SELECT 'Current user_profiles data:' as info;
SELECT id, email, first_name, last_name, user_role, created_at 
FROM user_profiles;

-- Simple auth.users creation with minimal required fields
-- User 1: zsolt.tasnadi@gmail.com
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    'af117cb0-e7b8-4f56-8e44-d8822462d95d'::uuid,
    'authenticated',
    'authenticated',
    'zsolt.tasnadi@gmail.com',
    crypt('Teaching123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"first_name":"Zsolt","last_name":"Tasnadi","user_role":"school_admin"}'::jsonb,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 2: brad.pitt.budapest@gmail.com
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    '54de9310-332d-481d-9b7e-b6cfaf0aacfa'::uuid,
    'authenticated',
    'authenticated',
    'brad.pitt.budapest@gmail.com',
    crypt('Teaching123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"first_name":"Brad","last_name":"Pitt","user_role":"teacher"}'::jsonb,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- User 3: Test user (update email first)
UPDATE user_profiles 
SET email = 'testuser@example.com'
WHERE id = '5cc03a8e-21db-496f-b482-a28634d16d65' AND email IS NULL;

INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    '5cc03a8e-21db-496f-b482-a28634d16d65'::uuid,
    'authenticated',
    'authenticated',
    'testuser@example.com',
    crypt('Teaching123', gen_salt('bf')),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"first_name":"Test","user_role":"student"}'::jsonb,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Re-enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Final verification
SELECT 'auth.users verification:' as info;
SELECT id, email, created_at, email_confirmed_at
FROM auth.users 
WHERE email IN ('zsolt.tasnadi@gmail.com', 'brad.pitt.budapest@gmail.com', 'testuser@example.com');

SELECT 'user_profiles verification:' as info;
SELECT id, email, first_name, user_role 
FROM user_profiles 
WHERE email IN ('zsolt.tasnadi@gmail.com', 'brad.pitt.budapest@gmail.com', 'testuser@example.com');

SELECT '=== AUTH USERS FIX COMPLETE (V2) ===' as result;