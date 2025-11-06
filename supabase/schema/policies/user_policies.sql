-- ========================================
-- User Policies
-- ========================================

CREATE POLICY "access all" ON "public"."users" USING (true) WITH CHECK (true);
