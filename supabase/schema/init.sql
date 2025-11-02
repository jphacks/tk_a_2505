


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

-- ========================================
-- Group Functions and Tables
-- ========================================

-- 1. 招待コード生成関数
CREATE OR REPLACE FUNCTION "public"."generate_invite_code"()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 2. グループ作成時の自動処理関数
CREATE OR REPLACE FUNCTION "public"."create_group_with_owner"(
    p_name VARCHAR(100),
    p_description TEXT DEFAULT NULL,
    p_max_members INTEGER DEFAULT 50
) RETURNS UUID AS $$
DECLARE
    new_group_id UUID;
    current_user_id UUID;
    invite_code TEXT;
BEGIN
    -- 現在のユーザーIDを取得
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated';
    END IF;

    -- ユニークな招待コードを生成
    LOOP
        invite_code := generate_invite_code();
        EXIT WHEN NOT EXISTS (SELECT 1 FROM groups WHERE groups.invite_code = invite_code);
    END LOOP;

    -- グループを作成
    INSERT INTO groups (name, description, owner_id, invite_code, max_members)
    VALUES (p_name, p_description, current_user_id, invite_code, p_max_members)
    RETURNING id INTO new_group_id;

    -- オーナーをメンバーとして追加
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (new_group_id, current_user_id, 'owner');

    RETURN new_group_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. グループ参加関数
CREATE OR REPLACE FUNCTION "public"."join_group_by_invite_code"(p_invite_code VARCHAR(8))
RETURNS UUID AS $$
DECLARE
    group_id_to_join UUID;
    current_user_id UUID;
    member_count INTEGER;
    max_members INTEGER;
BEGIN
    -- 現在のユーザーIDを取得
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated';
    END IF;

    -- グループを取得
    SELECT id, max_members INTO group_id_to_join, max_members
    FROM groups
    WHERE groups.invite_code = p_invite_code;

    IF group_id_to_join IS NULL THEN
        RAISE EXCEPTION 'Invalid invite code';
    END IF;

    -- 既にメンバーかチェック
    IF EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id_to_join AND user_id = current_user_id) THEN
        RAISE EXCEPTION 'User is already a member of this group';
    END IF;

    -- メンバー数上限チェック
    SELECT COUNT(*) INTO member_count FROM group_members WHERE group_id = group_id_to_join;
    IF member_count >= max_members THEN
        RAISE EXCEPTION 'Group is full';
    END IF;

    -- メンバーとして追加
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (group_id_to_join, current_user_id, 'member');

    RETURN group_id_to_join;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


-- ========================================
-- Group Tables
-- ========================================

CREATE TABLE IF NOT EXISTS "public"."groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" "text",
    "icon_url" "text",
    "owner_id" "uuid" NOT NULL,
    "invite_code" character varying(8) NOT NULL,
    "max_members" integer DEFAULT 50 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."groups" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."group_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "group_members_role_check" CHECK ((("role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying, 'member'::character varying])::"text"[])))
);

ALTER TABLE "public"."group_members" OWNER TO "postgres";

-- Indexes for groups
CREATE INDEX IF NOT EXISTS "idx_groups_owner_id" ON "public"."groups" USING "btree" ("owner_id");
CREATE INDEX IF NOT EXISTS "idx_groups_invite_code" ON "public"."groups" USING "btree" ("invite_code");

-- Indexes for group_members
CREATE INDEX IF NOT EXISTS "idx_group_members_group_id" ON "public"."group_members" USING "btree" ("group_id");
CREATE INDEX IF NOT EXISTS "idx_group_members_user_id" ON "public"."group_members" USING "btree" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_group_members_role" ON "public"."group_members" USING "btree" ("role");

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


CREATE TABLE IF NOT EXISTS "public"."mission_results" (
    "id" bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "mission_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "steps" bigint,
    "distances" double precision,
    "shelter_id" "uuid" DEFAULT "gen_random_uuid"(),
    CONSTRAINT "mission_results_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "mission_results_mission_id_fkey" FOREIGN KEY ("mission_id") REFERENCES "public"."missions"("id") ON UPDATE CASCADE,
    CONSTRAINT "mission_results_shelter_id_fkey" FOREIGN KEY ("shelter_id") REFERENCES "public"."shelters"("id") ON UPDATE CASCADE,
    CONSTRAINT "mission_results_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE
);


ALTER TABLE "public"."mission_results" OWNER TO "postgres";


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



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_invite_code_unique" UNIQUE ("invite_code");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_group_user_unique" UNIQUE ("group_id", "user_id");



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



ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "access all" ON "public"."points" USING (true) WITH CHECK (true);



CREATE POLICY "access all" ON "public"."users" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."missions" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."shelter_badges" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."shelters" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."user_shelter_badges" USING (true) WITH CHECK (true);



CREATE POLICY "all access" ON "public"."mission_results" USING (true) WITH CHECK (true);



CREATE POLICY "Groups are viewable by members" ON "public"."groups"
    FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."group_members"
  WHERE (("group_members"."group_id" = "groups"."id") AND ("group_members"."user_id" = "auth"."uid"())))));



CREATE POLICY "Groups are updatable by owner" ON "public"."groups"
    FOR UPDATE USING (("owner_id" = "auth"."uid"()));



CREATE POLICY "Groups are deletable by owner" ON "public"."groups"
    FOR DELETE USING (("owner_id" = "auth"."uid"()));



CREATE POLICY "Authenticated users can create groups" ON "public"."groups"
    FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "Group members are viewable by group members" ON "public"."group_members"
    FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."group_members" gm
  WHERE (("gm"."group_id" = "group_members"."group_id") AND ("gm"."user_id" = "auth"."uid"())))));



CREATE POLICY "Authenticated users can join groups" ON "public"."group_members"
    FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "Users can update their own membership" ON "public"."group_members"
    FOR UPDATE USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Members can leave or be removed by admin" ON "public"."group_members"
    FOR DELETE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."group_members" gm
  WHERE (("gm"."group_id" = "group_members"."group_id") AND ("gm"."user_id" = "auth"."uid"()) AND ("gm"."role" = ANY (ARRAY['owner'::character varying, 'admin'::character varying])))))));



ALTER TABLE "public"."missions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."points" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shelter_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shelters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_shelter_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mission_results" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."groups" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."group_members" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "service_role";


















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



GRANT ALL ON TABLE "public"."mission_results" TO "anon";
GRANT ALL ON TABLE "public"."mission_results" TO "authenticated";
GRANT ALL ON TABLE "public"."mission_results" TO "service_role";



GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";



GRANT ALL ON TABLE "public"."group_members" TO "anon";
GRANT ALL ON TABLE "public"."group_members" TO "authenticated";
GRANT ALL ON TABLE "public"."group_members" TO "service_role";









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
