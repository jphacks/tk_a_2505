-- Helper functions for shelter rating system

-- Function: Get average rating and total count for a shelter
-- Returns summary statistics used for displaying ratings on map markers and detail views
CREATE OR REPLACE FUNCTION get_shelter_rating_summary(shelter_uuid UUID)
RETURNS TABLE (
    average_rating NUMERIC,
    total_ratings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(ROUND(AVG(rating)::numeric, 1), 0) as average_rating,
        COUNT(*) as total_ratings
    FROM shelter_ratings
    WHERE shelter_id = shelter_uuid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_shelter_rating_summary IS 'Returns average rating (rounded to 1 decimal) and total count for a shelter. Returns 0 if no ratings exist.';


-- Function: Check if user has badge for shelter (authorization helper)
-- Used by RLS policies to verify user can rate a shelter
CREATE OR REPLACE FUNCTION user_can_rate_shelter(
    user_uuid UUID,
    shelter_uuid UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_shelter_badges usb
        JOIN shelter_badges sb ON usb.badge_id = sb.id
        WHERE usb.user_id = user_uuid
        AND sb.shelter_id = shelter_uuid
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION user_can_rate_shelter IS 'Returns true if user has collected the badge for the specified shelter (proves physical visit)';
