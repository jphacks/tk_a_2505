-- ========================================
-- Groups Table
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

-- Primary Key
ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_pkey" PRIMARY KEY ("id");

-- Unique Constraints
ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_invite_code_unique" UNIQUE ("invite_code");

-- Foreign Keys
ALTER TABLE ONLY "public"."groups"
    ADD CONSTRAINT "groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

-- Indexes
CREATE INDEX IF NOT EXISTS "idx_groups_owner_id" ON "public"."groups" USING "btree" ("owner_id");
CREATE INDEX IF NOT EXISTS "idx_groups_invite_code" ON "public"."groups" USING "btree" ("invite_code");

-- Row Level Security
ALTER TABLE "public"."groups" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."groups" TO "anon";
GRANT ALL ON TABLE "public"."groups" TO "authenticated";
GRANT ALL ON TABLE "public"."groups" TO "service_role";
