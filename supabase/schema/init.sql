


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."disaster_type" AS ENUM (
    'Flood',
    'Landslide',
    'Storm Surge',
    'Earthquake',
    'Tsunami',
    'Fire',
    'Inland Flood',
    'Volcano',
    'Zombie'
);


ALTER TYPE "public"."disaster_type" OWNER TO "postgres";


CREATE TYPE "public"."mission_state" AS ENUM (
    'none',
    'creating',
    'have',
    'done'
);


ALTER TYPE "public"."mission_state" OWNER TO "postgres";


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

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."missions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" DEFAULT "gen_random_uuid"(),
    "title" "text",
    "overview" "text",
    "disaster_type" "public"."disaster_type",
    "status" "public"."mission_state" DEFAULT 'none'::"public"."mission_state" NOT NULL,
    "steps" bigint,
    "distances" double precision,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."missions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."points" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "userId" "uuid" DEFAULT "gen_random_uuid"(),
    "point" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."points" OWNER TO "postgres";


COMMENT ON TABLE "public"."points" IS 'connects user and earned points';



CREATE TABLE IF NOT EXISTS "public"."shelter_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "badge_name" "text" NOT NULL,
    "shelter_id" "uuid" NOT NULL,
    "first_user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."shelter_badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."shelters" (
    "common_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "address" "text" NOT NULL,
    "municipality" "text",
    "is_shelter" boolean,
    "is_flood" boolean,
    "is_landslide" boolean,
    "is_storm_surge" boolean,
    "is_earthquake" boolean,
    "is_tsunami" boolean,
    "is_fire" boolean,
    "is_inland_flood" boolean,
    "is_volcano" boolean,
    "is_same_address_as_shelter" boolean,
    "other_municipal_notes" "text",
    "accepted_people" "text",
    "latitude" double precision NOT NULL,
    "longitude" double precision NOT NULL,
    "remarks" "text",
    "last_updated" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "number" bigint
);


ALTER TABLE "public"."shelters" OWNER TO "postgres";


COMMENT ON TABLE "public"."shelters" IS '避難場所・避難所のデータ';



CREATE TABLE IF NOT EXISTS "public"."user_shelter_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "badge_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "public"."user_shelter_badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text"
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON TABLE "public"."users" IS 'users table';



ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."points"
    ADD CONSTRAINT "points_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shelters"
    ADD CONSTRAINT "shelters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_user_badge_unique" UNIQUE ("user_id", "badge_id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."points"
    ADD CONSTRAINT "points_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_first_user_id_fkey" FOREIGN KEY ("first_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_shelter_id_fkey" FOREIGN KEY ("shelter_id") REFERENCES "public"."shelters"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."shelter_badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "access all" ON "public"."points" USING (true) WITH CHECK (true);



CREATE POLICY "access all" ON "public"."users" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."missions" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."shelter_badges" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."shelters" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."user_shelter_badges" USING (true) WITH CHECK (true);



ALTER TABLE "public"."missions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."points" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shelter_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shelters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_shelter_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";


















GRANT ALL ON TABLE "public"."missions" TO "anon";
GRANT ALL ON TABLE "public"."missions" TO "authenticated";
GRANT ALL ON TABLE "public"."missions" TO "service_role";



GRANT ALL ON TABLE "public"."points" TO "anon";
GRANT ALL ON TABLE "public"."points" TO "authenticated";
GRANT ALL ON TABLE "public"."points" TO "service_role";



GRANT ALL ON TABLE "public"."shelter_badges" TO "anon";
GRANT ALL ON TABLE "public"."shelter_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."shelter_badges" TO "service_role";



GRANT ALL ON TABLE "public"."shelters" TO "anon";
GRANT ALL ON TABLE "public"."shelters" TO "authenticated";
GRANT ALL ON TABLE "public"."shelters" TO "service_role";



GRANT ALL ON TABLE "public"."user_shelter_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_shelter_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_shelter_badges" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































RESET ALL;
