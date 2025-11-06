-- ========================================
-- Shelters Table
-- ========================================

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

-- Primary Key
ALTER TABLE ONLY "public"."shelters"
    ADD CONSTRAINT "shelters_pkey" PRIMARY KEY ("id");

-- Row Level Security
ALTER TABLE "public"."shelters" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."shelters" TO "anon";
GRANT ALL ON TABLE "public"."shelters" TO "authenticated";
GRANT ALL ON TABLE "public"."shelters" TO "service_role";
