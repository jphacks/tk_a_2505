-- ========================================
-- Group Members Table
-- ========================================

CREATE TABLE IF NOT EXISTS "public"."group_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "group_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" character varying(20) DEFAULT 'member'::character varying NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "group_members_role_check" CHECK ((("role")::"text" = ANY ((ARRAY['owner'::character varying, 'admin'::character varying, 'member'::character varying])::"text"[])))
);

ALTER TABLE "public"."group_members" OWNER TO "postgres";

-- Primary Key
ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_pkey" PRIMARY KEY ("id");

-- Unique Constraints
ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_group_user_unique" UNIQUE ("group_id", "user_id");

-- Foreign Keys
ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."groups"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."group_members"
    ADD CONSTRAINT "group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

-- Indexes
CREATE INDEX IF NOT EXISTS "idx_group_members_group_id" ON "public"."group_members" USING "btree" ("group_id");
CREATE INDEX IF NOT EXISTS "idx_group_members_user_id" ON "public"."group_members" USING "btree" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_group_members_role" ON "public"."group_members" USING "btree" ("role");

-- Row Level Security
ALTER TABLE "public"."group_members" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."group_members" TO "anon";
GRANT ALL ON TABLE "public"."group_members" TO "authenticated";
GRANT ALL ON TABLE "public"."group_members" TO "service_role";
