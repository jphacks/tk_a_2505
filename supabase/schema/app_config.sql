-- DROP TABLE public.app_config

-- App configuration table for version control and maintenance mode

CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "minimum_version" "text" NOT NULL DEFAULT '1.0.0',
    "is_maintenance_mode" boolean NOT NULL DEFAULT false,
    "maintenance_message_en" "text",
    "maintenance_message_ja" "text",
    "force_update_message_en" "text",
    "force_update_message_ja" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."app_config" OWNER TO "postgres";

COMMENT ON TABLE "public"."app_config" IS 'App configuration for version control and maintenance mode';

ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");

CREATE POLICY "all access" ON "public"."app_config" USING (true) WITH CHECK (true);

ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";


-- Insert default config with template messages
INSERT INTO "public"."app_config" ("minimum_version", "is_maintenance_mode", "maintenance_message_en", "maintenance_message_ja", "force_update_message_en", "force_update_message_ja")
VALUES (
    '1.0.0',
    false,
    'We are currently performing scheduled maintenance to improve your experience. Please check back soon!',
    '現在、サービス向上のためメンテナンスを実施しております。しばらくしてから再度お試しください。',
    'A new version of the app is available. Please update to continue using HiNan!',
    '新しいバージョンが利用可能です。HiNan!を引き続きご利用いただくには、アップデートをお願いします。'
)
ON CONFLICT DO NOTHING;
