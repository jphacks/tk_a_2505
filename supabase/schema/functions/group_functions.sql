-- ========================================
-- Group Functions
-- ========================================

-- 1. 招待コード生成関数
CREATE OR REPLACE FUNCTION "public"."generate_invite_code"()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 2. グループ作成時の自動処理関数
CREATE OR REPLACE FUNCTION "public"."create_group_with_owner"(
    p_name VARCHAR(100),
    p_description TEXT DEFAULT NULL,
    p_max_members INTEGER DEFAULT 50
) RETURNS UUID AS $$
DECLARE
    new_group_id UUID;
    current_user_id UUID;
    invite_code TEXT;
BEGIN
    -- 現在のユーザーIDを取得
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated';
    END IF;

    -- ユニークな招待コードを生成
    LOOP
        invite_code := generate_invite_code();
        EXIT WHEN NOT EXISTS (SELECT 1 FROM groups WHERE groups.invite_code = invite_code);
    END LOOP;

    -- グループを作成
    INSERT INTO groups (name, description, owner_id, invite_code, max_members)
    VALUES (p_name, p_description, current_user_id, invite_code, p_max_members)
    RETURNING id INTO new_group_id;

    -- オーナーをメンバーとして追加
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (new_group_id, current_user_id, 'owner');

    RETURN new_group_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. グループ参加関数
CREATE OR REPLACE FUNCTION "public"."join_group_by_invite_code"(p_invite_code VARCHAR(8))
RETURNS UUID AS $$
DECLARE
    group_id_to_join UUID;
    current_user_id UUID;
    member_count INTEGER;
    max_members INTEGER;
BEGIN
    -- 現在のユーザーIDを取得
    current_user_id := auth.uid();

    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated';
    END IF;

    -- グループを取得
    SELECT id, max_members INTO group_id_to_join, max_members
    FROM groups
    WHERE groups.invite_code = p_invite_code;

    IF group_id_to_join IS NULL THEN
        RAISE EXCEPTION 'Invalid invite code';
    END IF;

    -- 既にメンバーかチェック
    IF EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id_to_join AND user_id = current_user_id) THEN
        RAISE EXCEPTION 'User is already a member of this group';
    END IF;

    -- メンバー数上限チェック
    SELECT COUNT(*) INTO member_count FROM group_members WHERE group_id = group_id_to_join;
    IF member_count >= max_members THEN
        RAISE EXCEPTION 'Group is full';
    END IF;

    -- メンバーとして追加
    INSERT INTO group_members (group_id, user_id, role)
    VALUES (group_id_to_join, current_user_id, 'member');

    RETURN group_id_to_join;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_invite_code"() TO "service_role";

GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_group_with_owner"(character varying, text, integer) TO "service_role";

GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."join_group_by_invite_code"(character varying) TO "service_role";
