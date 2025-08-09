# 🎯 MASTER MIGRATION EXECUTION GUIDE

**Generated:** ${new Date().toISOString()}
**Source Project:** ycxqxdhaxehspypqbnpi.supabase.co (OLD - has data, auth crashed)
**Target Project:** aeijlzokobuqcyznljvn.supabase.co (NEW - clean auth, minimal data)

## 📊 CURRENT STATUS (Verification Results: 6/19 - 32% Complete)

### ✅ COMPLETED COMPONENTS
- **Tables Structure**: All critical tables exist ✅
- **Core Data**: User profiles, schools, favicons synchronized ✅

### ❌ MISSING COMPONENTS (CRITICAL - System Will Not Work Without These)
- **Functions**: 0/4 custom functions migrated ❌
- **Triggers**: 0/2 critical triggers migrated ❌  
- **RLS Policies**: 0/44 security policies migrated ❌
- **Storage**: 0/1 bucket + 0/44 objects migrated ❌

---

## 🚀 EXECUTION PLAN (Execute in This Exact Order)

### PHASE 1: Database Functions (CRITICAL)
```bash
# Execute the functions migration
node migrate-missing-functions.js

# Or manually apply the SQL file:
# Apply: migrate-missing-functions.sql to NEW project
```

**Required Functions:**
- `handle_new_user` - Creates user profile on signup
- `create_classroom` - Classroom management
- `generate_invite_code` - Classroom invites  
- `join_classroom_with_code` - Student enrollment

### PHASE 2: Database Triggers (CRITICAL)
```bash
# Execute the triggers migration
node migrate-missing-triggers.js

# Or manually apply the SQL file:
# Apply: migrate-missing-triggers.sql to NEW project
```

**Required Triggers:**
- `on_auth_user_created` on users table - Auto-creates profiles
- `update_user_profiles_updated_at` on user_profiles - Timestamp management

### PHASE 3: RLS Policies (CRITICAL - SECURITY)
```bash
# Execute RLS policies migration
node migrate-all-rls-policies.js

# Or manually apply the SQL file:
# Apply: migrate-all-rls-policies.sql to NEW project
```

**Critical for Security:** All 44 RLS policies must be recreated or users won't be able to access their data.

### PHASE 4: Storage Migration (HIGH PRIORITY)
```bash
# Execute storage migration
node migrate-storage-data.js

# Then manually copy files:
# 1. Apply migrate-storage-data.sql to create bucket + metadata
# 2. Use Supabase CLI or API to copy actual files from OLD to NEW
```

**Storage Components:**
- 1 storage bucket: `media`
- 44 storage objects (user uploads, images, etc.)

### PHASE 5: Verification (MANDATORY)
```bash
# Verify migration completeness
node complete-migration-verification.js

# Check that score is > 85% before proceeding
```

---

## 🛠️ QUICK MIGRATION SCRIPTS

### Option A: Individual Script Execution
```bash
# 1. Functions
node extract-missing-functions.js
# Apply migrate-missing-functions.sql to NEW project

# 2. Triggers  
node extract-missing-triggers.js
# Apply migrate-missing-triggers.sql to NEW project

# 3. RLS Policies
node extract-missing-rls-policies.js
# Apply migrate-all-rls-policies.sql to NEW project

# 4. Storage
node migrate-storage-data.js
# Apply migrate-storage-data.sql to NEW project + copy files

# 5. Verify
node complete-migration-verification.js
```

### Option B: All-in-One SQL Execution
**Create a master SQL file combining all migrations:**

```sql
-- MASTER MIGRATION SCRIPT
-- Execute this entire file on NEW project: aeijlzokobuqcyznljvn

-- PHASE 1: Functions
-- (Contents of migrate-missing-functions.sql)

-- PHASE 2: Triggers  
-- (Contents of migrate-missing-triggers.sql)

-- PHASE 3: RLS Policies
-- (Contents of migrate-all-rls-policies.sql)

-- PHASE 4: Storage
-- (Contents of migrate-storage-data.sql)
```

---

## 📋 MIGRATION CHECKLIST

### Pre-Migration Checklist
- [ ] Backup NEW project (just in case)
- [ ] Verify OLD project access token is working
- [ ] Confirm NEW project database connection
- [ ] Review all generated SQL files for accuracy

### Migration Execution Checklist
- [ ] **Phase 1**: Execute functions migration ✅/❌
- [ ] **Phase 2**: Execute triggers migration ✅/❌
- [ ] **Phase 3**: Execute RLS policies migration ✅/❌
- [ ] **Phase 4**: Execute storage migration ✅/❌
- [ ] **Phase 5**: Run verification (target: >85%) ✅/❌

### Post-Migration Checklist
- [ ] Run verification script (should show 95%+ completion)
- [ ] Test user login/registration flow
- [ ] Test flashcard creation and study
- [ ] Test file uploads and media access
- [ ] Test classroom functionality
- [ ] Update application config to use NEW project
- [ ] Monitor for any errors in production

---

## 🚨 CRITICAL WARNINGS

### ⚠️ SECURITY WARNING
**The NEW project currently has NO RLS policies on critical tables!**
- Users can access all data from all users
- No permission controls are active
- **NEVER go to production without RLS policies**

### ⚠️ FUNCTIONALITY WARNINGS
Without the missing components:
- **New user registration will fail** (missing handle_new_user function)
- **Profile updates won't timestamp** (missing trigger)  
- **Classroom features won't work** (missing functions)
- **File uploads will fail** (missing storage bucket)

### ⚠️ DATA INTEGRITY WARNINGS
- Some tables show MORE data in NEW than OLD (flashcard_sets, cards)
- This indicates test data was added to NEW - verify this is intentional
- OLD project auth is crashed - user sessions/tokens can't be verified

---

## 🎯 SUCCESS CRITERIA

### Minimum Requirements (85% verification score)
- [x] All critical tables exist and have correct data
- [ ] All 4 custom functions created  
- [ ] Both critical triggers created
- [ ] At least 35+ RLS policies created (80% of 44)
- [ ] Storage bucket created (file copying can be done later)

### Ideal Requirements (95% verification score)
- [x] All critical tables synchronized
- [ ] All 4 custom functions working
- [ ] Both triggers active  
- [ ] All 44 RLS policies active
- [ ] Storage bucket + all 44 objects migrated

### Production Ready (100% verification score)
- [x] Perfect data synchronization
- [ ] All functions, triggers, policies active
- [ ] All storage completely migrated
- [ ] Application tested and working
- [ ] Monitoring active

---

## 📞 EMERGENCY PROCEDURES

### If Migration Fails:
1. **DO NOT PANIC** - OLD project data is safe
2. Check error logs from failed script
3. Restore NEW project from backup if needed
4. Fix the specific issue and retry
5. Re-run verification after each fix

### If Application Breaks:
1. Immediately revert config to OLD project (even with auth issues)
2. Fix the NEW project migration issues
3. Re-run complete verification  
4. Only switch back when verification shows >95%

### If Data is Lost:
1. OLD project still contains all original data
2. Re-run the complete audit to verify data integrity
3. Re-extract and re-migrate any missing components
4. Never delete OLD project until NEW is 100% verified in production

---

## 🚀 READY TO EXECUTE?

**Your migration scripts are ready:**
- ✅ `complete-migration-audit.js` - Complete audit (DONE)
- ✅ `extract-missing-functions.js` + `migrate-missing-functions.sql`
- ✅ `extract-missing-triggers.js` + `migrate-missing-triggers.sql`  
- ✅ `extract-missing-rls-policies.js` + `migrate-all-rls-policies.sql`
- ✅ `migrate-storage-data.js` + `migrate-storage-data.sql`
- ✅ `complete-migration-verification.js` - Final verification

**Execute phases 1-4, then run verification. Target: 95%+ completion for production readiness.**