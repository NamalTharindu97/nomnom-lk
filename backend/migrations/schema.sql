-- ============================================================
-- NomNom LK — Full Database Schema
-- PostgreSQL 16
-- ============================================================

-- ─── Users ───────────────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255),
    name            VARCHAR(255) NOT NULL,
    avatar_url      TEXT,
    role            VARCHAR(20) NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user', 'restaurant_owner', 'admin')),
    firebase_uid    VARCHAR(128) UNIQUE,
    phone           VARCHAR(20),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Restaurants ────────────────────────────────────────────
CREATE TABLE restaurants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID REFERENCES users(id) ON DELETE SET NULL,
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) UNIQUE NOT NULL,
    description     TEXT,
    address         TEXT NOT NULL,
    latitude        DECIMAL(10,7),
    longitude       DECIMAL(10,7),
    contact_phone   VARCHAR(20),
    cuisine_tags    TEXT[] DEFAULT '{}',
    cover_image     TEXT,
    translations    JSONB DEFAULT '{}',
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),
    is_featured     BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_restaurants_owner ON restaurants(owner_id);
CREATE INDEX idx_restaurants_status ON restaurants(status);
CREATE INDEX idx_restaurants_cuisine ON restaurants USING GIN(cuisine_tags);

-- ─── Offers ─────────────────────────────────────────────────
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

-- ─── Favorites ──────────────────────────────────────────────
CREATE TABLE favorites (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    offer_id    UUID NOT NULL REFERENCES offers(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, offer_id)
);

CREATE INDEX idx_favorites_user ON favorites(user_id, created_at DESC);

-- ─── Notifications ──────────────────────────────────────────
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        TEXT,
    data        JSONB,
    is_read     BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- ─── Device Tokens (FCM) ────────────────────────────────────
CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    VARCHAR(10) CHECK (platform IN ('ios', 'android')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

-- ─── Refresh Tokens ─────────────────────────────────────────
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- ============================================================
-- Entity Relationship Summary
-- ============================================================
-- users 1──N restaurants     (owner)
-- users 1──N offers          (created_by)
-- users 1──N favorites       (user_id)
-- users 1──N notifications   (user_id)
-- users 1──N device_tokens   (user_id)
-- users 1──N refresh_tokens  (user_id)
-- restaurants 1──N offers    (restaurant_id)
-- offers 1──N favorites      (offer_id)
