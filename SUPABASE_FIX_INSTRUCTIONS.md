# 🚨 CRITICAL: Supabase Authentication Fix Instructions

## Issue Summary
The authentication fails with **"Database error querying schema"** (error code 500) because the Supabase database is missing the required `user_profiles` table setup or the user profile record.

## Direct Test Results
✅ REST API is healthy  
✅ user_profiles table exists  
✅ All required tables exist  
❌ **Authentication fails with schema error**  

## IMMEDIATE FIX STEPS

### Step 1: Access Supabase Dashboard
1. Go to: https://supabase.com/dashboard/project/ycxqxdhaxehspypqbnpi
2. Navigate to **SQL Editor**

### Step 2: Execute Emergency Fix
Copy and paste the entire content from `emergency-auth-fix.sql` into the SQL Editor and execute it.

### Step 3: Verify User Registration
Check if the user `vidamkos@gmail.com` exists in the auth system:
```sql
SELECT id, email, email_confirmed_at FROM auth.users WHERE email = 'vidamkos@gmail.com';
```

If the user doesn't exist, you need to register first:
- Use the registration form in your app, OR
- Use Supabase Auth UI, OR  
- Create via SQL (not recommended)

### Step 4: Test Authentication
After running the fix, test with:
```bash
cd /path/to/snappycards
./test-supabase-direct.sh
```

Or open `debug-auth.html` in a browser.

## What the Fix Does

1. **Checks existing data** and reports status
2. **Temporarily disables RLS** for debugging
3. **Creates user profile** if missing
4. **Re-enables RLS** with proper policies
5. **Grants necessary permissions**

## Expected Result
After the fix:
- ✅ Authentication with `vidamkos@gmail.com` / `Palacs1nta` should work
- ✅ User profile should be accessible
- ✅ Login should redirect to appropriate dashboard

## If Issues Persist

### Option 1: Full Database Reset
Execute the complete `supabase-setup.sql` script in SQL Editor.

### Option 2: Check Auth User
Verify the user exists and is confirmed:
```sql
SELECT * FROM auth.users WHERE email = 'vidamkos@gmail.com';
```

### Option 3: Manual Profile Creation
If you know the user's UUID:
```sql
INSERT INTO user_profiles (id, email, first_name, user_role, language, country)
VALUES ('YOUR_USER_UUID', 'vidamkos@gmail.com', 'Vidam', 'student', 'hu', 'HU');
```

## Security Note
The emergency fix temporarily disables RLS for debugging. It re-enables RLS with proper policies at the end.

## Files Created for Testing
- `test-supabase-direct.sh` - Direct API testing
- `emergency-auth-fix.sql` - Quick fix SQL script
- Existing: `debug-auth.html` - Browser-based testing
- Existing: `test-auth-fix.js` - Comprehensive test suite

## Next Steps After Fix
1. Test login via your app
2. Verify dashboard redirects work correctly
3. Test new user registration
4. Monitor for any remaining authentication errors

---

**⚠️ IMPORTANT**: I don't have access to Supabase MCP tools, so these manual steps through the Supabase Dashboard are required to fix the authentication issue.