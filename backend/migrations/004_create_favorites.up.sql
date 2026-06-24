CREATE TABLE favorites (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    offer_id    UUID NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, offer_id)
);

CREATE INDEX idx_favorites_user ON favorites(user_id, created_at DESC);
