-- Row Level Security (RLS) policies for shelter_ratings table
-- Ensures only badged users can rate shelters they've physically visited

-- Enable Row Level Security
ALTER TABLE shelter_ratings ENABLE ROW LEVEL SECURITY;


-- Policy 1: Public read access
-- Anyone (authenticated or not) can view all ratings and reviews
CREATE POLICY "Anyone can view ratings"
    ON shelter_ratings
    FOR SELECT
    USING (true);

COMMENT ON POLICY "Anyone can view ratings" ON shelter_ratings IS
    'Public read access - anyone can see ratings and reviews for shelters';


-- Policy 2: Badge-gated insert
-- Users can only insert ratings for shelters they have physically visited (have badge)
CREATE POLICY "Can rate only visited shelters"
    ON shelter_ratings
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND user_can_rate_shelter(auth.uid(), shelter_id)
    );

COMMENT ON POLICY "Can rate only visited shelters" ON shelter_ratings IS
    'Users can only rate shelters they have physically visited and collected the badge for. This ensures authenticity of ratings.';


-- Policy 3: Users can update their own ratings
-- Must still have the badge (prevents edge case where user loses badge after rating)
CREATE POLICY "Users can update own ratings"
    ON shelter_ratings
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id
        AND user_can_rate_shelter(auth.uid(), shelter_id)
    );

COMMENT ON POLICY "Users can update own ratings" ON shelter_ratings IS
    'Users can edit their ratings anytime, as long as they still have the badge for that shelter';


-- Policy 4: Users can delete their own ratings
CREATE POLICY "Users can delete own ratings"
    ON shelter_ratings
    FOR DELETE
    USING (auth.uid() = user_id);

COMMENT ON POLICY "Users can delete own ratings" ON shelter_ratings IS
    'Users can remove their ratings anytime';
