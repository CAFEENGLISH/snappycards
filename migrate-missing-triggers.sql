-- MISSING TRIGGERS MIGRATION SCRIPT
-- Generated: 2025-08-07T21:44:58.194Z
-- Source: ycxqxdhaxehspypqbnpi
-- Target: NEW project

-- Trigger: on_auth_user_created on users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT
  ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Trigger: update_user_profiles_updated_at on user_profiles
CREATE OR REPLACE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE
  ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER-RELATED FUNCTIONS
-- ===========================

-- Function: public.handle_new_user
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

-- Function: public.update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

