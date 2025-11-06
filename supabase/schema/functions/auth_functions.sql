-- ========================================
-- Authentication Functions
-- ========================================

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  adjectives text[] := array['Happy', 'Swift', 'Bright', 'Cool', 'Smart', 'Bold', 'Calm', 'Brave'];
  nouns text[] := array['Panda', 'Tiger', 'Eagle', 'Wolf', 'Fox', 'Bear', 'Hawk', 'Lion'];
  random_name text;
begin
  random_name := adjectives[floor(random() * array_length(adjectives, 1) + 1)] ||
                 nouns[floor(random() * array_length(nouns, 1) + 1)];

  insert into public.users (id, name)
  values (new.id, random_name);
  return new;
end;
$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

-- Grant permissions
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";
