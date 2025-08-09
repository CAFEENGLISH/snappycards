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
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


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


--
-- Name: add_prefixes(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.add_prefixes(_bucket_id text, _name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    prefixes text[];
BEGIN
    prefixes := "storage"."get_prefixes"("_name");

    IF array_length(prefixes, 1) > 0 THEN
        INSERT INTO storage.prefixes (name, bucket_id)
        SELECT UNNEST(prefixes) as name, "_bucket_id" ON CONFLICT DO NOTHING;
    END IF;
END;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: delete_prefix(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix(_bucket_id text, _name text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Check if we can delete the prefix
    IF EXISTS(
        SELECT FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name") + 1
          AND "prefixes"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    )
    OR EXISTS(
        SELECT FROM "storage"."objects"
        WHERE "objects"."bucket_id" = "_bucket_id"
          AND "storage"."get_level"("objects"."name") = "storage"."get_level"("_name") + 1
          AND "objects"."name" COLLATE "C" LIKE "_name" || '/%'
        LIMIT 1
    ) THEN
    -- There are sub-objects, skip deletion
    RETURN false;
    ELSE
        DELETE FROM "storage"."prefixes"
        WHERE "prefixes"."bucket_id" = "_bucket_id"
          AND level = "storage"."get_level"("_name")
          AND "prefixes"."name" = "_name";
        RETURN true;
    END IF;
END;
$$;


--
-- Name: delete_prefix_hierarchy_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_prefix_hierarchy_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prefix text;
BEGIN
    prefix := "storage"."get_prefix"(OLD."name");

    IF coalesce(prefix, '') != '' THEN
        PERFORM "storage"."delete_prefix"(OLD."bucket_id", prefix);
    END IF;

    RETURN OLD;
END;
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    SELECT _parts[array_length(_parts,1)] INTO _filename;
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_level(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_level(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT array_length(string_to_array("name", '/'), 1);
$$;


--
-- Name: get_prefix(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefix(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT
    CASE WHEN strpos("name", '/') > 0 THEN
             regexp_replace("name", '[\/]{1}[^\/]+\/?$', '')
         ELSE
             ''
        END;
$_$;


--
-- Name: get_prefixes(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefixes(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    parts text[];
    prefixes text[];
    prefix text;
BEGIN
    -- Split the name into parts by '/'
    parts := string_to_array("name", '/');
    prefixes := '{}';

    -- Construct the prefixes, stopping one level below the last part
    FOR i IN 1..array_length(parts, 1) - 1 LOOP
            prefix := array_to_string(parts[1:i], '/');
            prefixes := array_append(prefixes, prefix);
    END LOOP;

    RETURN prefixes;
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


--
-- Name: objects_insert_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_insert_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    NEW.level := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: objects_update_prefix_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.objects_update_prefix_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    old_prefixes TEXT[];
BEGIN
    -- Ensure this is an update operation and the name has changed
    IF TG_OP = 'UPDATE' AND (NEW."name" <> OLD."name" OR NEW."bucket_id" <> OLD."bucket_id") THEN
        -- Retrieve old prefixes
        old_prefixes := "storage"."get_prefixes"(OLD."name");

        -- Remove old prefixes that are only used by this object
        WITH all_prefixes as (
            SELECT unnest(old_prefixes) as prefix
        ),
        can_delete_prefixes as (
             SELECT prefix
             FROM all_prefixes
             WHERE NOT EXISTS (
                 SELECT 1 FROM "storage"."objects"
                 WHERE "bucket_id" = OLD."bucket_id"
                   AND "name" <> OLD."name"
                   AND "name" LIKE (prefix || '%')
             )
         )
        DELETE FROM "storage"."prefixes" WHERE name IN (SELECT prefix FROM can_delete_prefixes);

        -- Add new prefixes
        PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    END IF;
    -- Set the new level
    NEW."level" := "storage"."get_level"(NEW."name");

    RETURN NEW;
END;
$$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: prefixes_insert_trigger(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.prefixes_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM "storage"."add_prefixes"(NEW."bucket_id", NEW."name");
    RETURN NEW;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql
    AS $$
declare
    can_bypass_rls BOOLEAN;
begin
    SELECT rolbypassrls
    INTO can_bypass_rls
    FROM pg_roles
    WHERE rolname = coalesce(nullif(current_setting('role', true), 'none'), current_user);

    IF can_bypass_rls THEN
        RETURN QUERY SELECT * FROM storage.search_v1_optimised(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    ELSE
        RETURN QUERY SELECT * FROM storage.search_legacy_v1(prefix, bucketname, limits, levels, offsets, search, sortcolumn, sortorder);
    END IF;
end;
$$;


--
-- Name: search_legacy_v1(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select path_tokens[$1] as folder
           from storage.objects
             where objects.name ilike $2 || $3 || ''%''
               and bucket_id = $4
               and array_length(objects.path_tokens, 1) <> $1
           group by folder
           order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v1_optimised(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v1_optimised(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select (string_to_array(name, ''/''))[level] as name
           from storage.prefixes
             where lower(prefixes.name) like lower($2 || $3) || ''%''
               and bucket_id = $4
               and level = $1
           order by name ' || v_sort_order || '
     )
     (select name,
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[level] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where lower(objects.name) like lower($2 || $3) || ''%''
       and bucket_id = $4
       and level = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
    RETURN query EXECUTE
        $sql$
        SELECT * FROM (
            (
                SELECT
                    split_part(name, '/', $4) AS key,
                    name || '/' AS name,
                    NULL::uuid AS id,
                    NULL::timestamptz AS updated_at,
                    NULL::timestamptz AS created_at,
                    NULL::jsonb AS metadata
                FROM storage.prefixes
                WHERE name COLLATE "C" LIKE $1 || '%'
                AND bucket_id = $2
                AND level = $4
                AND name COLLATE "C" > $5
                ORDER BY prefixes.name COLLATE "C" LIMIT $3
            )
            UNION ALL
            (SELECT split_part(name, '/', $4) AS key,
                name,
                id,
                updated_at,
                created_at,
                metadata
            FROM storage.objects
            WHERE name COLLATE "C" LIKE $1 || '%'
                AND bucket_id = $2
                AND level = $4
                AND name COLLATE "C" > $5
            ORDER BY name COLLATE "C" LIMIT $3)
        ) obj
        ORDER BY name COLLATE "C" LIMIT $3;
        $sql$
        USING prefix, bucket_name, limits, levels, start_after;
END;
$_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


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
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb,
    level integer
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: prefixes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.prefixes (
    bucket_id text NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    level integer GENERATED ALWAYS AS (storage.get_level(name)) STORED NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	b18363b1-90d7-4763-9a6a-1f1f1d9b8a04	{"action":"user_confirmation_requested","actor_id":"2c90fe1c-2eb9-453b-989e-243d2fd1cee8","actor_username":"zsolt.tasnadi@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2025-08-07 11:35:03.315931+00	
00000000-0000-0000-0000-000000000000	78f6d9bb-6321-439b-b289-43cba17fd11b	{"action":"user_confirmation_requested","actor_id":"be68af34-0619-4805-907e-01fbc1bc2741","actor_username":"brad.pitt.budapest@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2025-08-07 11:35:29.801903+00	
00000000-0000-0000-0000-000000000000	1fde52ea-583b-42cc-8724-5233a5ab7187	{"action":"user_confirmation_requested","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2025-08-07 11:35:31.187001+00	
00000000-0000-0000-0000-000000000000	1ef7f14a-fefa-4a98-bdc3-c0531fb79fc4	{"action":"login","actor_id":"2c90fe1c-2eb9-453b-989e-243d2fd1cee8","actor_username":"zsolt.tasnadi@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 11:38:18.187746+00	
00000000-0000-0000-0000-000000000000	35f2de03-fdad-4be1-9b54-1610fc210746	{"action":"login","actor_id":"be68af34-0619-4805-907e-01fbc1bc2741","actor_username":"brad.pitt.budapest@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 11:38:18.81039+00	
00000000-0000-0000-0000-000000000000	642d5d06-7484-44b4-875d-20dcc9f26fa9	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 11:38:19.508404+00	
00000000-0000-0000-0000-000000000000	02b1a5a4-979a-4b75-8a6a-b50c82257241	{"action":"login","actor_id":"2c90fe1c-2eb9-453b-989e-243d2fd1cee8","actor_username":"zsolt.tasnadi@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 11:58:06.219007+00	
00000000-0000-0000-0000-000000000000	5d3fb537-f9f3-4ed9-83b0-ebad2b36f188	{"action":"logout","actor_id":"2c90fe1c-2eb9-453b-989e-243d2fd1cee8","actor_username":"zsolt.tasnadi@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 11:58:55.900501+00	
00000000-0000-0000-0000-000000000000	dc40d2f1-86d5-4ca7-9469-ae399e1d22d5	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 11:59:04.095241+00	
00000000-0000-0000-0000-000000000000	c241591a-4202-4332-ae6b-6a4c1f085c14	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 12:01:13.653659+00	
00000000-0000-0000-0000-000000000000	312e2a0a-3f32-4444-92c9-4eafcb6044e8	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 12:01:16.952457+00	
00000000-0000-0000-0000-000000000000	c287a3cb-0094-4ce0-9d9c-e4562bc89f05	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 12:05:11.782447+00	
00000000-0000-0000-0000-000000000000	7d319110-e08a-4b9f-a894-2fd6af1f876a	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 12:05:14.588442+00	
00000000-0000-0000-0000-000000000000	4f8bafa8-228c-42a5-be65-4dc5f92c277f	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 12:10:59.634249+00	
00000000-0000-0000-0000-000000000000	678cd2a3-2f9f-4b98-a3ce-051d3531c3ab	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 12:11:06.079553+00	
00000000-0000-0000-0000-000000000000	20f780db-2d73-45bf-a4ed-0d527e4175c0	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 15:38:26.0203+00	
00000000-0000-0000-0000-000000000000	09534946-a840-4668-ab05-83a49ed765bb	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 15:38:26.021233+00	
00000000-0000-0000-0000-000000000000	563c2ad2-0a15-4d07-8c8a-f37951f70160	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 15:38:27.728526+00	
00000000-0000-0000-0000-000000000000	caa47f24-2606-44b0-829a-5ff9c0ce90cb	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 15:38:31.104957+00	
00000000-0000-0000-0000-000000000000	ec243012-d7ff-414e-9930-f59587eb3795	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 15:39:51.868779+00	
00000000-0000-0000-0000-000000000000	076a6d1a-ff6e-46de-90a0-32830de23591	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 15:40:54.482792+00	
00000000-0000-0000-0000-000000000000	fef919a2-7fa6-491b-b824-82f3dddfa1d1	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 15:51:07.565304+00	
00000000-0000-0000-0000-000000000000	9ca07849-e7c1-46ab-a9f6-b73e6df17937	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 15:51:13.263674+00	
00000000-0000-0000-0000-000000000000	921bb7da-403d-4fc5-816d-ebd8328913a1	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 15:52:11.910091+00	
00000000-0000-0000-0000-000000000000	60a67a9e-8f87-459b-ba9a-72e09536a6b0	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 15:52:14.648078+00	
00000000-0000-0000-0000-000000000000	8ddb0e0d-7969-4674-9e56-4b13144d364b	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 16:09:43.26953+00	
00000000-0000-0000-0000-000000000000	f7de9a77-d985-4b2c-acac-43e05360b22b	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 16:09:50.147261+00	
00000000-0000-0000-0000-000000000000	06ecd82b-1acd-4350-80cf-2a7c51db5119	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-07 16:11:33.045795+00	
00000000-0000-0000-0000-000000000000	c0af2711-2a17-418c-ac68-228dea6020af	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 16:11:37.927314+00	
00000000-0000-0000-0000-000000000000	7f26da95-4e5e-4f05-a088-bfaed2f68ca9	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 19:08:00.506149+00	
00000000-0000-0000-0000-000000000000	deea62e9-0ea8-46c0-9025-b277c73a8a81	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 19:08:00.507071+00	
00000000-0000-0000-0000-000000000000	4f5f4f0d-914d-4d38-af62-812d9e6667cc	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 23:10:29.000994+00	
00000000-0000-0000-0000-000000000000	75457544-dcee-445c-82cf-2de97177a492	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-07 23:10:29.002001+00	
00000000-0000-0000-0000-000000000000	83363e20-532c-4de0-90dd-94152d74c9a8	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-07 23:10:32.826393+00	
00000000-0000-0000-0000-000000000000	4e3b0303-e589-4430-b2ed-4d1834ddbe28	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 00:05:45.034927+00	
00000000-0000-0000-0000-000000000000	5d3e81b3-ae27-41e4-a837-721a8e4ba70f	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 00:13:25.795136+00	
00000000-0000-0000-0000-000000000000	74b52e0b-21d2-4951-8822-87c0f69ed251	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 00:13:25.796019+00	
00000000-0000-0000-0000-000000000000	a854bc62-7738-459f-9ad3-02c197ee9c25	{"action":"logout","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account"}	2025-08-08 00:14:49.498263+00	
00000000-0000-0000-0000-000000000000	e64ba638-98cc-4dfa-8d8a-9141c4064137	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 00:14:53.446233+00	
00000000-0000-0000-0000-000000000000	7286f6aa-622e-439d-a639-741b12dda0f7	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 00:25:33.558642+00	
00000000-0000-0000-0000-000000000000	03ebfa87-1502-4813-a262-67945018801f	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 00:29:28.394328+00	
00000000-0000-0000-0000-000000000000	e1215e65-3a17-4a14-9538-94d0f228420b	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 00:31:10.864668+00	
00000000-0000-0000-0000-000000000000	423f13ab-875b-4890-a575-83517952b115	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 05:43:32.995451+00	
00000000-0000-0000-0000-000000000000	0aa104ee-4f7d-4adc-9237-9ed533c5c76d	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 05:43:32.996416+00	
00000000-0000-0000-0000-000000000000	47f1c279-86e8-438d-8fbb-b79de3db0567	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 06:58:20.059104+00	
00000000-0000-0000-0000-000000000000	192ab265-0ab6-4cd0-8e02-43c59ccca397	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 06:58:20.060047+00	
00000000-0000-0000-0000-000000000000	cdab6cda-b8a2-47f7-a20d-ad6a3b223188	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 08:07:54.076769+00	
00000000-0000-0000-0000-000000000000	52b89e63-a6df-419e-a543-edbde471ee37	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 08:07:54.077738+00	
00000000-0000-0000-0000-000000000000	f706b578-8e0c-43b7-835f-bd74c06caa98	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 08:54:28.757196+00	
00000000-0000-0000-0000-000000000000	300d57c2-047f-400e-95a0-3ef010a38699	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 21:04:54.223652+00	
00000000-0000-0000-0000-000000000000	f99a3d19-1a1f-4f66-8aa5-4f67f2637422	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 21:04:54.224487+00	
00000000-0000-0000-0000-000000000000	0c8fd5d8-b7fd-4fe6-9a17-35d955d957aa	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 21:07:52.904244+00	
00000000-0000-0000-0000-000000000000	500c9055-1d8b-4ed8-8a39-17753bf92083	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 21:12:56.152584+00	
00000000-0000-0000-0000-000000000000	7b4537a0-f256-4ecc-9428-2a873e9fe463	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 21:18:09.851761+00	
00000000-0000-0000-0000-000000000000	b6d01806-35a4-4d4c-9e61-1cac2609be33	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-08 21:23:44.061729+00	
00000000-0000-0000-0000-000000000000	d3ce6753-a49f-4010-90ba-a9decf7d6dc5	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 22:04:17.845176+00	
00000000-0000-0000-0000-000000000000	52ea63fb-bd21-46be-9d61-b5f2ec524b30	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-08 22:04:17.846005+00	
00000000-0000-0000-0000-000000000000	17f0b4de-daa2-4832-a0d1-4805902a06e5	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 05:10:26.119435+00	
00000000-0000-0000-0000-000000000000	87e6bdde-30be-4264-a3e4-838c3c2256df	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 05:10:26.120342+00	
00000000-0000-0000-0000-000000000000	2e5decf4-47df-4ffc-813a-036f8d2626b3	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 06:12:43.908631+00	
00000000-0000-0000-0000-000000000000	333d8e3a-efff-402a-854e-ff6698f8f7a5	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 06:12:43.909484+00	
00000000-0000-0000-0000-000000000000	04521f87-4fd8-4f7d-ae4e-6b2cb1a4aa1a	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 07:38:50.195658+00	
00000000-0000-0000-0000-000000000000	c05a5f6e-dde9-4a51-804d-ad42649fffd4	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 07:38:50.196592+00	
00000000-0000-0000-0000-000000000000	71b5761b-9d99-4f3d-a711-4b0fc504fb98	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 09:25:09.693907+00	
00000000-0000-0000-0000-000000000000	63a674c6-c0b0-4d7d-a99c-7addcade8e19	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 09:25:09.694876+00	
00000000-0000-0000-0000-000000000000	5c5d79ce-7ee4-4d2f-837b-ece2dde9eac1	{"action":"login","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-08-09 09:59:49.174593+00	
00000000-0000-0000-0000-000000000000	1d858dcd-8b70-419d-acb0-10d6de2d1cb9	{"action":"token_refreshed","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 10:29:04.277487+00	
00000000-0000-0000-0000-000000000000	bc805bc7-6eb7-45ab-a681-a2af4a6e014a	{"action":"token_revoked","actor_id":"1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3","actor_username":"vidamkos@gmail.com","actor_via_sso":false,"log_type":"token"}	2025-08-09 10:29:04.278371+00	
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
2c90fe1c-2eb9-453b-989e-243d2fd1cee8	2c90fe1c-2eb9-453b-989e-243d2fd1cee8	{"sub": "2c90fe1c-2eb9-453b-989e-243d2fd1cee8", "email": "zsolt.tasnadi@gmail.com", "last_name": "Tasnadi", "user_role": "school_admin", "first_name": "Zsolt", "email_verified": false, "phone_verified": false}	email	2025-08-07 11:35:03.309696+00	2025-08-07 11:35:03.310665+00	2025-08-07 11:35:03.310665+00	44968044-eda4-4c4b-9502-a35de3b8a219
be68af34-0619-4805-907e-01fbc1bc2741	be68af34-0619-4805-907e-01fbc1bc2741	{"sub": "be68af34-0619-4805-907e-01fbc1bc2741", "email": "brad.pitt.budapest@gmail.com", "last_name": "Pitt", "user_role": "teacher", "first_name": "Brad", "email_verified": false, "phone_verified": false}	email	2025-08-07 11:35:29.799791+00	2025-08-07 11:35:29.799837+00	2025-08-07 11:35:29.799837+00	8fb9b8e5-a2a1-4d6b-874b-9ccfc33fc41b
1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	{"sub": "1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3", "email": "vidamkos@gmail.com", "last_name": "Kós", "user_role": "student", "first_name": "Vidam", "email_verified": false, "phone_verified": false}	email	2025-08-07 11:35:31.184818+00	2025-08-07 11:35:31.184876+00	2025-08-07 11:35:31.184876+00	e7ed89a4-986c-4a60-a92e-f06ec2601d5f
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
828a4c82-9c60-4f3b-85cd-d6914b8c15e8	2025-08-07 11:38:18.813211+00	2025-08-07 11:38:18.813211+00	password	570794e0-140d-4b4a-a7f6-c4fc5f8f52a8
37f21841-9154-4c2e-9f41-58bebb4b1cb8	2025-08-08 00:14:53.44976+00	2025-08-08 00:14:53.44976+00	password	afc8d2f5-2e42-405f-92a8-26b7a71be4f5
ec25e896-726d-4921-94e6-57752a23674b	2025-08-08 00:25:33.563054+00	2025-08-08 00:25:33.563054+00	password	9244d663-f019-4821-b9d3-b4357d9e4a0b
796cf647-a016-477b-b601-4d569b4d219e	2025-08-08 00:29:28.398787+00	2025-08-08 00:29:28.398787+00	password	c082755d-04d3-45a3-8824-7bf441741c97
61ed8c6d-eb4c-49f1-99a5-fead62783249	2025-08-08 00:31:10.869521+00	2025-08-08 00:31:10.869521+00	password	8ae5fba1-a139-42da-a34c-44388d3ef4b5
aa097fd0-1bf6-44c6-83c2-40051f22d1e2	2025-08-08 08:54:28.76152+00	2025-08-08 08:54:28.76152+00	password	96c73b5a-1a60-4f85-9738-884e2a1c767a
87a13ead-adf3-4d4e-b0e5-e5d08bb1c9d3	2025-08-08 21:07:52.908503+00	2025-08-08 21:07:52.908503+00	password	f89b33a0-4761-419a-b4fb-0ab74e244715
8f8ce8df-362d-4240-8caa-dd9f4831ce92	2025-08-08 21:12:56.156831+00	2025-08-08 21:12:56.156831+00	password	8884d814-7aeb-4c4a-b1e4-e13e820a1401
607f7e8a-f7c7-4f48-9948-5433083f61c4	2025-08-08 21:18:09.855936+00	2025-08-08 21:18:09.855936+00	password	a2e0e9cf-3773-483c-912f-ee05985a030b
7de16ca7-c6d5-4910-88a6-ed1b02a3b2e4	2025-08-08 21:23:44.066433+00	2025-08-08 21:23:44.066433+00	password	2ff0abbf-09ba-4b7f-a3cb-8173bb1d2eee
979ff0fc-00c8-4a81-b59c-3a3593d22845	2025-08-09 09:59:49.178975+00	2025-08-09 09:59:49.178975+00	password	b48641de-e6f4-4e3b-8ff0-35438af7e5bc
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
5b897f13-851e-49bf-a233-b071523e4815	2c90fe1c-2eb9-453b-989e-243d2fd1cee8	confirmation_token	60077df7a18bef433a59fc273849b649a3ccaf2465d52b4a8166a82a	zsolt.tasnadi@gmail.com	2025-08-07 11:35:04.500839	2025-08-07 11:35:04.500839
9b50826b-f0b5-4f8b-af64-17b7760baecf	be68af34-0619-4805-907e-01fbc1bc2741	confirmation_token	5a5d7d3faf3d5afc63c24ab0abe22334fa22f51d3c537997f5f2dd8d	brad.pitt.budapest@gmail.com	2025-08-07 11:35:30.743462	2025-08-07 11:35:30.743462
192795f7-4919-47bd-84f7-4774c23268bb	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	confirmation_token	bd68e3ea0b5cd3c36c00d5bac90af3a99f12e143860e2e6bbaa74783	vidamkos@gmail.com	2025-08-07 11:35:32.153921	2025-08-07 11:35:32.153921
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	2	n2ukmus5nsxf	be68af34-0619-4805-907e-01fbc1bc2741	f	2025-08-07 11:38:18.811971+00	2025-08-07 11:38:18.811971+00	\N	828a4c82-9c60-4f3b-85cd-d6914b8c15e8
00000000-0000-0000-0000-000000000000	22	3jhfbpipoipl	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 00:25:33.560938+00	2025-08-08 00:25:33.560938+00	\N	ec25e896-726d-4921-94e6-57752a23674b
00000000-0000-0000-0000-000000000000	23	yicgqk5gh3vr	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 00:29:28.396685+00	2025-08-08 00:29:28.396685+00	\N	796cf647-a016-477b-b601-4d569b4d219e
00000000-0000-0000-0000-000000000000	24	nb7dchxytha4	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 00:31:10.867083+00	2025-08-08 00:31:10.867083+00	\N	61ed8c6d-eb4c-49f1-99a5-fead62783249
00000000-0000-0000-0000-000000000000	21	mbpzvehu7ni3	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 00:14:53.448026+00	2025-08-08 05:43:32.997075+00	\N	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	25	nvj7srkyny2e	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 05:43:32.997858+00	2025-08-08 06:58:20.060626+00	mbpzvehu7ni3	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	26	gd4wshyg2ugs	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 06:58:20.061297+00	2025-08-08 08:07:54.07834+00	nvj7srkyny2e	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	28	gjjmrrhneslg	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 08:54:28.759512+00	2025-08-08 08:54:28.759512+00	\N	aa097fd0-1bf6-44c6-83c2-40051f22d1e2
00000000-0000-0000-0000-000000000000	27	oog2xbm6d3fe	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 08:07:54.079084+00	2025-08-08 21:04:54.225065+00	gd4wshyg2ugs	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	30	ryartqs5vkcp	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 21:07:52.906464+00	2025-08-08 21:07:52.906464+00	\N	87a13ead-adf3-4d4e-b0e5-e5d08bb1c9d3
00000000-0000-0000-0000-000000000000	31	3o3phtsvs62y	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 21:12:56.154831+00	2025-08-08 21:12:56.154831+00	\N	8f8ce8df-362d-4240-8caa-dd9f4831ce92
00000000-0000-0000-0000-000000000000	32	jm7nvpg2z4ol	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 21:18:09.85397+00	2025-08-08 21:18:09.85397+00	\N	607f7e8a-f7c7-4f48-9948-5433083f61c4
00000000-0000-0000-0000-000000000000	33	wuiggp5m7wxo	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-08 21:23:44.064151+00	2025-08-08 21:23:44.064151+00	\N	7de16ca7-c6d5-4910-88a6-ed1b02a3b2e4
00000000-0000-0000-0000-000000000000	29	yyg4kc2myypx	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 21:04:54.225745+00	2025-08-08 22:04:17.846558+00	oog2xbm6d3fe	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	34	tunyezblmiuh	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-08 22:04:17.847258+00	2025-08-09 05:10:26.120893+00	yyg4kc2myypx	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	35	yjuidyiisrig	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-09 05:10:26.12156+00	2025-08-09 06:12:43.91004+00	tunyezblmiuh	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	36	qaduc6sruyj6	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-09 06:12:43.91076+00	2025-08-09 07:38:50.197262+00	yjuidyiisrig	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	37	2nf4cla3glhk	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-09 07:38:50.198034+00	2025-08-09 09:25:09.695512+00	qaduc6sruyj6	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	39	gp2wpstauv5p	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-09 09:59:49.176977+00	2025-08-09 09:59:49.176977+00	\N	979ff0fc-00c8-4a81-b59c-3a3593d22845
00000000-0000-0000-0000-000000000000	38	7y34kufw57fk	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	t	2025-08-09 09:25:09.696251+00	2025-08-09 10:29:04.278946+00	2nf4cla3glhk	37f21841-9154-4c2e-9f41-58bebb4b1cb8
00000000-0000-0000-0000-000000000000	40	esf3zf4tsrzd	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	f	2025-08-09 10:29:04.280437+00	2025-08-09 10:29:04.280437+00	7y34kufw57fk	37f21841-9154-4c2e-9f41-58bebb4b1cb8
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag) FROM stdin;
828a4c82-9c60-4f3b-85cd-d6914b8c15e8	be68af34-0619-4805-907e-01fbc1bc2741	2025-08-07 11:38:18.81117+00	2025-08-07 11:38:18.81117+00	\N	aal1	\N	\N	curl/8.7.1	37.76.36.195	\N
979ff0fc-00c8-4a81-b59c-3a3593d22845	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-09 09:59:49.175774+00	2025-08-09 09:59:49.175774+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36	188.36.10.32	\N
37f21841-9154-4c2e-9f41-58bebb4b1cb8	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 00:14:53.447068+00	2025-08-09 10:29:04.282946+00	\N	aal1	\N	2025-08-09 10:29:04.282877	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36	188.36.10.32	\N
ec25e896-726d-4921-94e6-57752a23674b	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 00:25:33.559751+00	2025-08-08 00:25:33.559751+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	194.48.175.48	\N
796cf647-a016-477b-b601-4d569b4d219e	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 00:29:28.395476+00	2025-08-08 00:29:28.395476+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	194.48.175.48	\N
61ed8c6d-eb4c-49f1-99a5-fead62783249	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 00:31:10.865821+00	2025-08-08 00:31:10.865821+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	194.48.175.48	\N
aa097fd0-1bf6-44c6-83c2-40051f22d1e2	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 08:54:28.758362+00	2025-08-08 08:54:28.758362+00	\N	aal1	\N	\N	curl/8.7.1	194.48.175.48	\N
87a13ead-adf3-4d4e-b0e5-e5d08bb1c9d3	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 21:07:52.90532+00	2025-08-08 21:07:52.90532+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	188.36.10.32	\N
8f8ce8df-362d-4240-8caa-dd9f4831ce92	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 21:12:56.153703+00	2025-08-08 21:12:56.153703+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	188.36.10.32	\N
607f7e8a-f7c7-4f48-9948-5433083f61c4	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 21:18:09.852847+00	2025-08-08 21:18:09.852847+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	188.36.10.32	\N
7de16ca7-c6d5-4910-88a6-ed1b02a3b2e4	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 21:23:44.062925+00	2025-08-08 21:23:44.062925+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36	188.36.10.32	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	be68af34-0619-4805-907e-01fbc1bc2741	authenticated	authenticated	brad.pitt.budapest@gmail.com	$2a$10$mfW9Utwn74bc3kqGtpUeduP/YTtAJecblFz5oPZixZ2hFCocHXxUO	2025-08-07 11:38:02.153609+00	\N	5a5d7d3faf3d5afc63c24ab0abe22334fa22f51d3c537997f5f2dd8d	2025-08-07 11:35:29.802444+00		\N			\N	2025-08-07 11:38:18.811096+00	{"provider": "email", "providers": ["email"]}	{"sub": "be68af34-0619-4805-907e-01fbc1bc2741", "email": "brad.pitt.budapest@gmail.com", "last_name": "Pitt", "user_role": "teacher", "first_name": "Brad", "email_verified": false, "phone_verified": false}	\N	2025-08-07 11:35:29.797432+00	2025-08-07 11:38:18.812879+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	2c90fe1c-2eb9-453b-989e-243d2fd1cee8	authenticated	authenticated	zsolt.tasnadi@gmail.com	$2a$10$Bv8y6IdNGvv6ZQ2w7kwJ.etz.Dv/QjyqHWtmng/Q7zOouTJWXGHRy	2025-08-07 11:38:02.153609+00	\N	60077df7a18bef433a59fc273849b649a3ccaf2465d52b4a8166a82a	2025-08-07 11:35:03.318557+00		\N			\N	2025-08-07 11:58:06.221371+00	{"provider": "email", "providers": ["email"]}	{"sub": "2c90fe1c-2eb9-453b-989e-243d2fd1cee8", "email": "zsolt.tasnadi@gmail.com", "last_name": "Tasnadi", "user_role": "school_admin", "first_name": "Zsolt", "email_verified": false, "phone_verified": false}	\N	2025-08-07 11:35:03.288719+00	2025-08-07 11:58:06.224121+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	authenticated	authenticated	vidamkos@gmail.com	$2a$10$200fdVtL9UjAJUHK4HwJIOYNVnFaMc6nwA7pcdJ/D4VRaf8pmtVF6	2025-08-07 11:38:02.153609+00	\N	bd68e3ea0b5cd3c36c00d5bac90af3a99f12e143860e2e6bbaa74783	2025-08-07 11:35:31.187491+00		\N			\N	2025-08-09 09:59:49.175668+00	{"provider": "email", "providers": ["email"]}	{"sub": "1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3", "email": "vidamkos@gmail.com", "last_name": "Kós", "user_role": "student", "first_name": "Vidam", "email_verified": false, "phone_verified": false}	\N	2025-08-07 11:35:31.182506+00	2025-08-09 10:29:04.281603+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: card_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.card_categories (id, card_id, category_id, created_at) FROM stdin;
c8f3c972-83cf-457d-9d0e-cf95cb5525df	a870f5b6-02da-4ee4-a3f4-baace59cea3d	d1da0869-3e25-4097-92eb-5a74ac41be9f	2025-08-08 08:33:58.215623+00
2a6f7a48-7c54-4177-a77b-553c5e7832f1	54b0ec84-163d-4cc7-96b3-1cf031a69e79	d1da0869-3e25-4097-92eb-5a74ac41be9f	2025-08-08 21:33:26.853493+00
e56992f1-c85d-4cc9-8071-b430ddf0e236	54b0ec84-163d-4cc7-96b3-1cf031a69e79	4dcf65bb-7548-4018-b154-636a1f214eb2	2025-08-08 21:33:26.853493+00
\.


--
-- Data for Name: card_interactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.card_interactions (id, session_id, card_id, direction, reaction_time, feedback_type, interaction_type, "timestamp", created_at) FROM stdin;
\.


--
-- Data for Name: cards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cards (id, title, english_title, title_formatted, english_title_formatted, image_url, image_alt, media_type, media_url, category, difficulty_level, user_id, is_public, created_at, updated_at, set_id, category_id, flashcard_set_id, front_text, back_text, front_image_url, back_image_url, is_mock) FROM stdin;
c8cbd6b1-c801-4361-9e45-4c9b88562575	tűzhely	stove	tűzhely	stove	\N	tűzhely - stove	\N	\N	\N	1	\N	f	2025-08-08 08:08:52.062699+00	2025-08-08 08:08:52.062699+00	\N	\N	\N	\N	\N	\N	\N	f
7df8a220-467d-49f9-b161-b13a5ac75f1e	tűzhely	stove	tűzhely	stove	\N	tűzhely - stove	\N	\N	\N	1	\N	f	2025-08-08 08:12:14.465802+00	2025-08-08 08:12:14.465802+00	\N	\N	\N	\N	\N	\N	\N	f
a870f5b6-02da-4ee4-a3f4-baace59cea3d	tűzhely	stove	tűzhely	stove	\N	tűzhely - stove	\N	\N	\N	1	\N	f	2025-08-08 08:12:32.201455+00	2025-08-08 08:12:32.201455+00	\N	\N	\N	\N	\N	\N	\N	f
54b0ec84-163d-4cc7-96b3-1cf031a69e79	konyhapult	kitchen counter	konyhapult	kitchen counter	\N	konyhapult - kitchen counter	\N	\N	\N	1	\N	f	2025-08-08 08:41:28.010812+00	2025-08-08 08:41:28.010812+00	\N	\N	\N	\N	\N	\N	\N	f
623dac1d-9002-43f7-b14a-7033401b87e2	útlevél	passport	útlevél	passport		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.009998+00	2025-08-08 22:36:34.009998+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
753a8df1-0383-4438-8a81-ecfb328d7880	vonat	train	vonat	train		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.175612+00	2025-08-08 22:36:34.175612+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
a5b3fcfd-050f-4ca1-8324-1d238dd07944	buszmegálló	bus stop	buszmegálló	bus stop		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.341612+00	2025-08-08 22:36:34.341612+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
26a31801-1689-45f9-87ad-53283a73c731	metró	subway	metró	subway		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.507749+00	2025-08-08 22:36:34.507749+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
50634f1b-77f9-41aa-826f-0d0ec2a21a0b	menetrend	timetable	menetrend	timetable		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.675958+00	2025-08-08 22:36:34.675958+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
1ec33efb-b0cb-4090-a264-309a93f9035f	beszállás	boarding	beszállás	boarding		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:34.841531+00	2025-08-08 22:36:34.841531+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
fdec52c8-dab1-476f-809e-fe956b2b181c	indulás	departure	indulás	departure		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.008627+00	2025-08-08 22:36:35.008627+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
7b0fed6d-b7ee-4f6e-96bb-ca9162c456c9	érkezés	arrival	érkezés	arrival		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.172876+00	2025-08-08 22:36:35.172876+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
0a0db511-4383-41ab-8e2e-144ab42ad965	úticél	destination	úticél	destination		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.336395+00	2025-08-08 22:36:35.336395+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
02b7f2c1-e2d0-41bc-90a6-43a961d778b4	turista	tourist	turista	tourist		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.500304+00	2025-08-08 22:36:35.500304+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
eabd5000-e910-4df8-9b5f-8dd09efb448b	autókölcsönző	car rental	autókölcsönző	car rental		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.672419+00	2025-08-08 22:36:35.672419+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
4b5de602-6505-40fd-902b-569332113987	biztonsági ellenőrzés	security check	biztonsági ellenőrzés	security check		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.825096+00	2025-08-08 22:36:35.825096+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
fa8d62d4-b434-4a2e-8021-156602edd6e0	beszállókártya	boarding pass	beszállókártya	boarding pass		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:35.988614+00	2025-08-08 22:36:35.988614+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
00a2aeaa-1328-441c-8985-f64b5e29b78f	útlevél-ellenőrzés	passport control	útlevél-ellenőrzés	passport control		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:36.151446+00	2025-08-08 22:36:36.151446+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
253af5fd-e258-4c54-807d-ab3b3fee2dc0	kézipoggyász	hand luggage	kézipoggyász	hand luggage		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:36.310401+00	2025-08-08 22:36:36.310401+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
81a30b4f-910d-4dc7-81fe-7fa9dd77f0b2	fedélzet	on board	fedélzet	on board		\N	text	\N	\N	1	\N	f	2025-08-08 22:36:36.46913+00	2025-08-08 22:36:36.46913+00	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	\N	\N	\N	\N	\N	\N	f
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (id, name, color, description, is_active, created_by, is_mock, created_at, updated_at) FROM stdin;
477a6888-6ea5-4b03-85b2-78d81b6080e7	butor	\N	\N	t	\N	f	2025-08-07 23:56:44.497151+00	2025-08-07 23:56:44.497151+00
68f95220-6041-412c-b227-7d77da22340a	épület	\N	\N	t	\N	f	2025-08-07 23:56:44.672546+00	2025-08-07 23:56:44.672546+00
d1da0869-3e25-4097-92eb-5a74ac41be9f	belső helység	\N	Automatikusan létrehozott kategória: belső helység	t	\N	f	2025-08-08 08:31:58.702127+00	2025-08-08 08:31:58.702127+00
11bffc46-8ccb-4d8a-abbc-c5224f17fd45	hideg	\N	Automatikusan létrehozott kategória: hideg	t	\N	f	2025-08-08 08:41:28.426046+00	2025-08-08 08:41:28.426046+00
4dcf65bb-7548-4018-b154-636a1f214eb2	elek	\N	Automatikusan létrehozott kategória: elek	t	\N	f	2025-08-08 21:33:26.775374+00	2025-08-08 21:33:26.775374+00
25e8d383-6a91-496e-8630-be6769bf5d1a	utazás	\N	\N	t	\N	f	2025-08-08 22:36:02.810605+00	2025-08-08 22:36:02.810605+00
\.


--
-- Data for Name: classroom_details; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.classroom_details (id, classroom_id, subject, grade_level, academic_year, meeting_schedule, additional_info, is_mock, created_at, updated_at, name, description, invite_code, is_active, teacher_email, teacher_first_name, teacher_last_name, student_count) FROM stdin;
\.


--
-- Data for Name: classroom_members; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.classroom_members (id, classroom_id, user_id, role, joined_at, is_active, is_mock, created_at, student_id) FROM stdin;
\.


--
-- Data for Name: classroom_sets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.classroom_sets (id, classroom_id, set_id, assigned_by, assigned_at, due_date, is_required, is_mock, created_at) FROM stdin;
\.


--
-- Data for Name: classrooms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.classrooms (id, name, description, teacher_id, school_id, access_code, is_active, max_students, is_mock, created_at, updated_at, invite_code) FROM stdin;
\.


--
-- Data for Name: favicons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.favicons (id, domain, favicon_url, last_updated, is_active, fetch_attempts, last_fetch_attempt, created_at) FROM stdin;
410ad964-fdee-4a87-8d72-1e359aa209c9	snappycards.app	data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPCEtLSBCYWNrZ3JvdW5kIC0tPgo8cmVjdCB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHJ4PSI0IiBmaWxsPSIjNjM2NmYxIi8+CjwhLS0gQ2FyZCBTaGFwZSAtLT4KPHJlY3QgeD0iNCIgeT0iNiIgd2lkdGg9IjI0IiBoZWlnaHQ9IjE2IiByeD0iMyIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjZGRkZGRkIiBzdHJva2Utd2lkdGg9IjAuNSIvPgo8IS0tIFRleHQgUyAtLT4KPHRleHQgeD0iMTYiIHk9IjE4IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNjM2NmYxIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkb21pbmFudC1iYXNlbGluZT0iY2VudHJhbCI+UzwvdGV4dD4KPCEtLSBTbWFsbCBkb3RzIGZvciBmbGFzaGNhcmQgZWZmZWN0IC0tPgo8Y2lyY2xlIGN4PSI4IiBjeT0iMTAiIHI9IjEiIGZpbGw9IiM2MzY2ZjEiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIxOCIgcj0iMSIgZmlsbD0iIzYzNjZmMSIvPgo8L3N2Zz4K	2025-08-04 22:18:16.773773+00	t	1	2025-08-04 22:18:16.773773+00	2025-08-04 22:18:16.773773+00
\.


--
-- Data for Name: flashcard_set_cards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flashcard_set_cards (id, set_id, card_id, "position", created_at) FROM stdin;
f094dc8e-9473-467e-83da-1db1fefdc2a8	438fcd77-e21a-45b3-9c0c-d370d54c3420	a870f5b6-02da-4ee4-a3f4-baace59cea3d	0	2025-08-08 08:17:01.368252+00
dc9fa3ed-eb0d-4dfb-9878-39c2c15d39ab	438fcd77-e21a-45b3-9c0c-d370d54c3420	54b0ec84-163d-4cc7-96b3-1cf031a69e79	0	2025-08-08 08:41:28.118401+00
3e804f24-4690-4545-ac07-a9a58302abbd	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	623dac1d-9002-43f7-b14a-7033401b87e2	4	2025-08-08 22:36:34.091992+00
5ee2b22c-c044-4e57-9c6c-e6d4343f99af	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	753a8df1-0383-4438-8a81-ecfb328d7880	5	2025-08-08 22:36:34.256463+00
ef2f5ba9-c67e-4698-9db9-f9591e4fbf95	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	a5b3fcfd-050f-4ca1-8324-1d238dd07944	6	2025-08-08 22:36:34.427265+00
fbb79c4d-efef-4e4a-a2f6-30e99a2c7a5e	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	26a31801-1689-45f9-87ad-53283a73c731	7	2025-08-08 22:36:34.58873+00
9971e118-2535-4101-80fd-3eb6b715d3a4	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	50634f1b-77f9-41aa-826f-0d0ec2a21a0b	8	2025-08-08 22:36:34.758971+00
962349fd-49cf-4e1a-9588-71caa8a7362c	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	1ec33efb-b0cb-4090-a264-309a93f9035f	9	2025-08-08 22:36:34.921196+00
953462d2-a572-44b8-adc2-5894191a5758	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	fdec52c8-dab1-476f-809e-fe956b2b181c	10	2025-08-08 22:36:35.097061+00
205b0b89-72e5-48ee-9558-a2d60d5c58d8	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	7b0fed6d-b7ee-4f6e-96bb-ca9162c456c9	11	2025-08-08 22:36:35.254655+00
49d6913f-30f2-478c-8740-6553f18e2933	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	0a0db511-4383-41ab-8e2e-144ab42ad965	12	2025-08-08 22:36:35.418621+00
182c5ada-52b0-4bc7-aacb-05ea3c198528	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	02b7f2c1-e2d0-41bc-90a6-43a961d778b4	13	2025-08-08 22:36:35.580778+00
50ec94cf-fb4e-4afb-a249-8d989a49905f	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	eabd5000-e910-4df8-9b5f-8dd09efb448b	14	2025-08-08 22:36:35.746355+00
76f0762a-0b74-4e1e-9d6a-d26b2666669b	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	4b5de602-6505-40fd-902b-569332113987	15	2025-08-08 22:36:35.906858+00
0a9a082e-f83a-4bcc-ad8f-a516c6f4bb44	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	fa8d62d4-b434-4a2e-8021-156602edd6e0	16	2025-08-08 22:36:36.077163+00
0d5871ca-179b-4d92-862b-0051a0fe58ce	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	00a2aeaa-1328-441c-8985-f64b5e29b78f	17	2025-08-08 22:36:36.227736+00
97c0316d-394f-4d59-9754-35efa39429ed	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	253af5fd-e258-4c54-807d-ab3b3fee2dc0	18	2025-08-08 22:36:36.393468+00
39a4e1ed-d2ee-41a7-a00d-59597a253081	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	81a30b4f-910d-4dc7-81fe-7fa9dd77f0b2	19	2025-08-08 22:36:36.546217+00
\.


--
-- Data for Name: flashcard_set_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flashcard_set_categories (id, set_id, category_id, created_at) FROM stdin;
7b8496e1-c05a-4d83-9c1e-12313b69c038	438fcd77-e21a-45b3-9c0c-d370d54c3420	477a6888-6ea5-4b03-85b2-78d81b6080e7	2025-08-09 10:34:57.121874+00
f05228ed-4092-4545-af51-0653cf785a70	438fcd77-e21a-45b3-9c0c-d370d54c3420	68f95220-6041-412c-b227-7d77da22340a	2025-08-09 10:34:57.121874+00
\.


--
-- Data for Name: flashcard_sets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flashcard_sets (id, title, description, language_a, language_b, category, difficulty_level, is_public, user_id, created_at, updated_at, language_a_code, language_b_code, creator_id, is_mock) FROM stdin;
faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	Utazás és közlekedés	\N	Hungarian	English	\N	\N	f	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-08 22:36:02.58424+00	2025-08-08 22:36:02.58424+00	\N	\N	\N	f
438fcd77-e21a-45b3-9c0c-d370d54c3420	konyha	Tarjányi Péter történelmi példával magyarázta aggályait: „1938-ban Münchenben területeket adtak át Hitlernek »a béke érdekében«. Egy év múlva világháború tört ki. Mert az agresszor ilyenkor nem megnyugszik, hanem erőt merít”. A szakértő hangsúlyozza: „Meg kell értenünk, a béke nem az erőszak jutalmazásából születik. Soha! Hanem abból, ha helyreáll az igazság, és kimondjuk: ez többé nem ismétlődhet meg.”	Hungarian	English	\N	\N	f	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	2025-08-07 23:56:44.303341+00	2025-08-09 10:34:56.782347+00	\N	\N	\N	f
\.


--
-- Data for Name: language_translations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.language_translations (id, language_id, display_language_code, translated_name, created_at) FROM stdin;
8937b659-74c7-458d-94e3-b35aff3b8ec0	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	hu	magyar	2025-08-08 22:03:12.22785+00
007b43b5-4131-4fb6-b6b3-359453b423b7	169f71bd-2568-4be5-98ed-7b466461c5bd	hu	angol	2025-08-08 22:03:12.22785+00
c61843cc-f1d8-448f-9dca-c3818b16b745	b0b5a636-6271-455e-84c6-169a0f4d187f	hu	német	2025-08-08 22:03:12.22785+00
543760a0-d037-4ab4-a22e-9033ff8360bf	40acb851-ec89-40d7-acc1-0cfc5465ebe6	hu	thai	2025-08-08 22:03:12.22785+00
0e5de342-cd5e-4d5d-a840-657528075d02	ab15e65e-3267-432b-9b85-46ad443b445e	hu	francia	2025-08-08 22:03:12.22785+00
ba4e3d61-7fb4-4c58-9c28-4f8ff0b29eb9	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	hu	olasz	2025-08-08 22:03:12.22785+00
d38ed524-592c-434d-8ddf-a1fc438f45f9	f511193a-f362-4bf8-aa68-b19bebd2bf0f	hu	spanyol	2025-08-08 22:03:12.22785+00
4b5a2cf9-e027-4092-b20d-35dc45c0d25c	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	hu	orosz	2025-08-08 22:03:12.22785+00
49088cc9-238a-4d05-bf86-00376626b82f	db81101a-caba-4256-8025-65cf7d2ef2ab	hu	lengyel	2025-08-08 22:03:12.22785+00
59d18411-e1d8-4e58-a5e7-318638d7e0e0	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	hu	cseh	2025-08-08 22:03:12.22785+00
c168277b-1f2f-4d36-8892-08ef769a760e	ce560240-8f4f-4970-a96f-06da04581859	hu	szlovák	2025-08-08 22:03:12.22785+00
f718eb1c-17c6-43dc-88a3-ea62e5c280be	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	hu	román	2025-08-08 22:03:12.22785+00
d914eddd-e770-4893-b76c-37d6bf64e4c2	60af38eb-dd45-4afc-8386-cb483f597022	hu	holland	2025-08-08 22:03:12.22785+00
2103055d-ac3c-469b-b1f3-8856b4ace000	043b87b2-c53c-4864-baa3-500beb6d102c	hu	portugál	2025-08-08 22:03:12.22785+00
8e312ac9-1298-4075-b7dd-fe80a79eb5f1	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	hu	svéd	2025-08-08 22:03:12.22785+00
9aced43b-fa65-4182-9a56-41b5e32611c7	a9294b82-7373-4b43-b110-b1f5249ab69f	hu	norvég	2025-08-08 22:03:12.22785+00
28ac4130-d800-4ef9-a54b-e44ab4484a73	0db1ad1f-85fd-4870-b149-f634a958356a	hu	dán	2025-08-08 22:03:12.22785+00
9da8f46a-5663-4c19-92a7-07c5bd63de1e	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	hu	finn	2025-08-08 22:03:12.22785+00
c42462c8-ce48-4404-a7ea-98afda9526fc	c200452a-8b96-40d2-b767-56be9926be7b	hu	görög	2025-08-08 22:03:12.22785+00
d8965539-ffbb-4588-9cb8-8fd6e7b105d8	6220a92d-4412-4e24-bac1-dc54bc49b1cd	hu	horvát	2025-08-08 22:03:12.22785+00
0581c1b8-2403-4682-8472-4a875e7f184d	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	en	Hungarian	2025-08-08 22:06:13.787468+00
b97fa0af-18fd-4967-89cf-60459698e0d2	169f71bd-2568-4be5-98ed-7b466461c5bd	en	English	2025-08-08 22:06:13.787468+00
1d942585-563c-4944-98b6-378a060b1bb3	b0b5a636-6271-455e-84c6-169a0f4d187f	en	German	2025-08-08 22:06:13.787468+00
176b3d13-fa7c-4ad1-8147-fafa08905f1f	40acb851-ec89-40d7-acc1-0cfc5465ebe6	en	Thai	2025-08-08 22:06:13.787468+00
7eccce9e-b651-41db-b6cd-2c584da53d48	ab15e65e-3267-432b-9b85-46ad443b445e	en	French	2025-08-08 22:06:13.787468+00
4b60c326-64ce-43b9-a39a-33f188405874	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	en	Italian	2025-08-08 22:06:13.787468+00
32a51808-6581-45f1-8e29-c0671c23de33	f511193a-f362-4bf8-aa68-b19bebd2bf0f	en	Spanish	2025-08-08 22:06:13.787468+00
2e331f54-bbef-44d9-a54e-0eb83b3c132f	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	en	Russian	2025-08-08 22:06:13.787468+00
7100c973-4e11-4a36-b8da-20f2cbcbc88a	db81101a-caba-4256-8025-65cf7d2ef2ab	en	Polish	2025-08-08 22:06:13.787468+00
14769a10-33e4-4f79-a3d3-5700d834fe16	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	en	Czech	2025-08-08 22:06:13.787468+00
8ba23336-9518-493f-a617-112433b15ebf	ce560240-8f4f-4970-a96f-06da04581859	en	Slovak	2025-08-08 22:06:13.787468+00
1ead392a-1641-4f20-b7f7-9885c0cdcca3	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	en	Romanian	2025-08-08 22:06:13.787468+00
32f83309-0942-4ffc-8670-fbed7bce230a	60af38eb-dd45-4afc-8386-cb483f597022	en	Dutch	2025-08-08 22:06:13.787468+00
11e310c5-199d-48b3-87ad-3150a62cc68a	043b87b2-c53c-4864-baa3-500beb6d102c	en	Portuguese	2025-08-08 22:06:13.787468+00
d7bdc25a-5842-4b11-a532-dd2017ada2bc	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	en	Swedish	2025-08-08 22:06:13.787468+00
45b03784-9df8-42b9-86bb-79228201f74b	a9294b82-7373-4b43-b110-b1f5249ab69f	en	Norwegian	2025-08-08 22:06:13.787468+00
fda4cffb-25dd-4b6f-8e75-1ba793407296	0db1ad1f-85fd-4870-b149-f634a958356a	en	Danish	2025-08-08 22:06:13.787468+00
e3735c90-98a8-4a69-bebb-a8bf54ac41a1	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	en	Finnish	2025-08-08 22:06:13.787468+00
3202cf1b-01b8-4806-b908-9e7fd37394b8	c200452a-8b96-40d2-b767-56be9926be7b	en	Greek	2025-08-08 22:06:13.787468+00
e2449633-64b6-4227-9cbf-aa4dc51db8cc	6220a92d-4412-4e24-bac1-dc54bc49b1cd	en	Croatian	2025-08-08 22:06:13.787468+00
124351f9-b0c4-43c6-9414-9668eacf1c89	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	de	Ungarisch	2025-08-08 22:06:28.389962+00
b41b77eb-29b0-423c-81e2-56947fa34481	169f71bd-2568-4be5-98ed-7b466461c5bd	de	Englisch	2025-08-08 22:06:28.389962+00
42a2bed6-be96-460a-9865-9498698a1a71	b0b5a636-6271-455e-84c6-169a0f4d187f	de	Deutsch	2025-08-08 22:06:28.389962+00
0c728f40-aca5-410d-b2b2-1ae44f120e2e	40acb851-ec89-40d7-acc1-0cfc5465ebe6	de	Thailändisch	2025-08-08 22:06:28.389962+00
13be6e55-06f6-4ed9-9998-5dc7f35a03ff	ab15e65e-3267-432b-9b85-46ad443b445e	de	Französisch	2025-08-08 22:06:28.389962+00
7c0217b9-18a4-472a-80d5-2df8d57300fd	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	de	Italienisch	2025-08-08 22:06:28.389962+00
98980cdb-b5eb-4d62-9590-9724ee31bf8b	f511193a-f362-4bf8-aa68-b19bebd2bf0f	de	Spanisch	2025-08-08 22:06:28.389962+00
c3b81802-22fb-4d57-86d4-6236405a16e7	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	de	Russisch	2025-08-08 22:06:28.389962+00
865d3c77-0c38-44a4-9909-c8e6d32f7738	db81101a-caba-4256-8025-65cf7d2ef2ab	de	Polnisch	2025-08-08 22:06:28.389962+00
450ca14f-1d5f-4552-b869-d9544b3283f9	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	de	Tschechisch	2025-08-08 22:06:28.389962+00
74892c24-654e-4eca-a981-d2ba6aa1dfae	ce560240-8f4f-4970-a96f-06da04581859	de	Slowakisch	2025-08-08 22:06:28.389962+00
df73ac3b-aaae-44a7-b698-4af2964462f9	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	de	Rumänisch	2025-08-08 22:06:28.389962+00
57a54155-b354-4159-9a24-cdebbf10301c	60af38eb-dd45-4afc-8386-cb483f597022	de	Niederländisch	2025-08-08 22:06:28.389962+00
4f67f5ef-7f06-4939-87d4-c2bf3da6f607	043b87b2-c53c-4864-baa3-500beb6d102c	de	Portugiesisch	2025-08-08 22:06:28.389962+00
a34d3d5c-4322-4f3f-9532-7a896485d253	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	de	Schwedisch	2025-08-08 22:06:28.389962+00
ba60f5ec-4692-48a8-9527-95261bcc17fa	a9294b82-7373-4b43-b110-b1f5249ab69f	de	Norwegisch	2025-08-08 22:06:28.389962+00
3835ebf4-9776-47e4-a158-8560f19a1e9d	0db1ad1f-85fd-4870-b149-f634a958356a	de	Dänisch	2025-08-08 22:06:28.389962+00
a82d2c7f-4126-4ff0-a3e2-216b8907fcc3	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	de	Finnisch	2025-08-08 22:06:28.389962+00
558fb658-6cb7-4189-ad62-49b10dc85f1a	c200452a-8b96-40d2-b767-56be9926be7b	de	Griechisch	2025-08-08 22:06:28.389962+00
6e98ef06-24c4-4d13-b1d6-9e9d60779171	6220a92d-4412-4e24-bac1-dc54bc49b1cd	de	Kroatisch	2025-08-08 22:06:28.389962+00
f274f5da-5258-4d39-a683-df3bb599a74a	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	fr	hongrois	2025-08-08 22:06:42.654054+00
24b9a8f2-8ab3-4048-9f90-39c426cdf83e	169f71bd-2568-4be5-98ed-7b466461c5bd	fr	anglais	2025-08-08 22:06:42.654054+00
42db6977-46c5-412e-a360-ff7107214247	b0b5a636-6271-455e-84c6-169a0f4d187f	fr	allemand	2025-08-08 22:06:42.654054+00
40d9ca1e-3741-4900-bc13-d6187eb93cea	40acb851-ec89-40d7-acc1-0cfc5465ebe6	fr	thaï	2025-08-08 22:06:42.654054+00
c0644f35-365f-4a65-b2af-d7820025b8b0	ab15e65e-3267-432b-9b85-46ad443b445e	fr	français	2025-08-08 22:06:42.654054+00
de886bb1-0fe4-4c72-b8d4-eef29f7b30bb	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	fr	italien	2025-08-08 22:06:42.654054+00
15f9c1bd-50bd-43e8-a3d1-11ced15e8688	f511193a-f362-4bf8-aa68-b19bebd2bf0f	fr	espagnol	2025-08-08 22:06:42.654054+00
f7a439ed-dde4-40e6-bec6-429ae58ba242	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	fr	russe	2025-08-08 22:06:42.654054+00
d0a97a29-31ee-4f85-808c-8dc11d911aab	db81101a-caba-4256-8025-65cf7d2ef2ab	fr	polonais	2025-08-08 22:06:42.654054+00
83c8e6be-965a-49b9-a9eb-14302e353da4	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	fr	tchèque	2025-08-08 22:06:42.654054+00
40b94505-ba6e-4bb6-9623-3b33155e06fa	ce560240-8f4f-4970-a96f-06da04581859	fr	slovaque	2025-08-08 22:06:42.654054+00
f5d79a19-2188-470e-97a3-1432e782a917	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	fr	roumain	2025-08-08 22:06:42.654054+00
3e8c2234-d850-4191-bd3d-ed4e4212a3b1	60af38eb-dd45-4afc-8386-cb483f597022	fr	néerlandais	2025-08-08 22:06:42.654054+00
9b370b0d-c462-48ff-a3aa-9172e7fd0fe1	043b87b2-c53c-4864-baa3-500beb6d102c	fr	portugais	2025-08-08 22:06:42.654054+00
07fd5a1c-fc04-4848-ae4b-083134cf4259	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	fr	suédois	2025-08-08 22:06:42.654054+00
6737bb32-12b7-4e5f-ad9a-883dc78f135a	a9294b82-7373-4b43-b110-b1f5249ab69f	fr	norvégien	2025-08-08 22:06:42.654054+00
a3f52f9e-e8fa-41c9-8253-2d042a9f8121	0db1ad1f-85fd-4870-b149-f634a958356a	fr	danois	2025-08-08 22:06:42.654054+00
52bbf734-8009-4584-9fd2-68f52065560f	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	fr	finnois	2025-08-08 22:06:42.654054+00
e620aac9-e76e-4b21-ad80-acf24853c51b	c200452a-8b96-40d2-b767-56be9926be7b	fr	grec	2025-08-08 22:06:42.654054+00
ef5aed00-e909-48cc-adb7-d6e312b8b5de	6220a92d-4412-4e24-bac1-dc54bc49b1cd	fr	croate	2025-08-08 22:06:42.654054+00
3ea06205-ab8a-4e30-a773-dfae7cabb71b	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	it	ungherese	2025-08-08 22:06:54.407735+00
9360c5cc-4939-4b9f-acea-6a702a5f7ceb	169f71bd-2568-4be5-98ed-7b466461c5bd	it	inglese	2025-08-08 22:06:54.407735+00
e02c304f-d70d-4224-a0dc-1b2e5a392c09	b0b5a636-6271-455e-84c6-169a0f4d187f	it	tedesco	2025-08-08 22:06:54.407735+00
8b8d7e98-9b5d-4598-a48b-d3c17a632ea9	40acb851-ec89-40d7-acc1-0cfc5465ebe6	it	tailandese	2025-08-08 22:06:54.407735+00
83aa8115-5dea-4d64-9687-f1ddf38f309b	ab15e65e-3267-432b-9b85-46ad443b445e	it	francese	2025-08-08 22:06:54.407735+00
8c5964c9-1fe3-478f-b53c-1b024a3b7407	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	it	italiano	2025-08-08 22:06:54.407735+00
ed79c03a-2b96-441f-be3e-381c66af7f06	f511193a-f362-4bf8-aa68-b19bebd2bf0f	it	spagnolo	2025-08-08 22:06:54.407735+00
b8bd193e-c15e-4148-a3d0-c50645fa5f5f	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	it	russo	2025-08-08 22:06:54.407735+00
6e468324-6e4a-4e1a-81a3-d8655242bd6c	db81101a-caba-4256-8025-65cf7d2ef2ab	it	polacco	2025-08-08 22:06:54.407735+00
c01a51f2-041c-4833-b1d0-786862e303ba	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	it	ceco	2025-08-08 22:06:54.407735+00
75538721-775e-4b5c-a514-eebe57fd005b	ce560240-8f4f-4970-a96f-06da04581859	it	slovacco	2025-08-08 22:06:54.407735+00
110ea81a-a4be-41e1-a9d4-98aa45254a2f	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	it	rumeno	2025-08-08 22:06:54.407735+00
b9f8ed80-c746-4f87-9599-4bc3716b6140	60af38eb-dd45-4afc-8386-cb483f597022	it	olandese	2025-08-08 22:06:54.407735+00
db966940-2ca3-4b07-9351-662717e122c8	043b87b2-c53c-4864-baa3-500beb6d102c	it	portoghese	2025-08-08 22:06:54.407735+00
3884179c-95d5-4301-a96b-d4235488801a	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	it	svedese	2025-08-08 22:06:54.407735+00
5b8b1457-b694-4ecb-8a54-fc8088dd0101	a9294b82-7373-4b43-b110-b1f5249ab69f	it	norvegese	2025-08-08 22:06:54.407735+00
73c76a51-f42d-4683-a191-9175eced07ec	0db1ad1f-85fd-4870-b149-f634a958356a	it	danese	2025-08-08 22:06:54.407735+00
2e7528c0-31a9-4cdb-acea-c34e1aa263b8	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	it	finlandese	2025-08-08 22:06:54.407735+00
1d7c9a58-b53e-47a0-8278-42b6f348573b	c200452a-8b96-40d2-b767-56be9926be7b	it	greco	2025-08-08 22:06:54.407735+00
bf9ed9d5-b967-43ad-8b2e-d924e55bccb9	6220a92d-4412-4e24-bac1-dc54bc49b1cd	it	croato	2025-08-08 22:06:54.407735+00
2b2be7ff-222e-4745-9248-11bd62a943f9	c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	th	ภาษาฮังการี	2025-08-08 22:07:11.14154+00
94a41790-1c7d-48ee-a420-338d5dc94a32	169f71bd-2568-4be5-98ed-7b466461c5bd	th	ภาษาอังกฤษ	2025-08-08 22:07:11.14154+00
bcab991d-77bc-4091-a801-0d5d2141e721	b0b5a636-6271-455e-84c6-169a0f4d187f	th	ภาษาเยอรมัน	2025-08-08 22:07:11.14154+00
6257d0b6-88cc-49d2-a6b7-d73699adf2c4	40acb851-ec89-40d7-acc1-0cfc5465ebe6	th	ภาษาไทย	2025-08-08 22:07:11.14154+00
49701e4a-387c-4478-9ca2-213d7a9ade02	ab15e65e-3267-432b-9b85-46ad443b445e	th	ภาษาฝรั่งเศส	2025-08-08 22:07:11.14154+00
3cfece98-ba42-497a-9c0a-de30390a77d2	9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	th	ภาษาอิตาลี	2025-08-08 22:07:11.14154+00
c7e4dc79-8449-4628-b8d5-3519d327c0d8	f511193a-f362-4bf8-aa68-b19bebd2bf0f	th	ภาษาสเปน	2025-08-08 22:07:11.14154+00
d3f1f135-697a-40ee-8551-5f9ab4e3f80e	ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	th	ภาษารัสเซีย	2025-08-08 22:07:11.14154+00
9a78174e-3e94-4d00-b900-39309143c350	db81101a-caba-4256-8025-65cf7d2ef2ab	th	ภาษาโปแลนด์	2025-08-08 22:07:11.14154+00
5525986f-cf65-4e4b-ad75-962efda8b89e	35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	th	ภาษาเช็ก	2025-08-08 22:07:11.14154+00
0145c288-94c9-4d5e-8dfa-f57ab0b6330f	ce560240-8f4f-4970-a96f-06da04581859	th	ภาษาสโลวัก	2025-08-08 22:07:11.14154+00
b2926433-cfe4-4755-9c2e-dad7db0b1d64	3fb939fd-f225-49c1-803f-bcb7cdd8f85f	th	ภาษาโรมาเนีย	2025-08-08 22:07:11.14154+00
22b30cca-f0d5-4564-b6c8-c6527bda9f96	60af38eb-dd45-4afc-8386-cb483f597022	th	ภาษาดัตช์	2025-08-08 22:07:11.14154+00
79d304bf-6106-4462-80ff-95ba8c4e38be	043b87b2-c53c-4864-baa3-500beb6d102c	th	ภาษาโปรตุเกส	2025-08-08 22:07:11.14154+00
9f5972d7-91d7-4f49-b3c1-4396e611075c	ea47b3b2-fc5e-40b7-b84e-21644b049ec0	th	ภาษาสวีเดน	2025-08-08 22:07:11.14154+00
b48968a1-fb5d-4a37-9a98-938433ba4e62	a9294b82-7373-4b43-b110-b1f5249ab69f	th	ภาษานอร์เวย์	2025-08-08 22:07:11.14154+00
823c2d0c-a25f-459b-9ff3-49c92c73fb36	0db1ad1f-85fd-4870-b149-f634a958356a	th	ภาษาเดนมาร์ก	2025-08-08 22:07:11.14154+00
ee85049e-1640-4ef9-97f0-824b25a5c70c	3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	th	ภาษาฟินแลนด์	2025-08-08 22:07:11.14154+00
6059867d-9cbd-44cc-875c-61de06b32476	c200452a-8b96-40d2-b767-56be9926be7b	th	ภาษากรีก	2025-08-08 22:07:11.14154+00
22f6cd74-d693-4b35-837c-826490b6b459	6220a92d-4412-4e24-bac1-dc54bc49b1cd	th	ภาษาโครเอเชีย	2025-08-08 22:07:11.14154+00
\.


--
-- Data for Name: languages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.languages (id, name, code, flag_emoji, is_active, created_at, updated_at) FROM stdin;
c0fadef5-b2b7-4eb3-9d06-c064c69c1cbb	Hungarian	hu	🇭🇺	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
169f71bd-2568-4be5-98ed-7b466461c5bd	English	en	🇺🇸	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
b0b5a636-6271-455e-84c6-169a0f4d187f	German	de	🇩🇪	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
40acb851-ec89-40d7-acc1-0cfc5465ebe6	Thai	th	🇹🇭	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
ab15e65e-3267-432b-9b85-46ad443b445e	French	fr	🇫🇷	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
9b6fb9d4-84a5-44f6-9e1b-4e11f5dc1e42	Italian	it	🇮🇹	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
f511193a-f362-4bf8-aa68-b19bebd2bf0f	Spanish	es	🇪🇸	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
ed9b0397-9cdf-4f4d-a33c-d935ecfdff0c	Russian	ru	🇷🇺	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
db81101a-caba-4256-8025-65cf7d2ef2ab	Polish	pl	🇵🇱	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
35c5c5a2-57f4-4edb-b5cb-ebee2a24d6a4	Czech	cs	🇨🇿	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
ce560240-8f4f-4970-a96f-06da04581859	Slovak	sk	🇸🇰	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
3fb939fd-f225-49c1-803f-bcb7cdd8f85f	Romanian	ro	🇷🇴	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
60af38eb-dd45-4afc-8386-cb483f597022	Dutch	nl	🇳🇱	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
043b87b2-c53c-4864-baa3-500beb6d102c	Portuguese	pt	🇵🇹	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
ea47b3b2-fc5e-40b7-b84e-21644b049ec0	Swedish	sv	🇸🇪	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
a9294b82-7373-4b43-b110-b1f5249ab69f	Norwegian	no	🇳🇴	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
0db1ad1f-85fd-4870-b149-f634a958356a	Danish	da	🇩🇰	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
3f8229c8-7103-47bd-8ba2-ebad6a6dd9a2	Finnish	fi	🇫🇮	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
c200452a-8b96-40d2-b767-56be9926be7b	Greek	el	🇬🇷	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
6220a92d-4412-4e24-bac1-dc54bc49b1cd	Croatian	hr	🇭🇷	t	2025-08-08 22:02:38.339329+00	2025-08-08 22:02:38.339329+00
\.


--
-- Data for Name: schools; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schools (id, name, address, phone, contact_email, admin_user_id, description, is_active, is_mock, created_at, updated_at) FROM stdin;
357d81d3-084e-4420-95cd-5556c98d902a	Test School	\N	\N	admin@testschool.com	\N	Test school for development	t	f	2025-08-07 22:55:37.823+00	2025-08-07 22:55:37.823+00
\.


--
-- Data for Name: study_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.study_logs (id, user_id, card_id, set_id, session_id, feedback_type, direction, reaction_time, mastery_level_before, mastery_level_after, review_interval, created_at) FROM stdin;
\.


--
-- Data for Name: study_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.study_sessions (id, user_id, set_id, classroom_id, direction, session_type, cards_studied, cards_correct, cards_incorrect, total_time, started_at, completed_at, is_completed, is_mock, created_at) FROM stdin;
\.


--
-- Data for Name: user_card_progress; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_card_progress (id, user_id, card_id, set_id, direction, mastery_level, last_reviewed, next_review, review_count, correct_count, is_mock, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_learning_languages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_learning_languages (id, user_id, language_id, created_at) FROM stdin;
cd9d19dd-6719-4ebb-867c-a1acc8f2ab4e	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	169f71bd-2568-4be5-98ed-7b466461c5bd	2025-08-08 22:10:13.829028+00
93e8238c-6b9d-4bdb-b475-462be0419e64	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	db81101a-caba-4256-8025-65cf7d2ef2ab	2025-08-08 22:11:55.560471+00
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_profiles (id, first_name, last_name, email, user_role, school_id, language, country, phone, status, note, is_mock, created_at, updated_at, stored_password) FROM stdin;
af117cb0-e7b8-4f56-8e44-d8822462d95d	Zsolt	Tasnadi	zsolt.tasnadi@gmail.com	school_admin	357d81d3-084e-4420-95cd-5556c98d902a	\N	\N	\N	\N	\N	f	2025-08-05 11:09:52.336411+00	2025-08-05 11:10:53.06969+00	\N
54de9310-332d-481d-9b7e-b6cfaf0aacfa	Brad	Pitt	brad.pitt.budapest@gmail.com	teacher	\N	\N	\N	\N	\N	\N	f	2025-08-05 11:09:52.336411+00	2025-08-05 11:10:53.06969+00	\N
9802312d-e7ce-4005-994b-ee9437fb5326	Vidam	Kós	vidamkos@gmail.com	student	\N	\N	\N	\N	\N	\N	f	2025-08-05 11:09:52.336411+00	2025-08-07 10:13:27.120907+00	Palacs1nta
1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	Zsolt	Tasnadi	vidamkos@gmail.com	student	\N	hu	\N	+36703345378	\N	\N	f	2025-08-08 21:58:47.217551+00	2025-08-08 22:32:39.663162+00	\N
\.


--
-- Data for Name: user_set_progress; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_set_progress (id, user_id, set_id, total_time_spent, last_studied, cards_studied, cards_mastered, session_count, is_mock, created_at, updated_at) FROM stdin;
5f42b22c-7879-4f43-9094-fd81de0ab80d	1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3	faa6bb13-beb7-4301-a3ef-12f87aaf3a3f	0	2025-08-08 22:46:00.985+00	0	0	0	f	2025-08-08 22:46:01.129793+00	2025-08-08 22:46:01.129793+00
\.


--
-- Data for Name: waitlist; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.waitlist (id, email, name, created_at, updated_at, confirmed, confirmation_token, confirmed_at, first_name, language, source, status, invite_sent_at, registered_at, is_mock) FROM stdin;
12345678-1234-1234-1234-123456789012	test@example.com	\N	2025-08-07 22:55:37.877+00	2025-08-07 22:55:37.877+00	f	\N	\N	\N	\N	\N	\N	\N	\N	f
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
media	media	\N	2025-08-01 14:15:13.571133+00	2025-08-01 14:15:13.571133+00	t	f	\N	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (id, type, format, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-08-07 11:28:36.210597
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-08-07 11:28:36.223492
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-08-07 11:28:36.231118
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-08-07 11:28:36.24615
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-08-07 11:28:36.262855
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-08-07 11:28:36.270652
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-08-07 11:28:36.279003
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-08-07 11:28:36.286572
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-08-07 11:28:36.294983
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-08-07 11:28:36.302329
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-08-07 11:28:36.31156
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-08-07 11:28:36.319625
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-08-07 11:28:36.328184
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-08-07 11:28:36.336005
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-08-07 11:28:36.344051
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-08-07 11:28:36.364862
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-08-07 11:28:36.372758
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-08-07 11:28:36.380971
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-08-07 11:28:36.388501
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-08-07 11:28:36.396725
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-08-07 11:28:36.40401
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-08-07 11:28:36.414551
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-08-07 11:28:36.429723
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-08-07 11:28:36.44229
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-08-07 11:28:36.449553
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-08-07 11:28:36.456686
26	objects-prefixes	ef3f7871121cdc47a65308e6702519e853422ae2	2025-08-07 11:34:01.235289
27	search-v2	33b8f2a7ae53105f028e13e9fcda9dc4f356b4a2	2025-08-07 11:34:01.255911
28	object-bucket-name-sorting	ba85ec41b62c6a30a3f136788227ee47f311c436	2025-08-07 11:34:01.401424
29	create-prefixes	a7b1a22c0dc3ab630e3055bfec7ce7d2045c5b7b	2025-08-07 11:34:01.408316
30	update-object-levels	6c6f6cc9430d570f26284a24cf7b210599032db7	2025-08-07 11:34:01.414096
31	objects-level-index	33f1fef7ec7fea08bb892222f4f0f5d79bab5eb8	2025-08-07 11:34:01.429052
32	backward-compatible-index-on-objects	2d51eeb437a96868b36fcdfb1ddefdf13bef1647	2025-08-07 11:34:01.438967
33	backward-compatible-index-on-prefixes	fe473390e1b8c407434c0e470655945b110507bf	2025-08-07 11:34:01.448372
34	optimize-search-function-v1	82b0e469a00e8ebce495e29bfa70a0797f7ebd2c	2025-08-07 11:34:01.450836
35	add-insert-trigger-prefixes	63bb9fd05deb3dc5e9fa66c83e82b152f0caf589	2025-08-07 11:34:01.460739
36	optimise-existing-functions	81cf92eb0c36612865a18016a38496c530443899	2025-08-07 11:34:01.467548
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2025-08-07 11:34:01.480591
38	iceberg-catalog-flag-on-buckets	19a8bd89d5dfa69af7f222a46c726b7c41e462c5	2025-08-07 11:34:01.487348
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata, level) FROM stdin;
bccf393b-3890-4af8-b49a-414534c3a18f	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 14:24:36.167845+00	2025-08-01 14:24:36.167845+00	2025-08-01 14:24:36.167845+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T14:24:37.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
9cf0d587-677c-4d20-a331-43c97d28d3d0	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 14:41:14.703899+00	2025-08-01 14:41:14.703899+00	2025-08-01 14:41:14.703899+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T14:41:15.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
7f03d5c0-fb5a-4c56-aa87-31afe5137486	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059833333_xufyxa7wr59.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 14:50:33.892509+00	2025-08-01 14:50:33.892509+00	2025-08-01 14:50:33.892509+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T14:50:34.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
66a3c9a6-2903-43e0-9357-1de6ea981e57	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754060396778_6pbj9admg3.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 14:59:57.314206+00	2025-08-01 14:59:57.314206+00	2025-08-01 14:59:57.314206+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T14:59:58.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
00be9e1d-7df3-4806-ade6-40d3342093fb	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_1rtayuayo9g.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 15:23:46.907186+00	2025-08-01 15:23:46.907186+00	2025-08-01 15:23:46.907186+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T15:23:47.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
7cf6255f-b9a2-4130-bff2-212f24e309dc	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_x4hy0q16c1.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 15:23:46.868763+00	2025-08-01 15:23:46.868763+00	2025-08-01 15:23:46.868763+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T15:23:47.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
141f686b-2162-46be-98a1-38e383e31845	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281219_hg669on57u5.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 15:48:01.837094+00	2025-08-01 15:48:01.837094+00	2025-08-01 15:48:01.837094+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T15:48:02.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
77aa2a90-0e05-4477-bed3-4902a27d49b9	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281220_2gprfoihenf.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 15:48:01.847393+00	2025-08-01 15:48:01.847393+00	2025-08-01 15:48:01.847393+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T15:48:02.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
6faf46e8-e157-4fcc-bdd7-85a526bd4a3d	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_1dm8ruxy0t5.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 15:59:22.696319+00	2025-08-03 15:59:22.696319+00	2025-08-03 15:59:22.696319+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T15:59:23.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
8112ffd8-28f9-4f6a-ba5c-12b60dcb8974	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_kyl98gf7z8.jpeg	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 15:59:22.683785+00	2025-08-03 15:59:22.683785+00	2025-08-03 15:59:22.683785+00	{"eTag": "\\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\\"", "size": 155174, "mimetype": "image/jpeg", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T15:59:23.000Z", "contentLength": 155174, "httpStatusCode": 200}	\N	\N	\N	3
b09b3ede-67df-4a5a-842f-6326b93cf785	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:18:28.260286+00	2025-08-01 17:18:28.260286+00	2025-08-01 17:18:28.260286+00	{"eTag": "\\"3ed3babd8b6a52b768fee4714d5f5d61\\"", "size": 230462, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:18:29.000Z", "contentLength": 230462, "httpStatusCode": 200}	\N	\N	\N	3
e7138afa-35fc-4c2b-8e6e-37f97a9a15d7	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754069851062_opc98k7pmni.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:37:32.095232+00	2025-08-01 17:37:32.095232+00	2025-08-01 17:37:32.095232+00	{"eTag": "\\"4b268e8fc75417546bb151b311f2d2f6\\"", "size": 1391886, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:37:32.000Z", "contentLength": 1391886, "httpStatusCode": 200}	\N	\N	\N	3
35f5b617-4481-4766-a2fa-1336adb960b6	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070134534_h3klxvkio0i.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:42:15.606421+00	2025-08-01 17:42:15.606421+00	2025-08-01 17:42:15.606421+00	{"eTag": "\\"9333985ee23d2978876c0ffb0a0f5843\\"", "size": 1430225, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:42:16.000Z", "contentLength": 1430225, "httpStatusCode": 200}	\N	\N	\N	3
0e833d89-3048-4cca-85fc-1778c5de299c	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070376408_ifvvsune63r.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:46:16.844218+00	2025-08-01 17:46:16.844218+00	2025-08-01 17:46:16.844218+00	{"eTag": "\\"c41a2601445070f3b2d22b503ecf1f0f\\"", "size": 64891, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:46:17.000Z", "contentLength": 64891, "httpStatusCode": 200}	\N	\N	\N	3
1ad178e7-8d02-4066-aabc-c48949e55132	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070406486_1a0o4c0ya56.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:46:47.450846+00	2025-08-01 17:46:47.450846+00	2025-08-01 17:46:47.450846+00	{"eTag": "\\"91e0c91d6b52f2d6ab82eb8a731f645c\\"", "size": 1347272, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:46:48.000Z", "contentLength": 1347272, "httpStatusCode": 200}	\N	\N	\N	3
b6f9b4fa-9442-4f50-a474-0f0d51abae22	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070689049_ykaa09anqy.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:51:29.81476+00	2025-08-01 17:51:29.81476+00	2025-08-01 17:51:29.81476+00	{"eTag": "\\"5528bef8f89c6c41936ec1dfa997d5b0\\"", "size": 560891, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:51:30.000Z", "contentLength": 560891, "httpStatusCode": 200}	\N	\N	\N	3
2c3c7742-fc03-4ec6-94d3-cae321a90e1f	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070718585_flkco5ynm9g.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:51:59.5802+00	2025-08-01 17:51:59.5802+00	2025-08-01 17:51:59.5802+00	{"eTag": "\\"81ddfa7cdc7b30cb4860a5577b320134\\"", "size": 1361112, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:52:00.000Z", "contentLength": 1361112, "httpStatusCode": 200}	\N	\N	\N	3
52165783-f4de-4532-9ad4-601043f8cf7c	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071133208_yx5tj4evbrs.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 17:58:54.283563+00	2025-08-01 17:58:54.283563+00	2025-08-01 17:58:54.283563+00	{"eTag": "\\"ed25bc917bcc94de3691f29d0201746f\\"", "size": 1368076, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T17:58:55.000Z", "contentLength": 1368076, "httpStatusCode": 200}	\N	\N	\N	3
38295f39-9f96-4a83-8962-46a7db2472d0	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071381516_5jywcqpkr22.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 18:03:02.247575+00	2025-08-01 18:03:02.247575+00	2025-08-01 18:03:02.247575+00	{"eTag": "\\"c28c8856069ff3658e250cc1052807b8\\"", "size": 817869, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T18:03:03.000Z", "contentLength": 817869, "httpStatusCode": 200}	\N	\N	\N	3
aa0de215-6f72-4f98-81fa-55a670ff3745	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754073360276_qp22w0onij.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-01 18:36:01.489717+00	2025-08-01 18:36:01.489717+00	2025-08-01 18:36:01.489717+00	{"eTag": "\\"5721820167873dac1510f941b1c3519b\\"", "size": 1538204, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-01T18:36:02.000Z", "contentLength": 1538204, "httpStatusCode": 200}	\N	\N	\N	3
5b95ebf8-6af2-4c4f-a56f-b75245b287e2	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136177271_cwug6mm34ad.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-02 12:02:58.288702+00	2025-08-02 12:02:58.288702+00	2025-08-02 12:02:58.288702+00	{"eTag": "\\"39e6d06a1df1fab2b8b1636e3ab84036\\"", "size": 1367000, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-02T12:02:59.000Z", "contentLength": 1367000, "httpStatusCode": 200}	\N	\N	\N	3
4e9203dc-ae0c-4f73-8dd5-511eac46adcc	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136724885_1a4y03jhpdt.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-02 12:12:05.661845+00	2025-08-02 12:12:05.661845+00	2025-08-02 12:12:05.661845+00	{"eTag": "\\"14183f5102c0ef9c0beeecb0d601e15a\\"", "size": 868173, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-02T12:12:06.000Z", "contentLength": 868173, "httpStatusCode": 200}	\N	\N	\N	3
a342151e-532f-4730-8f3e-aa6a9c4eccd9	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136964687_pj775ro9hd.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-02 12:16:05.477044+00	2025-08-02 12:16:05.477044+00	2025-08-02 12:16:05.477044+00	{"eTag": "\\"20782c8de32c7cce25a62036026fd047\\"", "size": 909103, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-02T12:16:06.000Z", "contentLength": 909103, "httpStatusCode": 200}	\N	\N	\N	3
50a1b817-ca9b-4514-8d6a-7c15f93640ab	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754247996774_5d4rxhjx5e7.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:06:37.525371+00	2025-08-03 19:06:37.525371+00	2025-08-03 19:06:37.525371+00	{"eTag": "\\"790592ce63b289ee1fd83e06e4bfc54f\\"", "size": 770833, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:06:38.000Z", "contentLength": 770833, "httpStatusCode": 200}	\N	\N	\N	3
59d4ce35-cc22-43c4-b53c-b3b630af835b	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248251778_9y86aadumf6.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:10:52.508207+00	2025-08-03 19:10:52.508207+00	2025-08-03 19:10:52.508207+00	{"eTag": "\\"e97f10c40fb549dfc8adb36d2c4d116b\\"", "size": 728121, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:10:53.000Z", "contentLength": 728121, "httpStatusCode": 200}	\N	\N	\N	3
28bfbf21-8f8f-43b9-a896-d4b9d19f5dcb	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248275148_48t909nkqh2.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:11:15.853611+00	2025-08-03 19:11:15.853611+00	2025-08-03 19:11:15.853611+00	{"eTag": "\\"e97f10c40fb549dfc8adb36d2c4d116b\\"", "size": 728121, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:11:16.000Z", "contentLength": 728121, "httpStatusCode": 200}	\N	\N	\N	3
4e47b723-029d-40cb-903e-4b015116ea81	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248421365_r7zxeev7pb.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:13:42.920818+00	2025-08-03 19:13:42.920818+00	2025-08-03 19:13:42.920818+00	{"eTag": "\\"18d35e12660b37c0bfe531ef7f71c4ac\\"", "size": 4269404, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:13:43.000Z", "contentLength": 4269404, "httpStatusCode": 200}	\N	\N	\N	3
22afc7f7-d3d2-4831-b15a-57ed42dcad78	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248445574_koawtzfjva9.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:14:06.28748+00	2025-08-03 19:14:06.28748+00	2025-08-03 19:14:06.28748+00	{"eTag": "\\"3cf32c3ef8f828710e52eb910b794b9a\\"", "size": 756667, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:14:07.000Z", "contentLength": 756667, "httpStatusCode": 200}	\N	\N	\N	3
68b5cc17-ae1f-4363-b8f4-9ce2ab418b7f	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248632778_z3w5u7xrmj.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:17:13.526246+00	2025-08-03 19:17:13.526246+00	2025-08-03 19:17:13.526246+00	{"eTag": "\\"c6aa408fcb3601ca2e859a890a26c312\\"", "size": 782999, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:17:14.000Z", "contentLength": 782999, "httpStatusCode": 200}	\N	\N	\N	3
e08072ff-7fb7-4b4b-812a-3e32e3011795	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249298507_7m1dj6f26vs.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:28:19.268581+00	2025-08-03 19:28:19.268581+00	2025-08-03 19:28:19.268581+00	{"eTag": "\\"faac5e38ec9334db523ea8d4613ba211\\"", "size": 747133, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:28:20.000Z", "contentLength": 747133, "httpStatusCode": 200}	\N	\N	\N	3
383a08b2-88f0-41fa-963e-76608f7747b5	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249823648_wumfimc5jxs.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:37:04.606907+00	2025-08-03 19:37:04.606907+00	2025-08-03 19:37:04.606907+00	{"eTag": "\\"655f0d1cf0132aafe98285335eb6cf3e\\"", "size": 1726773, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:37:05.000Z", "contentLength": 1726773, "httpStatusCode": 200}	\N	\N	\N	3
747be234-17c4-444f-84aa-79abe06a46e5	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249873696_c0nil6jdxlb.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:37:54.299387+00	2025-08-03 19:37:54.299387+00	2025-08-03 19:37:54.299387+00	{"eTag": "\\"1292e983b8084abdae47913f7983a88e\\"", "size": 277243, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:37:55.000Z", "contentLength": 277243, "httpStatusCode": 200}	\N	\N	\N	3
e805ab45-bdfc-47c7-9b9e-eced5b51b78d	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250045571_kj8luwryyu7.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:40:46.079232+00	2025-08-03 19:40:46.079232+00	2025-08-03 19:40:46.079232+00	{"eTag": "\\"1292e983b8084abdae47913f7983a88e\\"", "size": 277243, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:40:46.000Z", "contentLength": 277243, "httpStatusCode": 200}	\N	\N	\N	3
8f1f956d-19ac-480c-869c-3027dc9d1712	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250058447_2hi8bpooiml.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:40:58.987262+00	2025-08-03 19:40:58.987262+00	2025-08-03 19:40:58.987262+00	{"eTag": "\\"1292e983b8084abdae47913f7983a88e\\"", "size": 277243, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:40:59.000Z", "contentLength": 277243, "httpStatusCode": 200}	\N	\N	\N	3
91b00af0-fbc1-408d-b7cb-7bd2441753e8	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250181414_pda0fn9nmsd.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:43:01.997426+00	2025-08-03 19:43:01.997426+00	2025-08-03 19:43:01.997426+00	{"eTag": "\\"1292e983b8084abdae47913f7983a88e\\"", "size": 277243, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:43:02.000Z", "contentLength": 277243, "httpStatusCode": 200}	\N	\N	\N	3
0af60075-48ee-41fe-92d3-6ee42f1679a9	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250349221_0ooapzq6yp29.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:45:49.962695+00	2025-08-03 19:45:49.962695+00	2025-08-03 19:45:49.962695+00	{"eTag": "\\"e78c91c2c5f1f5ded5a32d0db247458e\\"", "size": 781720, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:45:50.000Z", "contentLength": 781720, "httpStatusCode": 200}	\N	\N	\N	3
4106fe9d-7be2-4530-8246-1a7ee90175a1	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250536179_pp565enayi9.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:48:57.079726+00	2025-08-03 19:48:57.079726+00	2025-08-03 19:48:57.079726+00	{"eTag": "\\"a545a23a8da7e9a84f943ecfb7b02b03\\"", "size": 1077942, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:48:57.000Z", "contentLength": 1077942, "httpStatusCode": 200}	\N	\N	\N	3
38284921-486e-4f68-8912-70ce7f45bb03	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250555947_dqvhb1u1roj.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:49:16.75786+00	2025-08-03 19:49:16.75786+00	2025-08-03 19:49:16.75786+00	{"eTag": "\\"a545a23a8da7e9a84f943ecfb7b02b03\\"", "size": 1077942, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:49:17.000Z", "contentLength": 1077942, "httpStatusCode": 200}	\N	\N	\N	3
d982a951-0bd7-4fa0-bb20-3e62cb4d5eef	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250815489_66e22ityenb.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:53:36.063488+00	2025-08-03 19:53:36.063488+00	2025-08-03 19:53:36.063488+00	{"eTag": "\\"adf794904c63b556d4c24a391dac9fd2\\"", "size": 168259, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:53:36.000Z", "contentLength": 168259, "httpStatusCode": 200}	\N	\N	\N	3
0375f1ae-bb09-478e-9709-c56c25fcd03c	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250986922_8o62ncfj2a.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 19:56:28.031021+00	2025-08-03 19:56:28.031021+00	2025-08-03 19:56:28.031021+00	{"eTag": "\\"314c6f3ebc523176bf6f5fdb61fc9027\\"", "size": 1847992, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T19:56:28.000Z", "contentLength": 1847992, "httpStatusCode": 200}	\N	\N	\N	3
74455c7b-acd4-4175-94b4-91abd8ac4ac4	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251233083_wmfdp0jq0xl.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 20:00:34.011485+00	2025-08-03 20:00:34.011485+00	2025-08-03 20:00:34.011485+00	{"eTag": "\\"89a112d1add351da2f6f8bed3e23245c\\"", "size": 1449454, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T20:00:34.000Z", "contentLength": 1449454, "httpStatusCode": 200}	\N	\N	\N	3
b500d648-b9eb-42f5-85e0-0e0a806a0da1	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251494059_hy3edd4dq9r.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 20:04:55.068666+00	2025-08-03 20:04:55.068666+00	2025-08-03 20:04:55.068666+00	{"eTag": "\\"b905404e0a0d125433af484be0fac243\\"", "size": 1544772, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T20:04:55.000Z", "contentLength": 1544772, "httpStatusCode": 200}	\N	\N	\N	3
ab866ad2-c9f2-4562-81db-32c57f076ace	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251549080_2td6nmjosdo.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 20:05:50.09483+00	2025-08-03 20:05:50.09483+00	2025-08-03 20:05:50.09483+00	{"eTag": "\\"6ab41b20429f74abbcee29f0bb64ee11\\"", "size": 1710115, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T20:05:50.000Z", "contentLength": 1710115, "httpStatusCode": 200}	\N	\N	\N	3
0ea537ab-f05a-4db3-a17e-4a604361a651	media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251892207_fny3ryxm15c.png	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-03 20:11:33.252525+00	2025-08-03 20:11:33.252525+00	2025-08-03 20:11:33.252525+00	{"eTag": "\\"64446be1b68689779baeb3c9fee92d23\\"", "size": 1512213, "mimetype": "image/png", "cacheControl": "max-age=3600", "lastModified": "2025-08-03T20:11:34.000Z", "contentLength": 1512213, "httpStatusCode": 200}	\N	\N	\N	3
\.


--
-- Data for Name: prefixes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.prefixes (bucket_id, name, created_at, updated_at) FROM stdin;
media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4	2025-08-07 22:20:31.704954+00	2025-08-07 22:20:31.704954+00
media	6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards	2025-08-07 22:20:31.704954+00	2025-08-07 22:20:31.704954+00
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 40, true);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


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
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: prefixes prefixes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT prefixes_pkey PRIMARY KEY (bucket_id, level, name);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


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
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_name_bucket_level_unique; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX idx_name_bucket_level_unique ON storage.objects USING btree (name COLLATE "C", bucket_id, level);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_lower_name ON storage.objects USING btree ((path_tokens[level]), lower(name) text_pattern_ops, bucket_id, level);


--
-- Name: idx_prefixes_lower_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_prefixes_lower_name ON storage.prefixes USING btree (bucket_id, level, ((string_to_array(name, '/'::text))[level]), lower(name) text_pattern_ops);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: objects_bucket_id_level_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX objects_bucket_id_level_idx ON storage.objects USING btree (bucket_id, level, name COLLATE "C");


--
-- Name: users create_user_profile_trigger; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER create_user_profile_trigger AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.create_user_profile();


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
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: objects objects_delete_delete_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_delete_delete_prefix AFTER DELETE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects objects_insert_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_insert_create_prefix BEFORE INSERT ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.objects_insert_prefix_trigger();


--
-- Name: objects objects_update_create_prefix; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER objects_update_create_prefix BEFORE UPDATE ON storage.objects FOR EACH ROW WHEN (((new.name <> old.name) OR (new.bucket_id <> old.bucket_id))) EXECUTE FUNCTION storage.objects_update_prefix_trigger();


--
-- Name: prefixes prefixes_create_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_create_hierarchy BEFORE INSERT ON storage.prefixes FOR EACH ROW WHEN ((pg_trigger_depth() < 1)) EXECUTE FUNCTION storage.prefixes_insert_trigger();


--
-- Name: prefixes prefixes_delete_hierarchy; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER prefixes_delete_hierarchy AFTER DELETE ON storage.prefixes FOR EACH ROW EXECUTE FUNCTION storage.delete_prefix_hierarchy_trigger();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


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
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: prefixes prefixes_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.prefixes
    ADD CONSTRAINT "prefixes_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

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
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: prefixes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.prefixes ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

