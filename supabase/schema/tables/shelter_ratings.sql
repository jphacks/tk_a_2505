-- Shelter ratings and reviews table
-- Stores user ratings (1-5 stars) and optional reviews for emergency shelters
-- Only users who have collected a shelter's badge can rate it

CREATE TABLE shelter_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shelter_id UUID NOT NULL REFERENCES shelters(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Rating: 1-5 stars (required)
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),

    -- Review text: optional, max 500 characters
    review TEXT CHECK (review IS NULL OR LENGTH(review) <= 500),

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- One rating per user per shelter
    CONSTRAINT unique_user_shelter_rating UNIQUE(shelter_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_shelter_ratings_shelter_id ON shelter_ratings(shelter_id);
CREATE INDEX idx_shelter_ratings_user_id ON shelter_ratings(user_id);
CREATE INDEX idx_shelter_ratings_created_at ON shelter_ratings(created_at DESC);

-- Trigger to auto-update updated_at timestamp when rating is edited
CREATE OR REPLACE FUNCTION update_shelter_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shelter_ratings_updated_at
    BEFORE UPDATE ON shelter_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_shelter_ratings_updated_at();

-- Table and column comments for documentation
COMMENT ON TABLE shelter_ratings IS 'User ratings and reviews for emergency shelters. Only users who have physically visited shelters (collected badges) can submit ratings.';
COMMENT ON COLUMN shelter_ratings.rating IS '1-5 star rating for overall shelter quality';
COMMENT ON COLUMN shelter_ratings.review IS 'Optional review text describing shelter conditions, max 500 characters';
COMMENT ON COLUMN shelter_ratings.created_at IS 'Timestamp when rating was first created';
COMMENT ON COLUMN shelter_ratings.updated_at IS 'Timestamp when rating was last modified (auto-updated)';
