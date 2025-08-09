--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: create_classroom(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_classroom(classroom_name text, description text DEFAULT NULL::text) RETURNS TABLE(classroom_id uuid, invite_code text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
        DECLARE
          new_classroom_id uuid;
          new_invite_code text;
        BEGIN
          -- Generate unique invite code
          LOOP
            new_invite_code := generate_invite_code(6);
            EXIT WHEN NOT EXISTS (
              SELECT 1 FROM classrooms WHERE access_code = new_invite_code
            );
          END LOOP;
          
          -- Create the classroom
          INSERT INTO classrooms (name, description, teacher_id, access_code, is_active)
          VALUES (classroom_name, description, auth.uid(), new_invite_code, true)
          RETURNING id INTO new_classroom_id;
          
          -- Return the results
          RETURN QUERY SELECT new_classroom_id, new_invite_code;
        END;
        $$;


--
-- Name: create_user_profile(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_user_profile() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO user_profiles (id, created_at, updated_at)
    VALUES (NEW.id, NOW(), NOW());
    RETURN NEW;
END;
$$;


--
-- Name: generate_invite_code(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_invite_code(length integer DEFAULT 6) RETURNS text
    LANGUAGE plpgsql
    AS $$
        DECLARE
          chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Excluding confusing characters
          result text := '';
          i integer;
        BEGIN
          FOR i IN 1..length LOOP
            result := result || substr(chars, (random() * length(chars))::integer + 1, 1);
          END LOOP;
          RETURN result;
        END;
        $$;


--
-- Name: join_classroom_with_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.join_classroom_with_code(code text) RETURNS TABLE(success boolean, message text, classroom_name text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
        DECLARE
          classroom_record record;
          user_id_val uuid := auth.uid();
        BEGIN
          -- Check if user is authenticated
          IF user_id_val IS NULL THEN
            RETURN QUERY SELECT false, 'User not authenticated', null::text;
            RETURN;
          END IF;
          
          -- Find classroom by code
          SELECT id, name, is_active INTO classroom_record
          FROM classrooms 
          WHERE access_code = code;
          
          IF NOT FOUND THEN
            RETURN QUERY SELECT false, 'Invalid invite code', null::text;
            RETURN;
          END IF;
          
          IF NOT classroom_record.is_active THEN
            RETURN QUERY SELECT false, 'Classroom is not active', classroom_record.name;
            RETURN;
          END IF;
          
          -- Check if user is already a member
          IF EXISTS (
            SELECT 1 FROM classroom_members 
            WHERE classroom_id = classroom_record.id 
            AND user_id = user_id_val
          ) THEN
            RETURN QUERY SELECT false, 'Already a member of this classroom', classroom_record.name;
            RETURN;
          END IF;
          
          -- Add user to classroom
          INSERT INTO classroom_members (classroom_id, user_id, role, is_active)
          VALUES (classroom_record.id, user_id_val, 'student', true);
          
          RETURN QUERY SELECT true, 'Successfully joined classroom', classroom_record.name;
        END;
        $$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: card_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    card_id uuid NOT NULL,
    category_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: card_interactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_interactions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    card_id uuid NOT NULL,
    direction text DEFAULT 'hu-en'::text NOT NULL,
    reaction_time integer,
    feedback_type text,
    interaction_type text DEFAULT 'view'::text,
    "timestamp" timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT card_interactions_direction_check CHECK ((direction = ANY (ARRAY['hu-en'::text, 'en-hu'::text]))),
    CONSTRAINT card_interactions_feedback_type_check CHECK ((feedback_type = ANY (ARRAY['tudom'::text, 'bizonytalan'::text, 'tanulandó'::text]))),
    CONSTRAINT card_interactions_interaction_type_check CHECK ((interaction_type = ANY (ARRAY['view'::text, 'flip'::text, 'feedback'::text, 'skip'::text])))
);


--
-- Name: cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text,
    english_title text,
    title_formatted text,
    english_title_formatted text,
    image_url text,
    image_alt text,
    media_type text,
    media_url text,
    category text,
    difficulty_level text,
    user_id uuid,
    is_public boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    set_id uuid,
    category_id uuid,
    flashcard_set_id uuid,
    front_text text,
    back_text text,
    front_image_url text,
    back_image_url text,
    is_mock boolean DEFAULT false
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    color text,
    description text,
    is_active boolean DEFAULT true,
    created_by uuid,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: classroom_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classroom_details (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    classroom_id uuid,
    subject text,
    grade_level text,
    academic_year text,
    meeting_schedule text,
    additional_info text,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    name text,
    description text,
    invite_code text,
    is_active boolean DEFAULT true,
    teacher_email text,
    teacher_first_name text,
    teacher_last_name text,
    student_count integer DEFAULT 0
);


--
-- Name: classroom_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classroom_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    classroom_id uuid,
    user_id uuid,
    role text DEFAULT 'student'::text,
    joined_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    student_id uuid
);


--
-- Name: classroom_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classroom_sets (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    classroom_id uuid NOT NULL,
    set_id uuid NOT NULL,
    assigned_by uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now(),
    due_date timestamp with time zone,
    is_required boolean DEFAULT true,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: classrooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.classrooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    teacher_id uuid,
    school_id uuid,
    access_code text,
    is_active boolean DEFAULT true,
    max_students integer,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    invite_code text
);


--
-- Name: favicons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favicons (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    domain text NOT NULL,
    favicon_url text NOT NULL,
    last_updated timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    fetch_attempts integer DEFAULT 0,
    last_fetch_attempt timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: flashcard_set_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flashcard_set_cards (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    set_id uuid NOT NULL,
    card_id uuid NOT NULL,
    "position" integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: flashcard_set_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flashcard_set_categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    set_id uuid NOT NULL,
    category_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: flashcard_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flashcard_sets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    language_a text DEFAULT 'hungarian'::text,
    language_b text DEFAULT 'english'::text,
    category text,
    difficulty_level text,
    is_public boolean DEFAULT false,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    language_a_code text,
    language_b_code text,
    creator_id uuid,
    is_mock boolean DEFAULT false
);


--
-- Name: language_translations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language_translations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    language_id uuid NOT NULL,
    display_language_code text NOT NULL,
    translated_name text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    flag_emoji text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: schools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schools (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    address text,
    phone text,
    contact_email text,
    admin_user_id uuid,
    description text,
    is_active boolean DEFAULT true,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: study_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.study_logs (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    card_id uuid NOT NULL,
    set_id uuid NOT NULL,
    session_id uuid,
    feedback_type text NOT NULL,
    direction text DEFAULT 'hu-en'::text NOT NULL,
    reaction_time integer,
    mastery_level_before integer,
    mastery_level_after integer,
    review_interval integer,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT study_logs_direction_check CHECK ((direction = ANY (ARRAY['hu-en'::text, 'en-hu'::text]))),
    CONSTRAINT study_logs_feedback_type_enhanced_check CHECK ((feedback_type = ANY (ARRAY['tudom'::text, 'bizonytalan'::text, 'tanulandó'::text, 'easy'::text, 'medium'::text, 'hard'::text])))
);


--
-- Name: study_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.study_sessions (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    set_id uuid NOT NULL,
    classroom_id uuid,
    direction text DEFAULT 'hu-en'::text NOT NULL,
    session_type text DEFAULT 'study'::text,
    cards_studied integer DEFAULT 0,
    cards_correct integer DEFAULT 0,
    cards_incorrect integer DEFAULT 0,
    total_time integer DEFAULT 0,
    started_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    is_completed boolean DEFAULT false,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT study_sessions_direction_check CHECK ((direction = ANY (ARRAY['hu-en'::text, 'en-hu'::text]))),
    CONSTRAINT study_sessions_session_type_check CHECK ((session_type = ANY (ARRAY['study'::text, 'practice'::text, 'test'::text, 'review'::text])))
);


--
-- Name: user_card_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_card_progress (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    card_id uuid NOT NULL,
    set_id uuid NOT NULL,
    direction text DEFAULT 'hu-en'::text NOT NULL,
    mastery_level integer DEFAULT 1,
    last_reviewed timestamp with time zone DEFAULT now(),
    next_review timestamp with time zone,
    review_count integer DEFAULT 1,
    correct_count integer DEFAULT 0,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT user_card_progress_direction_check CHECK ((direction = ANY (ARRAY['hu-en'::text, 'en-hu'::text]))),
    CONSTRAINT user_card_progress_mastery_level_enhanced_check CHECK (((mastery_level >= 0) AND (mastery_level <= 3)))
);


--
-- Name: user_learning_languages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_learning_languages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    language_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name text,
    last_name text,
    email text,
    user_role text DEFAULT 'student'::text,
    school_id uuid,
    language text,
    country text,
    phone text,
    status text,
    note text,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    stored_password text,
    CONSTRAINT user_profiles_user_role_check CHECK ((user_role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text, 'school_admin'::text])))
);


--
-- Name: user_set_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_set_progress (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    set_id uuid NOT NULL,
    total_time_spent integer DEFAULT 0,
    last_studied timestamp with time zone DEFAULT now(),
    cards_studied integer DEFAULT 0,
    cards_mastered integer DEFAULT 0,
    session_count integer DEFAULT 0,
    is_mock boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: waitlist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.waitlist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    name text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    confirmed boolean DEFAULT false,
    confirmation_token text,
    confirmed_at timestamp with time zone,
    first_name text,
    language text,
    source text,
    status text,
    invite_sent_at timestamp with time zone,
    registered_at timestamp with time zone,
    is_mock boolean DEFAULT false
);


--
-- Name: card_categories card_categories_card_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_categories
    ADD CONSTRAINT card_categories_card_id_category_id_key UNIQUE (card_id, category_id);


--
-- Name: card_categories card_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_categories
    ADD CONSTRAINT card_categories_pkey PRIMARY KEY (id);


--
-- Name: card_interactions card_interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_interactions
    ADD CONSTRAINT card_interactions_pkey PRIMARY KEY (id);


--
-- Name: cards cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: classroom_details classroom_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_details
    ADD CONSTRAINT classroom_details_pkey PRIMARY KEY (id);


--
-- Name: classroom_members classroom_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_members
    ADD CONSTRAINT classroom_members_pkey PRIMARY KEY (id);


--
-- Name: classroom_sets classroom_sets_classroom_id_set_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_sets
    ADD CONSTRAINT classroom_sets_classroom_id_set_id_key UNIQUE (classroom_id, set_id);


--
-- Name: classroom_sets classroom_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_sets
    ADD CONSTRAINT classroom_sets_pkey PRIMARY KEY (id);


--
-- Name: classrooms classrooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classrooms
    ADD CONSTRAINT classrooms_pkey PRIMARY KEY (id);


--
-- Name: favicons favicons_domain_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favicons
    ADD CONSTRAINT favicons_domain_key UNIQUE (domain);


--
-- Name: favicons favicons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favicons
    ADD CONSTRAINT favicons_pkey PRIMARY KEY (id);


--
-- Name: flashcard_set_cards flashcard_set_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_cards
    ADD CONSTRAINT flashcard_set_cards_pkey PRIMARY KEY (id);


--
-- Name: flashcard_set_cards flashcard_set_cards_set_id_card_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_cards
    ADD CONSTRAINT flashcard_set_cards_set_id_card_id_key UNIQUE (set_id, card_id);


--
-- Name: flashcard_set_categories flashcard_set_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_categories
    ADD CONSTRAINT flashcard_set_categories_pkey PRIMARY KEY (id);


--
-- Name: flashcard_set_categories flashcard_set_categories_set_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_categories
    ADD CONSTRAINT flashcard_set_categories_set_id_category_id_key UNIQUE (set_id, category_id);


--
-- Name: flashcard_sets flashcard_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_sets
    ADD CONSTRAINT flashcard_sets_pkey PRIMARY KEY (id);


--
-- Name: language_translations language_translations_language_id_display_language_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language_translations
    ADD CONSTRAINT language_translations_language_id_display_language_code_key UNIQUE (language_id, display_language_code);


--
-- Name: language_translations language_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language_translations
    ADD CONSTRAINT language_translations_pkey PRIMARY KEY (id);


--
-- Name: languages languages_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_code_key UNIQUE (code);


--
-- Name: languages languages_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_name_key UNIQUE (name);


--
-- Name: languages languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (id);


--
-- Name: schools schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schools
    ADD CONSTRAINT schools_pkey PRIMARY KEY (id);


--
-- Name: study_logs study_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.study_logs
    ADD CONSTRAINT study_logs_pkey PRIMARY KEY (id);


--
-- Name: study_sessions study_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.study_sessions
    ADD CONSTRAINT study_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_card_progress user_card_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_card_progress
    ADD CONSTRAINT user_card_progress_pkey PRIMARY KEY (id);


--
-- Name: user_card_progress user_card_progress_user_id_card_id_set_id_direction_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_card_progress
    ADD CONSTRAINT user_card_progress_user_id_card_id_set_id_direction_key UNIQUE (user_id, card_id, set_id, direction);


--
-- Name: user_learning_languages user_learning_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_learning_languages
    ADD CONSTRAINT user_learning_languages_pkey PRIMARY KEY (id);


--
-- Name: user_learning_languages user_learning_languages_user_id_language_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_learning_languages
    ADD CONSTRAINT user_learning_languages_user_id_language_id_key UNIQUE (user_id, language_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_set_progress user_set_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_set_progress
    ADD CONSTRAINT user_set_progress_pkey PRIMARY KEY (id);


--
-- Name: user_set_progress user_set_progress_user_id_set_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_set_progress
    ADD CONSTRAINT user_set_progress_user_id_set_id_key UNIQUE (user_id, set_id);


--
-- Name: waitlist waitlist_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_email_key UNIQUE (email);


--
-- Name: waitlist waitlist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_pkey PRIMARY KEY (id);


--
-- Name: idx_card_categories_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_categories_card ON public.card_categories USING btree (card_id);


--
-- Name: idx_card_categories_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_categories_card_id ON public.card_categories USING btree (card_id);


--
-- Name: idx_card_categories_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_categories_category ON public.card_categories USING btree (category_id);


--
-- Name: idx_card_categories_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_categories_category_id ON public.card_categories USING btree (category_id);


--
-- Name: idx_card_interactions_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_interactions_card ON public.card_interactions USING btree (card_id);


--
-- Name: idx_card_interactions_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_interactions_session ON public.card_interactions USING btree (session_id);


--
-- Name: idx_cards_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cards_category ON public.cards USING btree (category);


--
-- Name: idx_cards_difficulty_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cards_difficulty_level ON public.cards USING btree (difficulty_level);


--
-- Name: idx_categories_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_name ON public.categories USING btree (name);


--
-- Name: idx_classroom_members_classroom_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_classroom_members_classroom_user ON public.classroom_members USING btree (classroom_id, user_id);


--
-- Name: idx_classrooms_school_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_classrooms_school_id ON public.classrooms USING btree (school_id);


--
-- Name: idx_classrooms_teacher_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_classrooms_teacher_id ON public.classrooms USING btree (teacher_id);


--
-- Name: idx_favicons_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_favicons_active ON public.favicons USING btree (is_active);


--
-- Name: idx_favicons_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_favicons_domain ON public.favicons USING btree (domain);


--
-- Name: idx_flashcard_set_categories_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_flashcard_set_categories_category ON public.flashcard_set_categories USING btree (category_id);


--
-- Name: idx_flashcard_set_categories_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_flashcard_set_categories_set ON public.flashcard_set_categories USING btree (set_id);


--
-- Name: idx_flashcard_sets_is_public; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_flashcard_sets_is_public ON public.flashcard_sets USING btree (is_public);


--
-- Name: idx_flashcard_sets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_flashcard_sets_user_id ON public.flashcard_sets USING btree (user_id);


--
-- Name: idx_study_logs_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_card ON public.study_logs USING btree (card_id);


--
-- Name: idx_study_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_created_at ON public.study_logs USING btree (created_at);


--
-- Name: idx_study_logs_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_session ON public.study_logs USING btree (session_id);


--
-- Name: idx_study_logs_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_set ON public.study_logs USING btree (set_id);


--
-- Name: idx_study_logs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_user ON public.study_logs USING btree (user_id);


--
-- Name: idx_study_logs_user_card; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_user_card ON public.study_logs USING btree (user_id, card_id);


--
-- Name: idx_study_logs_user_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_logs_user_set ON public.study_logs USING btree (user_id, set_id);


--
-- Name: idx_study_sessions_classroom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_sessions_classroom ON public.study_sessions USING btree (classroom_id);


--
-- Name: idx_study_sessions_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_sessions_set ON public.study_sessions USING btree (set_id);


--
-- Name: idx_study_sessions_started; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_sessions_started ON public.study_sessions USING btree (started_at);


--
-- Name: idx_study_sessions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_sessions_user ON public.study_sessions USING btree (user_id);


--
-- Name: idx_study_sessions_user_set_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_study_sessions_user_set_direction ON public.study_sessions USING btree (user_id, set_id, direction);


--
-- Name: idx_user_card_progress_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_card_progress_direction ON public.user_card_progress USING btree (user_id, direction);


--
-- Name: idx_user_card_progress_mastery; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_card_progress_mastery ON public.user_card_progress USING btree (mastery_level);


--
-- Name: idx_user_set_progress_last_studied; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_set_progress_last_studied ON public.user_set_progress USING btree (last_studied);


--
-- Name: idx_user_set_progress_set; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_set_progress_set ON public.user_set_progress USING btree (set_id);


--
-- Name: idx_user_set_progress_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_set_progress_user ON public.user_set_progress USING btree (user_id);


--
-- Name: categories update_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: classrooms update_classrooms_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_classrooms_updated_at BEFORE UPDATE ON public.classrooms FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: flashcard_sets update_flashcard_sets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_flashcard_sets_updated_at BEFORE UPDATE ON public.flashcard_sets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: schools update_schools_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON public.schools FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_profiles update_user_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_set_progress update_user_set_progress_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_set_progress_updated_at BEFORE UPDATE ON public.user_set_progress FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: card_categories card_categories_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_categories
    ADD CONSTRAINT card_categories_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.cards(id) ON DELETE CASCADE;


--
-- Name: card_categories card_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_categories
    ADD CONSTRAINT card_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: card_interactions card_interactions_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_interactions
    ADD CONSTRAINT card_interactions_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.study_sessions(id) ON DELETE CASCADE;


--
-- Name: classroom_details classroom_details_classroom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_details
    ADD CONSTRAINT classroom_details_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id) ON DELETE CASCADE;


--
-- Name: classroom_members classroom_members_classroom_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_members
    ADD CONSTRAINT classroom_members_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id) ON DELETE CASCADE;


--
-- Name: classroom_sets classroom_sets_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.classroom_sets
    ADD CONSTRAINT classroom_sets_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: flashcard_set_cards flashcard_set_cards_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_cards
    ADD CONSTRAINT flashcard_set_cards_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.cards(id) ON DELETE CASCADE;


--
-- Name: flashcard_set_categories flashcard_set_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_categories
    ADD CONSTRAINT flashcard_set_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: flashcard_set_categories flashcard_set_categories_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flashcard_set_categories
    ADD CONSTRAINT flashcard_set_categories_set_id_fkey FOREIGN KEY (set_id) REFERENCES public.flashcard_sets(id) ON DELETE CASCADE;


--
-- Name: language_translations language_translations_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language_translations
    ADD CONSTRAINT language_translations_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id) ON DELETE CASCADE;


--
-- Name: study_logs study_logs_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.study_logs
    ADD CONSTRAINT study_logs_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.study_sessions(id) ON DELETE CASCADE;


--
-- Name: study_logs study_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.study_logs
    ADD CONSTRAINT study_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: study_sessions study_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.study_sessions
    ADD CONSTRAINT study_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_card_progress user_card_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_card_progress
    ADD CONSTRAINT user_card_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_learning_languages user_learning_languages_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_learning_languages
    ADD CONSTRAINT user_learning_languages_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.languages(id) ON DELETE CASCADE;


--
-- Name: user_learning_languages user_learning_languages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_learning_languages
    ADD CONSTRAINT user_learning_languages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_set_progress user_set_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_set_progress
    ADD CONSTRAINT user_set_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: waitlist Allow public insert on waitlist; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public insert on waitlist" ON public.waitlist FOR INSERT WITH CHECK (true);


--
-- Name: waitlist Allow public read on waitlist; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read on waitlist" ON public.waitlist FOR SELECT USING (true);


--
-- Name: waitlist Allow public update on waitlist; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public update on waitlist" ON public.waitlist FOR UPDATE USING (true);


--
-- Name: cards Anyone can create cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can create cards" ON public.cards FOR INSERT WITH CHECK (true);


--
-- Name: cards Anyone can delete cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can delete cards" ON public.cards FOR DELETE USING (true);


--
-- Name: user_profiles Anyone can insert profile on signup; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can insert profile on signup" ON public.user_profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: cards Anyone can read cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can read cards" ON public.cards FOR SELECT USING (true);


--
-- Name: cards Anyone can update cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can update cards" ON public.cards FOR UPDATE USING (true) WITH CHECK (true);


--
-- Name: categories Authenticated users can insert categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert categories" ON public.categories FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: favicons Authenticated users can manage favicons; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can manage favicons" ON public.favicons WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: card_categories Card categories viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Card categories viewable by everyone" ON public.card_categories FOR SELECT USING (true);


--
-- Name: classroom_sets Classroom members can view classroom sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Classroom members can view classroom sets" ON public.classroom_sets FOR SELECT USING (((classroom_id IN ( SELECT cm.classroom_id
   FROM public.classroom_members cm
  WHERE (cm.user_id = auth.uid()))) OR (classroom_id IN ( SELECT c.id
   FROM public.classrooms c
  WHERE (c.teacher_id = auth.uid())))));


--
-- Name: schools Enable insert for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users" ON public.schools FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: schools Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.schools FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: user_profiles Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.user_profiles FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: schools Enable update for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for authenticated users" ON public.schools FOR UPDATE USING ((auth.role() = 'authenticated'::text));


--
-- Name: language_translations Everyone can read language translations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can read language translations" ON public.language_translations FOR SELECT USING (true);


--
-- Name: languages Everyone can read languages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can read languages" ON public.languages FOR SELECT USING (true);


--
-- Name: categories Everyone can view categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view categories" ON public.categories FOR SELECT USING (true);


--
-- Name: favicons Favicons are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Favicons are publicly readable" ON public.favicons FOR SELECT USING (true);


--
-- Name: flashcard_set_categories Set categories viewable by everyone; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Set categories viewable by everyone" ON public.flashcard_set_categories FOR SELECT USING (true);


--
-- Name: classroom_members Students can join classrooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Students can join classrooms" ON public.classroom_members FOR INSERT WITH CHECK (((auth.uid() = user_id) AND (EXISTS ( SELECT 1
   FROM public.user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.user_role = 'student'::text))))));


--
-- Name: classroom_members Students can leave classrooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Students can leave classrooms" ON public.classroom_members FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: classrooms Students can view their classrooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Students can view their classrooms" ON public.classrooms FOR SELECT USING ((id IN ( SELECT classroom_members.classroom_id
   FROM public.classroom_members
  WHERE (classroom_members.user_id = auth.uid()))));


--
-- Name: classroom_sets Teachers can manage their classroom sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Teachers can manage their classroom sets" ON public.classroom_sets USING ((classroom_id IN ( SELECT c.id
   FROM public.classrooms c
  WHERE (c.teacher_id = auth.uid()))));


--
-- Name: classrooms Teachers can manage their classrooms; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Teachers can manage their classrooms" ON public.classrooms USING ((teacher_id = auth.uid()));


--
-- Name: classroom_members Teachers can view their classroom members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Teachers can view their classroom members" ON public.classroom_members FOR SELECT USING (((auth.uid() IN ( SELECT classrooms.teacher_id
   FROM public.classrooms
  WHERE (classrooms.id = classroom_members.classroom_id))) OR (auth.uid() = user_id)));


--
-- Name: card_interactions Users can create own card interactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create own card interactions" ON public.card_interactions FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.study_sessions ss
  WHERE ((ss.id = card_interactions.session_id) AND (ss.user_id = auth.uid())))));


--
-- Name: user_card_progress Users can create own card progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create own card progress" ON public.user_card_progress FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_set_progress Users can create own set progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create own set progress" ON public.user_set_progress FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: study_logs Users can create own study logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create own study logs" ON public.study_logs FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: study_sessions Users can create own study sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create own study sessions" ON public.study_sessions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: flashcard_sets Users can create their own flashcard sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own flashcard sets" ON public.flashcard_sets FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: flashcard_sets Users can delete their own flashcard sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own flashcard sets" ON public.flashcard_sets FOR DELETE USING ((auth.uid() = user_id));


--
-- Name: card_categories Users can manage card categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage card categories" ON public.card_categories TO authenticated USING (true) WITH CHECK (true);


--
-- Name: flashcard_set_cards Users can manage cards in their own sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage cards in their own sets" ON public.flashcard_set_cards USING ((EXISTS ( SELECT 1
   FROM public.flashcard_sets
  WHERE ((flashcard_sets.id = flashcard_set_cards.set_id) AND (flashcard_sets.user_id = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.flashcard_sets
  WHERE ((flashcard_sets.id = flashcard_set_cards.set_id) AND (flashcard_sets.user_id = auth.uid())))));


--
-- Name: flashcard_set_categories Users can manage categories for their own sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage categories for their own sets" ON public.flashcard_set_categories USING ((EXISTS ( SELECT 1
   FROM public.flashcard_sets
  WHERE ((flashcard_sets.id = flashcard_set_categories.set_id) AND (flashcard_sets.user_id = auth.uid())))));


--
-- Name: cards Users can manage their own cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own cards" ON public.cards USING ((user_id = auth.uid()));


--
-- Name: user_learning_languages Users can manage their own learning languages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own learning languages" ON public.user_learning_languages USING ((auth.uid() = user_id));


--
-- Name: card_interactions Users can read own card interactions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own card interactions" ON public.card_interactions FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.study_sessions ss
  WHERE ((ss.id = card_interactions.session_id) AND (ss.user_id = auth.uid())))));


--
-- Name: user_card_progress Users can read own card progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own card progress" ON public.user_card_progress FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: user_set_progress Users can read own set progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own set progress" ON public.user_set_progress FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: study_logs Users can read own study logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own study logs" ON public.study_logs FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: study_sessions Users can read own study sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read own study sessions" ON public.study_sessions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: flashcard_sets Users can read their own flashcard sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read their own flashcard sets" ON public.flashcard_sets FOR SELECT USING (((auth.uid() = user_id) OR (is_public = true)));


--
-- Name: user_card_progress Users can update own card progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own card progress" ON public.user_card_progress FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: user_set_progress Users can update own set progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own set progress" ON public.user_set_progress FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: study_sessions Users can update own study sessions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own study sessions" ON public.study_sessions FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: flashcard_sets Users can update their own flashcard sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own flashcard sets" ON public.flashcard_sets FOR UPDATE USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: user_profiles Users can update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING ((id = auth.uid()));


--
-- Name: cards Users can view public cards; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view public cards" ON public.cards FOR SELECT USING (((is_public = true) OR (user_id = auth.uid())));


--
-- Name: flashcard_sets Users can view public flashcard sets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view public flashcard sets" ON public.flashcard_sets FOR SELECT USING (((is_public = true) OR (user_id = auth.uid())));


--
-- Name: user_profiles Users can view their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own profile" ON public.user_profiles FOR SELECT USING ((id = auth.uid()));


--
-- Name: card_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.card_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: card_interactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.card_interactions ENABLE ROW LEVEL SECURITY;

--
-- Name: cards; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

--
-- Name: categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

--
-- Name: classroom_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.classroom_details ENABLE ROW LEVEL SECURITY;

--
-- Name: classroom_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.classroom_members ENABLE ROW LEVEL SECURITY;

--
-- Name: classroom_sets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.classroom_sets ENABLE ROW LEVEL SECURITY;

--
-- Name: classrooms; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;

--
-- Name: favicons; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.favicons ENABLE ROW LEVEL SECURITY;

--
-- Name: flashcard_set_cards; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.flashcard_set_cards ENABLE ROW LEVEL SECURITY;

--
-- Name: flashcard_set_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.flashcard_set_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: flashcard_sets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.flashcard_sets ENABLE ROW LEVEL SECURITY;

--
-- Name: language_translations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.language_translations ENABLE ROW LEVEL SECURITY;

--
-- Name: languages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;

--
-- Name: schools; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;

--
-- Name: study_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.study_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: study_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_card_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_card_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: user_learning_languages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_learning_languages ENABLE ROW LEVEL SECURITY;

--
-- Name: user_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: user_set_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_set_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: waitlist; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

