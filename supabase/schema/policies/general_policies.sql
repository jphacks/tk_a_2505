-- ========================================
-- General Policies for other tables
-- ========================================

-- Points table
CREATE POLICY "access all" ON "public"."points" USING (true) WITH CHECK (true);

-- Missions table
CREATE POLICY "all access" ON "public"."missions" USING (true) WITH CHECK (true);

-- Shelter badges table
CREATE POLICY "all access" ON "public"."shelter_badges" USING (true) WITH CHECK (true);

-- Shelters table
CREATE POLICY "all access" ON "public"."shelters" USING (true) WITH CHECK (true);

-- User shelter badges table
CREATE POLICY "all access" ON "public"."user_shelter_badges" USING (true) WITH CHECK (true);

-- Mission results table
CREATE POLICY "all access" ON "public"."mission_results" USING (true) WITH CHECK (true);
