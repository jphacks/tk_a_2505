-- ========================================
-- Users Table
-- ========================================

SET default_tablespace = '';
SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "shelter_badge_id" "uuid"
);

ALTER TABLE "public"."users" OWNER TO "postgres";

COMMENT ON TABLE "public"."users" IS 'users table';

-- Primary Key
ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

-- Foreign Keys
ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_shelter_badge_id_fkey" FOREIGN KEY ("shelter_badge_id") REFERENCES "public"."shelter_badges"("id") ON DELETE SET NULL;

-- Row Level Security
ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";
