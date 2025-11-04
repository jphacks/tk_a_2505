-- ========================================
-- Shelter Badges Table
-- ========================================

CREATE TABLE IF NOT EXISTS "public"."shelter_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "badge_name" "text" NOT NULL,
    "shelter_id" "uuid" NOT NULL,
    "first_user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE "public"."shelter_badges" OWNER TO "postgres";

-- Primary Key
ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_pkey" PRIMARY KEY ("id");

-- Foreign Keys
ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_first_user_id_fkey" FOREIGN KEY ("first_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."shelter_badges"
    ADD CONSTRAINT "shelter_badges_shelter_id_fkey" FOREIGN KEY ("shelter_id") REFERENCES "public"."shelters"("id") ON DELETE CASCADE;

-- Row Level Security
ALTER TABLE "public"."shelter_badges" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."shelter_badges" TO "anon";
GRANT ALL ON TABLE "public"."shelter_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."shelter_badges" TO "service_role";
