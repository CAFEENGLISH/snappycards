# 🚨 CRITICAL: SnappyCards Authentication Fix Guide

## Problem Analysis

The error `AuthApiError: Database error querying schema` with a 500 status indicates that Supabase's authentication system cannot query the necessary database tables, specifically the `user_profiles` table that your application expects.

### Root Cause
Your application's authentication flow expects a `user_profiles` table to exist with proper RLS (Row Level Security) policies, but this table likely doesn't exist or isn't properly configured in your Supabase database.

## 🔥 IMMEDIATE FIX STEPS

### Step 1: Access Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sign in and select your project: `ycxqxdhaxehspypqbnpi`

### Step 2: Run Database Setup Script
1. Navigate to **SQL Editor** in your Supabase dashboard
2. Create a new query
3. Copy and paste the entire content from `supabase-setup.sql` file
4. Execute the script

### Step 3: Verify Table Creation
Run this query to verify tables were created:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'user_profiles', 
    'schools', 
    'flashcard_sets', 
    'cards', 
    'study_sessions'
);
```

### Step 4: Check User Profile for Test Account
Verify if the test user profile exists:
```sql
SELECT id, email, first_name, user_role, school_id 
FROM user_profiles 
WHERE email = 'vidamkos@gmail.com';
```

If no profile exists, create one manually:
```sql
-- First, find the user ID from auth.users
SELECT id, email FROM auth.users WHERE email = 'vidamkos@gmail.com';

-- Then create the profile (replace USER_ID with actual ID)
INSERT INTO user_profiles (id, email, first_name, user_role, language, country)
VALUES (
    'USER_ID_FROM_ABOVE', 
    'vidamkos@gmail.com', 
    'Admin', 
    'school_admin', 
    'hu', 
    'HU'
);
```

## 🔧 DEBUGGING STEPS

### Step 5: Test Authentication Flow
1. Open the `debug-auth.html` file I created in your project
2. Open it in a browser (you can use a local server)
3. Check the browser console for detailed error information

### Step 6: Verify RLS Policies
Check if RLS policies are working:
```sql
-- Test if user_profiles table is accessible
SELECT * FROM user_profiles LIMIT 1;

-- Check RLS policies on user_profiles
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'user_profiles';
```

### Step 7: Test Direct API Access
Test the Supabase REST API directly:
```bash
curl -X GET 'https://ycxqxdhaxehspypqbnpi.supabase.co/rest/v1/user_profiles?select=*&limit=1' \
  -H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g'
```

## 🎯 SPECIFIC AUTHENTICATION ISSUES

### Issue 1: Missing user_profiles Table
**Symptom**: "Database error querying schema"
**Fix**: Run the `supabase-setup.sql` script

### Issue 2: RLS Policies Too Restrictive
**Symptom**: Authentication works but profile fetch fails
**Fix**: The RLS policies in the setup script allow:
- Users to read their own profiles
- Users to create their own profiles during signup
- School admins to read profiles in their school

### Issue 3: Missing Trigger for Auto Profile Creation
**Symptom**: Login works but no profile is created
**Fix**: The setup script includes a trigger that automatically creates a user profile when a user signs up

### Issue 4: Email/Password Combination Issues
**Symptom**: "Invalid email or password"
**Possible causes**:
- User doesn't exist in auth.users table
- Password is incorrect
- Email confirmation required but not completed

## 🔍 VERIFICATION CHECKLIST

After running the setup script, verify:

- [ ] `user_profiles` table exists
- [ ] RLS is enabled on `user_profiles`
- [ ] RLS policies allow authenticated users to read their own profiles
- [ ] Trigger exists to auto-create profiles on user signup
- [ ] Test user profile exists for `vidamkos@gmail.com`
- [ ] Authentication endpoint returns proper user data
- [ ] Login redirects to correct dashboard based on user role

## 🚀 TESTING THE FIX

1. **Test login** with `vidamkos@gmail.com` / `Palacs1nta`
2. **Check browser console** for any remaining errors
3. **Verify redirect** to appropriate dashboard based on user role
4. **Test new user registration** to ensure profiles are auto-created

## 📊 MONITORING

After the fix, monitor:
- Authentication success rates
- Profile creation success
- Database query performance
- Any remaining 500 errors

## 🔒 SECURITY CONSIDERATIONS

The setup script implements proper security:
- RLS policies restrict data access based on user roles
- School admins can only see their school's data
- Users can only access their own profiles
- Proper indexing for performance
- Triggers for data consistency

## 📞 SUPPORT

If issues persist after following this guide:
1. Check Supabase logs in the dashboard
2. Verify all environment variables are correct
3. Test with a new user registration
4. Check network connectivity to Supabase endpoints

---

**Expected Result**: After running the setup script, the authentication error should be resolved and users should be able to log in successfully with proper role-based dashboard redirects.