-- ========================================
-- User Shelter Badges Table
-- ========================================

CREATE TABLE IF NOT EXISTS "public"."user_shelter_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "badge_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE "public"."user_shelter_badges" OWNER TO "postgres";

-- Primary Key
ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_pkey" PRIMARY KEY ("id");

-- Unique Constraints
ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_user_badge_unique" UNIQUE ("user_id", "badge_id");

-- Foreign Keys
ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."shelter_badges"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."user_shelter_badges"
    ADD CONSTRAINT "user_shelter_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

-- Row Level Security
ALTER TABLE "public"."user_shelter_badges" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."user_shelter_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_shelter_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_shelter_badges" TO "service_role";
