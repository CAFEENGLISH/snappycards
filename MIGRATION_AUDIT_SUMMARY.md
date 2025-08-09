# COMPLETE MIGRATION AUDIT REPORT
Generated: 2025-08-07T21:41:59.975Z

## PROJECT INFORMATION
OLD PROJECT: ycxqxdhaxehspypqbnpi (ycxqxdhaxehspypqbnpi.supabase.co)
NEW PROJECT: aeijlzokobuqcyznljvn (aeijlzokobuqcyznljvn.supabase.co)

## SUMMARY STATISTICS
Tables: 42 (OLD) → 45 (NEW)
Functions: 19 (OLD) → 29 (NEW) | Missing: 4
Triggers: 4 (OLD) → 14 (NEW) | Missing: 2
RLS Policies: 44 (OLD) → 41 (NEW) | Missing: 44

## MIGRATION PRIORITIES

### CRITICAL PRIORITY (44 items)
- **auth_identities_access_policy**: RLS policy missing on identities
  Action: Create security policy

- **auth_refresh_tokens_access_policy**: RLS policy missing on refresh_tokens
  Action: Create security policy

- **auth_sessions_access_policy**: RLS policy missing on sessions
  Action: Create security policy

- **auth_users_access_policy**: RLS policy missing on users
  Action: Create security policy

- **card_categories_delete_policy**: RLS policy missing on card_categories
  Action: Create security policy

- **card_categories_insert_policy**: RLS policy missing on card_categories
  Action: Create security policy

- **card_categories_select_policy**: RLS policy missing on card_categories
  Action: Create security policy

- **card_categories_update_policy**: RLS policy missing on card_categories
  Action: Create security policy

- **Anyone can create cards**: RLS policy missing on cards
  Action: Create security policy

- **Anyone can delete cards**: RLS policy missing on cards
  Action: Create security policy

- **Anyone can read cards**: RLS policy missing on cards
  Action: Create security policy

- **Anyone can update cards**: RLS policy missing on cards
  Action: Create security policy

- **Authenticated users can insert categories**: RLS policy missing on categories
  Action: Create security policy

- **Everyone can view categories**: RLS policy missing on categories
  Action: Create security policy

- **Students can join classrooms**: RLS policy missing on classroom_members
  Action: Create security policy

- **Students can leave classrooms**: RLS policy missing on classroom_members
  Action: Create security policy

- **Teachers can view their classroom members**: RLS policy missing on classroom_members
  Action: Create security policy

- **Classroom members can view classroom sets**: RLS policy missing on classroom_sets
  Action: Create security policy

- **Teachers can manage their classroom sets**: RLS policy missing on classroom_sets
  Action: Create security policy

- **Enable read access for all users**: RLS policy missing on classrooms
  Action: Create security policy

- **Users can manage cards in their own sets**: RLS policy missing on flashcard_set_cards
  Action: Create security policy

- **Users can manage categories for their own sets**: RLS policy missing on flashcard_set_categories
  Action: Create security policy

- **Users can create their own flashcard sets**: RLS policy missing on flashcard_sets
  Action: Create security policy

- **Users can delete their own flashcard sets**: RLS policy missing on flashcard_sets
  Action: Create security policy

- **Users can read their own flashcard sets**: RLS policy missing on flashcard_sets
  Action: Create security policy

- **Users can update their own flashcard sets**: RLS policy missing on flashcard_sets
  Action: Create security policy

- **Enable insert for authenticated users**: RLS policy missing on schools
  Action: Create security policy

- **Enable read access for authenticated users**: RLS policy missing on schools
  Action: Create security policy

- **Enable update for authenticated users**: RLS policy missing on schools
  Action: Create security policy

- **Users can view and create their own study logs**: RLS policy missing on study_logs
  Action: Create security policy

- **Users can manage their own progress**: RLS policy missing on user_card_progress
  Action: Create security policy

- **Anyone can insert profile on signup**: RLS policy missing on user_profiles
  Action: Create security policy

- **Enable read access for authenticated users**: RLS policy missing on user_profiles
  Action: Create security policy

- **Enable update for authenticated users**: RLS policy missing on user_profiles
  Action: Create security policy

- **Users can update their own profile**: RLS policy missing on user_profiles
  Action: Create security policy

- **Users can view and edit their own set progress**: RLS policy missing on user_set_progress
  Action: Create security policy

- **Allow anon users to read for confirmation**: RLS policy missing on waitlist
  Action: Create security policy

- **Allow confirmation updates for anon users**: RLS policy missing on waitlist
  Action: Create security policy

- **Anyone can insert waitlist entries**: RLS policy missing on waitlist
  Action: Create security policy

- **Only authenticated users can view waitlist**: RLS policy missing on waitlist
  Action: Create security policy

- **Public Access**: RLS policy missing on objects
  Action: Create security policy

- **Users can delete own media**: RLS policy missing on objects
  Action: Create security policy

- **Users can update own media**: RLS policy missing on objects
  Action: Create security policy

- **Users can upload media**: RLS policy missing on objects
  Action: Create security policy

### HIGH PRIORITY (9 items)
- **auth.instances**: Table exists but missing 1 rows of data
  Action: Migrate data

- **storage.buckets**: Table exists but missing 1 rows of data
  Action: Migrate data

- **storage.objects**: Table exists but missing 44 rows of data
  Action: Migrate data

- **public.create_classroom**: Custom function missing in NEW project
  Action: Create function

- **public.generate_invite_code**: Custom function missing in NEW project
  Action: Create function

- **public.handle_new_user**: Custom function missing in NEW project
  Action: Create function

- **public.join_classroom_with_code**: Custom function missing in NEW project
  Action: Create function

- **on_auth_user_created**: Trigger missing on users
  Action: Create trigger

- **update_user_profiles_updated_at**: Trigger missing on user_profiles
  Action: Create trigger

## DETAILED TABLE COMPARISON

### auth.audit_log_entries
OLD: 222 rows | NEW: 31 rows
⚠️ **ROW COUNT MISMATCH**

### auth.flow_state
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.identities
OLD: 3 rows | NEW: 3 rows
✅ **SYNCHRONIZED**

### auth.instances
OLD: 1 rows | NEW: 0 rows
⚠️ **ROW COUNT MISMATCH**

### auth.mfa_amr_claims
OLD: 0 rows | NEW: 2 rows
⚠️ **ROW COUNT MISMATCH**

### auth.mfa_challenges
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.mfa_factors
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.one_time_tokens
OLD: 0 rows | NEW: 3 rows
⚠️ **ROW COUNT MISMATCH**

### auth.refresh_tokens
OLD: 0 rows | NEW: 3 rows
⚠️ **ROW COUNT MISMATCH**

### auth.saml_providers
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.saml_relay_states
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.schema_migrations
OLD: 61 rows | NEW: 61 rows
✅ **SYNCHRONIZED**

### auth.sessions
OLD: 0 rows | NEW: 2 rows
⚠️ **ROW COUNT MISMATCH**

### auth.sso_domains
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.sso_providers
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### auth.users
OLD: 3 rows | NEW: 3 rows
✅ **SYNCHRONIZED**

### public.card_categories
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.card_interactions
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.cards
OLD: 0 rows | NEW: 5 rows
⚠️ **ROW COUNT MISMATCH**

### public.categories
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.classroom_members
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.classroom_sets
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.classrooms
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.favicons
OLD: 1 rows | NEW: 1 rows
✅ **SYNCHRONIZED**

### public.flashcard_set_cards
OLD: 0 rows | NEW: 5 rows
⚠️ **ROW COUNT MISMATCH**

### public.flashcard_set_categories
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.flashcard_sets
OLD: 0 rows | NEW: 1 rows
⚠️ **ROW COUNT MISMATCH**

### public.schools
OLD: 1 rows | NEW: 1 rows
✅ **SYNCHRONIZED**

### public.study_logs
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.study_sessions
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.user_card_progress
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.user_profiles
OLD: 3 rows | NEW: 3 rows
✅ **SYNCHRONIZED**

### public.user_set_progress
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### public.waitlist
OLD: 1 rows | NEW: 2 rows
⚠️ **ROW COUNT MISMATCH**

### realtime.messages
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### realtime.schema_migrations
OLD: 63 rows | NEW: 63 rows
✅ **SYNCHRONIZED**

### realtime.subscription
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### storage.buckets
OLD: 1 rows | NEW: 0 rows
⚠️ **ROW COUNT MISMATCH**

### storage.migrations
OLD: 26 rows | NEW: 39 rows
⚠️ **ROW COUNT MISMATCH**

### storage.objects
OLD: 44 rows | NEW: 0 rows
⚠️ **ROW COUNT MISMATCH**

### storage.s3_multipart_uploads
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

### storage.s3_multipart_uploads_parts
OLD: 0 rows | NEW: 0 rows
✅ **SYNCHRONIZED**

