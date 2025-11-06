-- ========================================
-- Missions Table
-- ========================================

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

-- Primary Key
ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_pkey" PRIMARY KEY ("id");

-- Foreign Keys
ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

-- Row Level Security
ALTER TABLE "public"."missions" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."missions" TO "anon";
GRANT ALL ON TABLE "public"."missions" TO "authenticated";
GRANT ALL ON TABLE "public"."missions" TO "service_role";
