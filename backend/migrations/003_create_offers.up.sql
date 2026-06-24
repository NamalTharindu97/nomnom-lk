CREATE TABLE offers (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id    UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    title            VARCHAR(255) NOT NULL,
    description      TEXT,
    original_price   DECIMAL(10,2) NOT NULL CHECK (original_price > 0),
    offer_price      DECIMAL(10,2) NOT NULL CHECK (offer_price > 0),
    discount_percent INTEGER GENERATED ALWAYS AS (
                         ROUND((1 - offer_price / original_price) * 100)
                     ) STORED,
    image_urls       TEXT[] DEFAULT '{}',
    translations     JSONB DEFAULT '{}',
    start_date       TIMESTAMPTZ DEFAULT NOW(),
    end_date         TIMESTAMPTZ NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    rejection_reason TEXT,
    created_by       UUID REFERENCES users(id),
    view_count       INTEGER DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (offer_price < original_price)
);

ALTER TABLE offers ADD COLUMN search_vector TSVECTOR
    GENERATED ALWAYS AS (
        to_tsvector('simple',
            coalesce(title, '') || ' ' || coalesce(description, '')
        )
    ) STORED;

CREATE INDEX idx_offers_search ON offers USING GIN(search_vector);
CREATE INDEX idx_offers_restaurant ON offers(restaurant_id);
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_end_date ON offers(end_date) WHERE status = 'approved';
CREATE INDEX idx_offers_created ON offers(created_at DESC);
