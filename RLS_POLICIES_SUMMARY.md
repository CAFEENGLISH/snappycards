# RLS POLICIES MIGRATION SUMMARY

Generated: 2025-08-07T21:45:43.254Z
Total policies: 44
Tables with policies: 20

## Policies by Table

### auth.identities (1 policies)
- **auth_identities_access_policy** (ALL)

### auth.refresh_tokens (1 policies)
- **auth_refresh_tokens_access_policy** (ALL)

### auth.sessions (1 policies)
- **auth_sessions_access_policy** (ALL)

### auth.users (1 policies)
- **auth_users_access_policy** (ALL)

### public.card_categories (4 policies)
- **card_categories_delete_policy** (DELETE)
- **card_categories_insert_policy** (INSERT)
- **card_categories_select_policy** (SELECT)
- **card_categories_update_policy** (UPDATE)

### public.cards (4 policies)
- **Anyone can create cards** (INSERT)
- **Anyone can delete cards** (DELETE)
- **Anyone can read cards** (SELECT)
- **Anyone can update cards** (UPDATE)

### public.categories (2 policies)
- **Authenticated users can insert categories** (INSERT)
- **Everyone can view categories** (SELECT)

### public.classroom_members (3 policies)
- **Students can join classrooms** (INSERT)
- **Students can leave classrooms** (UPDATE)
- **Teachers can view their classroom members** (SELECT)

### public.classroom_sets (2 policies)
- **Classroom members can view classroom sets** (SELECT)
- **Teachers can manage their classroom sets** (ALL)

### public.classrooms (1 policies)
- **Enable read access for all users** (SELECT)

### public.flashcard_set_cards (1 policies)
- **Users can manage cards in their own sets** (ALL)

### public.flashcard_set_categories (1 policies)
- **Users can manage categories for their own sets** (ALL)

### public.flashcard_sets (4 policies)
- **Users can create their own flashcard sets** (INSERT)
- **Users can delete their own flashcard sets** (DELETE)
- **Users can read their own flashcard sets** (SELECT)
- **Users can update their own flashcard sets** (UPDATE)

### public.schools (3 policies)
- **Enable insert for authenticated users** (INSERT)
- **Enable read access for authenticated users** (SELECT)
- **Enable update for authenticated users** (UPDATE)

### public.study_logs (1 policies)
- **Users can view and create their own study logs** (ALL)

### public.user_card_progress (1 policies)
- **Users can manage their own progress** (ALL)

### public.user_profiles (4 policies)
- **Anyone can insert profile on signup** (INSERT)
- **Enable read access for authenticated users** (SELECT)
- **Enable update for authenticated users** (UPDATE)
- **Users can update their own profile** (UPDATE)

### public.user_set_progress (1 policies)
- **Users can view and edit their own set progress** (ALL)

### public.waitlist (4 policies)
- **Allow anon users to read for confirmation** (SELECT)
- **Allow confirmation updates for anon users** (UPDATE)
- **Anyone can insert waitlist entries** (INSERT)
- **Only authenticated users can view waitlist** (SELECT)

### storage.objects (4 policies)
- **Public Access** (SELECT)
- **Users can delete own media** (DELETE)
- **Users can update own media** (UPDATE)
- **Users can upload media** (INSERT)

