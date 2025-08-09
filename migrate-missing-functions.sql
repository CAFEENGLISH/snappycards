-- MISSING FUNCTIONS MIGRATION SCRIPT
-- Generated: 2025-08-07T21:44:28.816Z
-- Source: ycxqxdhaxehspypqbnpi
-- Target: NEW project

-- Function: create_classroom
CREATE OR REPLACE FUNCTION public.create_classroom(classroom_name text, description text DEFAULT NULL::text)
 RETURNS TABLE(classroom_id uuid, invite_code text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_classroom_id UUID;
    new_invite_code TEXT;
    attempts INTEGER := 0;
    teacher_role TEXT;
BEGIN
    -- Check if user is teacher
    SELECT up.user_role INTO teacher_role 
    FROM public.user_profiles up 
    WHERE up.id = auth.uid();
    
    IF teacher_role != 'teacher' THEN
        RAISE EXCEPTION 'Only teachers can create classrooms';
    END IF;
    
    -- Generate unique invite code (max 10 attempts)
    LOOP
        new_invite_code := generate_invite_code();
        attempts := attempts + 1;
        
        -- Check if code is unique
        IF NOT EXISTS (SELECT 1 FROM public.classrooms WHERE classrooms.invite_code = new_invite_code) THEN
            EXIT;
        END IF;
        
        IF attempts >= 10 THEN
            RAISE EXCEPTION 'Could not generate unique invite code';
        END IF;
    END LOOP;
    
    -- Create classroom
    INSERT INTO public.classrooms (name, description, teacher_id, invite_code)
    VALUES (classroom_name, description, auth.uid(), new_invite_code)
    RETURNING id INTO new_classroom_id;
    
    RETURN QUERY SELECT new_classroom_id, new_invite_code;
END;
$function$
;

-- Function: generate_invite_code
CREATE OR REPLACE FUNCTION public.generate_invite_code(length integer DEFAULT 6)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    RETURN result;
END;
$function$
;

-- Function: handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.user_profiles (id, first_name, user_role)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''), 
        COALESCE(NEW.raw_user_meta_data->>'user_role', 'student')
    );
    RETURN NEW;
END;
$function$
;

-- Function: join_classroom_with_code
CREATE OR REPLACE FUNCTION public.join_classroom_with_code(code text)
 RETURNS TABLE(success boolean, message text, classroom_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    target_classroom_id UUID;
    target_classroom_name TEXT;
    student_role TEXT;
BEGIN
    -- Check if user is student
    SELECT up.user_role INTO student_role 
    FROM public.user_profiles up 
    WHERE up.id = auth.uid();
    
    IF student_role != 'student' THEN
        RETURN QUERY SELECT false, 'Only students can join classrooms', NULL::TEXT;
        RETURN;
    END IF;
    
    -- Find classroom by invite code
    SELECT c.id, c.name INTO target_classroom_id, target_classroom_name
    FROM public.classrooms c
    WHERE c.invite_code = code AND c.is_active = true;
    
    IF target_classroom_id IS NULL THEN
        RETURN QUERY SELECT false, 'Invalid or expired invite code', NULL::TEXT;
        RETURN;
    END IF;
    
    -- Check if already a member
    IF EXISTS (
        SELECT 1 FROM public.classroom_members cm 
        WHERE cm.classroom_id = target_classroom_id 
        AND cm.student_id = auth.uid() 
        AND cm.is_active = true
    ) THEN
        RETURN QUERY SELECT false, 'Already a member of this classroom', target_classroom_name;
        RETURN;
    END IF;
    
    -- Join classroom
    INSERT INTO public.classroom_members (classroom_id, student_id)
    VALUES (target_classroom_id, auth.uid())
    ON CONFLICT (classroom_id, student_id) 
    DO UPDATE SET is_active = true, joined_at = NOW();
    
    RETURN QUERY SELECT true, 'Successfully joined classroom', target_classroom_name;
END;
$function$
;

