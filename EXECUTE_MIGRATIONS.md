# CRITICAL SUPABASE MIGRATION EXECUTION GUIDE

## Target Project: aeijlzokobuqcyznljvn.supabase.co

**⚠️ EXECUTE IN THIS EXACT ORDER - DEPENDENCIES REQUIRED**

## Step 1: FUNCTIONS FIRST (Dependencies required)

**File:** `migrate-missing-functions.sql`

**Critical Functions:**
- `handle_new_user()` - Auto-creates user profiles on signup
- `update_updated_at_column()` - Timestamp trigger function  
- `create_classroom()` - Teacher classroom creation
- `generate_invite_code()` - Unique invite code generation
- `join_classroom_with_code()` - Student classroom joining

**Execute via:**
```sql
-- Copy and paste the entire content of migrate-missing-functions.sql
-- into your Supabase SQL editor and execute
```

## Step 2: TRIGGERS SECOND (Depend on functions)

**File:** `migrate-missing-triggers.sql`

**Critical Triggers:**
- `on_auth_user_created` - Creates user profile on auth.users INSERT
- `update_user_profiles_updated_at` - Updates timestamp on profile changes

**Execute via:**
```sql
-- Copy and paste the entire content of migrate-missing-triggers.sql
-- into your Supabase SQL editor and execute
```

## Step 3: RLS POLICIES THIRD (CRITICAL - Security)

**File:** `migrate-all-rls-policies.sql`

**Critical Policies (44 total):**
- auth.users, auth.sessions, auth.identities - Auth access
- public.user_profiles - User profile management
- public.classrooms, classroom_members - Classroom security
- public.flashcard_sets, cards - Content security
- storage.objects - File upload security

**Execute via:**
```sql
-- Copy and paste the entire content of migrate-all-rls-policies.sql  
-- into your Supabase SQL editor and execute
```

## Step 4: STORAGE LAST (Optional but important)

**File:** `migrate-storage-data.sql`

**Storage Components:**
- media bucket creation
- 44 file metadata records
- Note: Actual file data needs separate copying

**Execute via:**
```sql
-- Copy and paste the entire content of migrate-storage-data.sql
-- into your Supabase SQL editor and execute
```

## VERIFICATION COMMANDS

After each step, run these verification queries:

### After Functions:
```sql
SELECT proname FROM pg_proc WHERE proname IN (
  'handle_new_user', 'update_updated_at_column', 
  'create_classroom', 'generate_invite_code', 'join_classroom_with_code'
);
```

### After Triggers:
```sql
SELECT tgname, relname 
FROM pg_trigger t 
JOIN pg_class c ON t.tgrelid = c.oid 
WHERE tgname IN ('on_auth_user_created', 'update_user_profiles_updated_at');
```

### After RLS Policies:
```sql
SELECT COUNT(*) as total_policies 
FROM pg_policies 
WHERE schemaname IN ('public', 'auth', 'storage');
-- Should return 44 or more
```

### After Storage:
```sql
SELECT name, public FROM storage.buckets;
-- Should show 'media' bucket

SELECT COUNT(*) FROM storage.objects WHERE bucket_id = 'media';
-- Should show 44 objects
```

## CRITICAL NOTES

1. **ORDER MATTERS** - Functions must be created before triggers that use them
2. **RLS is CRITICAL** - Without proper policies, the app will be non-functional or insecure  
3. **Stop on ANY Error** - If any step fails, investigate before proceeding
4. **Storage Files** - SQL only creates metadata; actual files need separate copying
5. **Backup First** - Consider backing up your new project before migration

## EXECUTION METHOD

**Recommended:** Use Supabase Dashboard SQL Editor
1. Go to https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn/sql
2. Copy-paste each migration file content
3. Execute one at a time
4. Verify results with verification queries
5. Only proceed to next step if current step succeeds

**Alternative:** Use Supabase CLI if available
```bash
supabase db reset --project-ref aeijlzokobuqcyznljvn
# Then run each migration file
```

## FILE LOCATIONS

All migration files are in the project root:
- `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-missing-functions.sql`
- `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-missing-triggers.sql`  
- `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-all-rls-policies.sql`
- `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-storage-data.sql`

Execute NOW to restore system functionality! 🚀