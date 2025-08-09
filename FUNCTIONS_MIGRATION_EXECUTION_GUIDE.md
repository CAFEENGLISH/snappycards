# Database Functions Migration Execution Guide

## Overview
This guide provides multiple methods to execute the database functions migration for the NEW SnappyCards Supabase project (`aeijlzokobuqcyznljvn - snappycards2025`).

## Functions to be Created
The migration will create 4 critical database functions:

1. **`handle_new_user()`** - Trigger function for new user creation
2. **`create_classroom()`** - Creates classroom with invite code  
3. **`generate_invite_code()`** - Generates unique classroom invite codes
4. **`join_classroom_with_code()`** - Allows students to join classrooms

## Prerequisites

### Service Role Key Required
To execute these functions, you need the **service role key** for the NEW project:

1. Go to [https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn](https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn)
2. Navigate to **Settings → API**
3. Copy the **"service_role"** key (NOT the anon key)

## Method 1: Using MCP Server (Recommended)

### Step 1: Set Environment Variables
```bash
export SUPABASE_URL="https://aeijlzokobuqcyznljvn.supabase.co"
export SUPABASE_KEY="your_service_role_key_here"
```

### Step 2: Execute Migration Script
```bash
./execute-functions-migration.sh
```

This script will:
- Execute each function individually
- Provide detailed feedback on success/failure
- Verify all functions were created
- Show a comprehensive results summary

## Method 2: Using Node.js Script

### Step 1: Install Dependencies
```bash
npm install @supabase/supabase-js
```

### Step 2: Set Environment Variable
```bash
export SUPABASE_SERVICE_KEY="your_service_role_key_here"
```

### Step 3: Execute Migration
```bash
node execute-functions-migration.js
```

## Method 3: Manual Execution via Supabase Dashboard

### Step 1: Access SQL Editor
1. Go to [https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn](https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn)
2. Navigate to **SQL Editor**

### Step 2: Execute Functions
Copy and execute the contents of `migrate-missing-functions.sql` in the SQL Editor.

## Method 4: Using psql (Alternative)

If you have PostgreSQL client installed:

```bash
# Set connection string (replace with your actual service role key)
export DATABASE_URL="postgresql://postgres.[your-ref]:[your-password]@db.aeijlzokobuqcyznljvn.supabase.co:5432/postgres"

# Execute migration
psql $DATABASE_URL -f migrate-missing-functions.sql
```

## Verification Steps

After executing the migration, verify success by running this query:

```sql
SELECT 
    routine_name as function_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('create_classroom', 'generate_invite_code', 'handle_new_user', 'join_classroom_with_code')
ORDER BY routine_name;
```

**Expected Result:** 4 functions should be returned.

## Function Details

### 1. `handle_new_user()`
- **Type:** Trigger function
- **Purpose:** Automatically creates user profile when new user registers
- **Security:** DEFINER (runs with elevated privileges)

### 2. `create_classroom(classroom_name, description)`
- **Returns:** TABLE(classroom_id uuid, invite_code text)
- **Purpose:** Creates new classroom with unique invite code
- **Security:** DEFINER, requires teacher role

### 3. `generate_invite_code(length)`
- **Returns:** TEXT
- **Purpose:** Generates random alphanumeric invite codes
- **Default length:** 6 characters

### 4. `join_classroom_with_code(code)`
- **Returns:** TABLE(success boolean, message text, classroom_name text)
- **Purpose:** Allows students to join classrooms using invite codes
- **Security:** DEFINER, requires student role

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Ensure you're using the service role key, not anon key
   - Service role key starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSI...`

2. **Function Already Exists**
   - The migration uses `CREATE OR REPLACE FUNCTION` so it's safe to re-run

3. **Missing Dependencies**
   - Ensure all required tables exist: `classrooms`, `classroom_members`, `user_profiles`
   - Run table migrations first if needed

### Getting Help

If you encounter issues:
1. Check the Supabase dashboard logs
2. Verify your service role key is correct
3. Ensure all prerequisite tables exist
4. Check that RLS policies don't block function execution

## Files Created

The following files are available for migration execution:
- `execute-functions-migration.sh` - MCP-based bash script
- `execute-functions-migration.js` - Node.js-based script  
- `migrate-missing-functions.sql` - Source SQL file with all functions

## Next Steps After Migration

1. Test function execution in your application
2. Verify trigger creation for `handle_new_user()` 
3. Test classroom creation and joining workflows
4. Monitor function performance and logs