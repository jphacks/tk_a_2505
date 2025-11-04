-- ========================================
-- Group Policies
-- ========================================

-- Groups table policies
CREATE POLICY "Groups are viewable by members" ON "public"."groups"
    FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."group_members"
  WHERE (("group_members"."group_id" = "groups"."id") AND ("group_members"."user_id" = "auth"."uid"())))));

CREATE POLICY "Groups are updatable by owner" ON "public"."groups"
    FOR UPDATE USING (("owner_id" = "auth"."uid"()));

CREATE POLICY "Groups are deletable by owner" ON "public"."groups"
    FOR DELETE USING (("owner_id" = "auth"."uid"()));

CREATE POLICY "Authenticated users can create groups" ON "public"."groups"
    FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));

-- Group members table policies
CREATE POLICY "Group members are viewable by group members" ON "public"."group_members"
    FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."group_members" gm
  WHERE (("gm"."group_id" = "group_members"."group_id") AND ("gm"."user_id" = "auth"."uid"())))));

CREATE POLICY "Authenticated users can join groups" ON "public"."group_members"
    FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));

CREATE POLICY "Users can update their own membership" ON "public"."group_members"
    FOR UPDATE USING (("user_id" = "auth"."uid"()));

CREATE POLICY "Members can leave or be removed by admin" ON "public"."group_members"
    FOR DELETE USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."group_members" gm
  WHERE (("gm"."group_id" = "group_members"."group_id") AND ("gm"."user_id" = "auth"."uid"()) AND ("gm"."role" = ANY (ARRAY['owner'::character varying, 'admin'::character varying])))))));
