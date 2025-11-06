-- ========================================
-- Custom Types
-- ========================================

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
