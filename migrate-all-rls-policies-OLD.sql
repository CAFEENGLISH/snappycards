-- COMPREHENSIVE RLS POLICIES MIGRATION SCRIPT
-- Generated: 2025-08-07T21:45:43.250Z
-- Source: ycxqxdhaxehspypqbnpi
-- Target: NEW project
-- Total policies: 44

-- WARNING: This will recreate ALL RLS policies from the OLD project
-- Make sure to backup your NEW project before running this script

-- =============================================
-- RLS Policies for auth.identities
-- =============================================

-- Enable RLS on auth.identities
ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

-- Policy: auth_identities_access_policy
CREATE POLICY "auth_identities_access_policy" ON auth.identities TO {postgres,service_role,supabase_auth_admin}
  USING (true);


-- =============================================
-- RLS Policies for auth.refresh_tokens
-- =============================================

-- Enable RLS on auth.refresh_tokens
ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: auth_refresh_tokens_access_policy
CREATE POLICY "auth_refresh_tokens_access_policy" ON auth.refresh_tokens TO {postgres,service_role,supabase_auth_admin}
  USING (true);


-- =============================================
-- RLS Policies for auth.sessions
-- =============================================

-- Enable RLS on auth.sessions
ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

-- Policy: auth_sessions_access_policy
CREATE POLICY "auth_sessions_access_policy" ON auth.sessions TO {postgres,service_role,supabase_auth_admin}
  USING (true);


-- =============================================
-- RLS Policies for auth.users
-- =============================================

-- Enable RLS on auth.users
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Policy: auth_users_access_policy
CREATE POLICY "auth_users_access_policy" ON auth.users TO {postgres,service_role,supabase_auth_admin}
  USING (true);


-- =============================================
-- RLS Policies for public.card_categories
-- =============================================

-- Enable RLS on public.card_categories
ALTER TABLE public.card_categories ENABLE ROW LEVEL SECURITY;

-- Policy: card_categories_delete_policy
CREATE POLICY "card_categories_delete_policy" ON public.card_categories FOR DELETE TO {public}
  USING (true);

-- Policy: card_categories_insert_policy
CREATE POLICY "card_categories_insert_policy" ON public.card_categories FOR INSERT TO {public}
  WITH CHECK (true);

-- Policy: card_categories_select_policy
CREATE POLICY "card_categories_select_policy" ON public.card_categories FOR SELECT TO {public}
  USING (true);

-- Policy: card_categories_update_policy
CREATE POLICY "card_categories_update_policy" ON public.card_categories FOR UPDATE TO {public}
  USING (true);


-- =============================================
-- RLS Policies for public.cards
-- =============================================

-- Enable RLS on public.cards
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can create cards
CREATE POLICY "Anyone can create cards" ON public.cards FOR INSERT TO {public}
  WITH CHECK (true);

-- Policy: Anyone can delete cards
CREATE POLICY "Anyone can delete cards" ON public.cards FOR DELETE TO {public}
  USING (true);

-- Policy: Anyone can read cards
CREATE POLICY "Anyone can read cards" ON public.cards FOR SELECT TO {public}
  USING (true);

-- Policy: Anyone can update cards
CREATE POLICY "Anyone can update cards" ON public.cards FOR UPDATE TO {public}
  USING (true);


-- =============================================
-- RLS Policies for public.categories
-- =============================================

-- Enable RLS on public.categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can insert categories
CREATE POLICY "Authenticated users can insert categories" ON public.categories FOR INSERT TO {public}
  WITH CHECK ((auth.role() = 'authenticated'::text));

-- Policy: Everyone can view categories
CREATE POLICY "Everyone can view categories" ON public.categories FOR SELECT TO {public}
  USING (true);


-- =============================================
-- RLS Policies for public.classroom_members
-- =============================================

-- Enable RLS on public.classroom_members
ALTER TABLE public.classroom_members ENABLE ROW LEVEL SECURITY;

-- Policy: Students can join classrooms
CREATE POLICY "Students can join classrooms" ON public.classroom_members FOR INSERT TO {public}
  WITH CHECK (((auth.uid() = student_id) AND (EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.user_role = 'student'::text))))));

-- Policy: Students can leave classrooms
CREATE POLICY "Students can leave classrooms" ON public.classroom_members FOR UPDATE TO {public}
  USING ((auth.uid() = student_id));

-- Policy: Teachers can view their classroom members
CREATE POLICY "Teachers can view their classroom members" ON public.classroom_members FOR SELECT TO {public}
  USING (((auth.uid() IN ( SELECT classrooms.teacher_id
   FROM classrooms
  WHERE (classrooms.id = classroom_members.classroom_id))) OR (auth.uid() = student_id)));


-- =============================================
-- RLS Policies for public.classroom_sets
-- =============================================

-- Enable RLS on public.classroom_sets
ALTER TABLE public.classroom_sets ENABLE ROW LEVEL SECURITY;

-- Policy: Classroom members can view classroom sets
CREATE POLICY "Classroom members can view classroom sets" ON public.classroom_sets FOR SELECT TO {public}
  USING (((classroom_id IN ( SELECT cm.classroom_id
   FROM classroom_members cm
  WHERE (cm.student_id = auth.uid()))) OR (classroom_id IN ( SELECT c.id
   FROM classrooms c
  WHERE (c.teacher_id = auth.uid())))));

-- Policy: Teachers can manage their classroom sets
CREATE POLICY "Teachers can manage their classroom sets" ON public.classroom_sets TO {public}
  USING ((classroom_id IN ( SELECT c.id
   FROM classrooms c
  WHERE (c.teacher_id = auth.uid()))));


-- =============================================
-- RLS Policies for public.classrooms
-- =============================================

-- Enable RLS on public.classrooms
ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;

-- Policy: Enable read access for all users
CREATE POLICY "Enable read access for all users" ON public.classrooms FOR SELECT TO {public}
  USING (true);


-- =============================================
-- RLS Policies for public.flashcard_set_cards
-- =============================================

-- Enable RLS on public.flashcard_set_cards
ALTER TABLE public.flashcard_set_cards ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage cards in their own sets
CREATE POLICY "Users can manage cards in their own sets" ON public.flashcard_set_cards TO {public}
  USING ((EXISTS ( SELECT 1
   FROM flashcard_sets
  WHERE ((flashcard_sets.id = flashcard_set_cards.set_id) AND (flashcard_sets.creator_id = auth.uid())))));


-- =============================================
-- RLS Policies for public.flashcard_set_categories
-- =============================================

-- Enable RLS on public.flashcard_set_categories
ALTER TABLE public.flashcard_set_categories ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage categories for their own sets
CREATE POLICY "Users can manage categories for their own sets" ON public.flashcard_set_categories TO {public}
  USING ((EXISTS ( SELECT 1
   FROM flashcard_sets
  WHERE ((flashcard_sets.id = flashcard_set_categories.set_id) AND (flashcard_sets.creator_id = auth.uid())))));


-- =============================================
-- RLS Policies for public.flashcard_sets
-- =============================================

-- Enable RLS on public.flashcard_sets
ALTER TABLE public.flashcard_sets ENABLE ROW LEVEL SECURITY;

-- Policy: Users can create their own flashcard sets
CREATE POLICY "Users can create their own flashcard sets" ON public.flashcard_sets FOR INSERT TO {public}
  WITH CHECK ((auth.uid() = creator_id));

-- Policy: Users can delete their own flashcard sets
CREATE POLICY "Users can delete their own flashcard sets" ON public.flashcard_sets FOR DELETE TO {public}
  USING ((auth.uid() = creator_id));

-- Policy: Users can read their own flashcard sets
CREATE POLICY "Users can read their own flashcard sets" ON public.flashcard_sets FOR SELECT TO {public}
  USING (((auth.uid() = creator_id) OR (is_public = true)));

-- Policy: Users can update their own flashcard sets
CREATE POLICY "Users can update their own flashcard sets" ON public.flashcard_sets FOR UPDATE TO {public}
  USING ((auth.uid() = creator_id));


-- =============================================
-- RLS Policies for public.schools
-- =============================================

-- Enable RLS on public.schools
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

-- Policy: Enable insert for authenticated users
CREATE POLICY "Enable insert for authenticated users" ON public.schools FOR INSERT TO {public}
  WITH CHECK ((auth.role() = 'authenticated'::text));

-- Policy: Enable read access for authenticated users
CREATE POLICY "Enable read access for authenticated users" ON public.schools FOR SELECT TO {public}
  USING ((auth.role() = 'authenticated'::text));

-- Policy: Enable update for authenticated users
CREATE POLICY "Enable update for authenticated users" ON public.schools FOR UPDATE TO {public}
  USING ((auth.role() = 'authenticated'::text));


-- =============================================
-- RLS Policies for public.study_logs
-- =============================================

-- Enable RLS on public.study_logs
ALTER TABLE public.study_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view and create their own study logs
CREATE POLICY "Users can view and create their own study logs" ON public.study_logs TO {public}
  USING ((auth.uid() = user_id));


-- =============================================
-- RLS Policies for public.user_card_progress
-- =============================================

-- Enable RLS on public.user_card_progress
ALTER TABLE public.user_card_progress ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own progress
CREATE POLICY "Users can manage their own progress" ON public.user_card_progress TO {public}
  USING ((auth.uid() = user_id));


-- =============================================
-- RLS Policies for public.user_profiles
-- =============================================

-- Enable RLS on public.user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert profile on signup
CREATE POLICY "Anyone can insert profile on signup" ON public.user_profiles FOR INSERT TO {public}
  WITH CHECK ((auth.uid() = id));

-- Policy: Enable read access for authenticated users
CREATE POLICY "Enable read access for authenticated users" ON public.user_profiles FOR SELECT TO {public}
  USING ((auth.role() = 'authenticated'::text));

-- Policy: Enable update for authenticated users
CREATE POLICY "Enable update for authenticated users" ON public.user_profiles FOR UPDATE TO {public}
  USING (((auth.role() = 'authenticated'::text) AND (auth.uid() = id)));

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE TO {public}
  USING ((auth.uid() = id));


-- =============================================
-- RLS Policies for public.user_set_progress
-- =============================================

-- Enable RLS on public.user_set_progress
ALTER TABLE public.user_set_progress ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view and edit their own set progress
CREATE POLICY "Users can view and edit their own set progress" ON public.user_set_progress TO {public}
  USING ((auth.uid() = user_id));


-- =============================================
-- RLS Policies for public.waitlist
-- =============================================

-- Enable RLS on public.waitlist
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anon users to read for confirmation
CREATE POLICY "Allow anon users to read for confirmation" ON public.waitlist FOR SELECT TO {anon}
  USING ((confirmation_token IS NOT NULL));

-- Policy: Allow confirmation updates for anon users
CREATE POLICY "Allow confirmation updates for anon users" ON public.waitlist FOR UPDATE TO {anon}
  USING (true);

-- Policy: Anyone can insert waitlist entries
CREATE POLICY "Anyone can insert waitlist entries" ON public.waitlist FOR INSERT TO {anon}
  WITH CHECK (true);

-- Policy: Only authenticated users can view waitlist
CREATE POLICY "Only authenticated users can view waitlist" ON public.waitlist FOR SELECT TO {authenticated}
  USING (true);


-- =============================================
-- RLS Policies for storage.objects
-- =============================================

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy: Public Access
CREATE POLICY "Public Access" ON storage.objects FOR SELECT TO {public}
  USING ((bucket_id = 'media'::text));

-- Policy: Users can delete own media
CREATE POLICY "Users can delete own media" ON storage.objects FOR DELETE TO {public}
  USING (((bucket_id = 'media'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));

-- Policy: Users can update own media
CREATE POLICY "Users can update own media" ON storage.objects FOR UPDATE TO {public}
  USING (((bucket_id = 'media'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));

-- Policy: Users can upload media
CREATE POLICY "Users can upload media" ON storage.objects FOR INSERT TO {public}
  WITH CHECK (((bucket_id = 'media'::text) AND (auth.role() = 'authenticated'::text)));


-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check total number of policies created
SELECT COUNT(*) as total_policies FROM pg_policies WHERE schemaname IN ('public', 'auth', 'storage');

-- Check policies by table
SELECT schemaname, tablename, COUNT(*) as policy_count 
FROM pg_policies 
WHERE schemaname IN ('public', 'auth', 'storage')
GROUP BY schemaname, tablename 
ORDER BY schemaname, tablename;

-- Check if RLS is enabled on all tables
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname IN ('public', 'auth', 'storage')
ORDER BY schemaname, tablename;

