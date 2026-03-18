-- MacOS-Dino – Supabase Veritabanı Şeması (Yolmov)
-- Tüm tablolar dino_ prefix'i ile (paylaşımlı DB'de çakışma önleme)

-- =============================================================
-- 1. EXTENSIONS
-- =============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================================
-- 2. DINO_PROFILES
-- =============================================================
CREATE TABLE IF NOT EXISTS dino_profiles (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_url   TEXT,
    pro_until    TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT dino_profiles_user_id_unique UNIQUE(user_id)
);

ALTER TABLE dino_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dino_profiles_select" ON dino_profiles FOR SELECT USING (true);
CREATE POLICY "dino_profiles_update" ON dino_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "dino_profiles_insert" ON dino_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION dino_handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO dino_profiles (user_id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS dino_on_auth_user_created ON auth.users;
CREATE TRIGGER dino_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION dino_handle_new_user();

-- =============================================================
-- 3. DINO_WALLPAPERS
-- =============================================================
CREATE TABLE IF NOT EXISTS dino_wallpapers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name              TEXT NOT NULL,
    category          TEXT NOT NULL DEFAULT 'abstract',
    content_type      TEXT NOT NULL DEFAULT 'video',
    remote_url        TEXT NOT NULL,
    thumbnail_path    TEXT,
    storage_path      TEXT,
    shader_name       TEXT,
    shader_parameters JSONB DEFAULT '{}',
    loop_start_time   DOUBLE PRECISION,
    loop_end_time     DOUBLE PRECISION,
    aspect_ratio      TEXT NOT NULL DEFAULT '16:9',
    dimensions        JSONB,
    file_size         BIGINT,
    is_featured       BOOLEAN NOT NULL DEFAULT FALSE,
    popularity_score  INTEGER NOT NULL DEFAULT 0,
    tags              TEXT[] DEFAULT '{}',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dino_wp_category ON dino_wallpapers(category);
CREATE INDEX IF NOT EXISTS idx_dino_wp_content_type ON dino_wallpapers(content_type);
CREATE INDEX IF NOT EXISTS idx_dino_wp_popularity ON dino_wallpapers(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_dino_wp_featured ON dino_wallpapers(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_dino_wp_name_trgm ON dino_wallpapers USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_dino_wp_created_at ON dino_wallpapers(created_at DESC);

ALTER TABLE dino_wallpapers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dino_wallpapers_select" ON dino_wallpapers FOR SELECT USING (true);
CREATE POLICY "dino_wallpapers_insert" ON dino_wallpapers FOR INSERT WITH CHECK (auth.jwt()->>'role' = 'service_role');
CREATE POLICY "dino_wallpapers_update" ON dino_wallpapers FOR UPDATE USING (auth.jwt()->>'role' = 'service_role');

CREATE OR REPLACE FUNCTION dino_increment_popularity(wp_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE dino_wallpapers SET popularity_score = popularity_score + 1 WHERE id = wp_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================
-- 4. DINO_USER_LIBRARY
-- =============================================================
CREATE TABLE IF NOT EXISTS dino_user_library (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    wallpaper_id     UUID NOT NULL REFERENCES dino_wallpapers(id) ON DELETE CASCADE,
    custom_transform TEXT,
    is_favorite      BOOLEAN NOT NULL DEFAULT FALSE,
    added_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT dino_user_library_unique UNIQUE(user_id, wallpaper_id)
);

CREATE INDEX IF NOT EXISTS idx_dino_ul_user ON dino_user_library(user_id);
CREATE INDEX IF NOT EXISTS idx_dino_ul_fav ON dino_user_library(user_id) WHERE is_favorite = TRUE;

ALTER TABLE dino_user_library ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dino_ul_select" ON dino_user_library FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "dino_ul_insert" ON dino_user_library FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "dino_ul_update" ON dino_user_library FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "dino_ul_delete" ON dino_user_library FOR DELETE USING (auth.uid() = user_id);

-- =============================================================
-- 5. DINO_SUBSCRIPTIONS
-- =============================================================
CREATE TABLE IF NOT EXISTS dino_subscriptions (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan                 TEXT NOT NULL DEFAULT 'free',
    is_pro               BOOLEAN NOT NULL DEFAULT FALSE,
    has_content_pass     BOOLEAN NOT NULL DEFAULT FALSE,
    apple_transaction_id TEXT,
    started_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at           TIMESTAMPTZ,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT dino_subscriptions_user_unique UNIQUE(user_id)
);

ALTER TABLE dino_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dino_sub_select" ON dino_subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "dino_sub_insert" ON dino_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "dino_sub_update" ON dino_subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- =============================================================
-- 6. DINO_ANALYTICS_EVENTS
-- =============================================================
CREATE TABLE IF NOT EXISTS dino_analytics_events (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event       TEXT NOT NULL,
    properties  JSONB DEFAULT '{}',
    app_version TEXT,
    os_version  TEXT,
    timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dino_ae_event ON dino_analytics_events(event);
CREATE INDEX IF NOT EXISTS idx_dino_ae_ts ON dino_analytics_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_dino_ae_user ON dino_analytics_events(user_id);

ALTER TABLE dino_analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dino_ae_insert" ON dino_analytics_events FOR INSERT WITH CHECK (true);
CREATE POLICY "dino_ae_select" ON dino_analytics_events FOR SELECT USING (auth.jwt()->>'role' = 'service_role');

-- =============================================================
-- 7. REALTIME
-- =============================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE dino_wallpapers;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE dino_user_library;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE dino_profiles;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================
-- 8. SEED DATA
-- =============================================================
INSERT INTO dino_wallpapers (name, category, content_type, remote_url, aspect_ratio, dimensions, is_featured, popularity_score) VALUES
('Nebula 4K',        'deep_space',    'video',        'https://example.com/nebula.mp4',       '16:9', '{"width":3840,"height":2160}', TRUE,  150),
('Ocean Waves',      'nature',        'video',        'https://example.com/ocean.mp4',        '16:9', '{"width":3840,"height":2160}', TRUE,  120),
('Neon City',        'cityscape',     'video',        'https://example.com/neon-city.mp4',    '16:9', '{"width":3840,"height":2160}', FALSE, 95),
('Liquid Glass',     'abstract',      'metal_shader', 'shader://liquidGlass',                 '16:9', '{"width":3840,"height":2160}', TRUE,  200),
('Audio Visualizer', 'visual_music',  'metal_shader', 'shader://audioReactive',               '16:9', '{"width":3840,"height":2160}', FALSE, 80),
('Simple Wave',      'abstract',      'metal_shader', 'shader://simpleWave',                  '16:9', '{"width":3840,"height":2160}', FALSE, 110),
('Cursor Particles', 'abstract',      'metal_shader', 'shader://cursorRepel',                 '16:9', '{"width":3840,"height":2160}', TRUE,  175),
('Cherry Blossom',   'nature',        'video',        'https://example.com/cherry.mp4',       '16:9', '{"width":3840,"height":2160}', FALSE, 65),
('Gaming Setup',     'game',          'video',        'https://example.com/gaming.mp4',       '16:9', '{"width":3840,"height":2160}', FALSE, 88),
('Anime Night',      'animation',     'video',        'https://example.com/anime-night.mp4',  '16:9', '{"width":3840,"height":2160}', FALSE, 72),
('Totoro Forest',    'cartoon',       'video',        'https://example.com/totoro.mp4',       '4:3',  '{"width":2560,"height":1920}', TRUE,  140),
('Matrix Rain',      'abstract',      'metal_shader', 'shader://matrix',                      '16:9', '{"width":3840,"height":2160}', FALSE, 99),
('Cute Cats',        'cute_pet',      'video',        'https://example.com/cats.mp4',         '16:9', '{"width":1920,"height":1080}', FALSE, 55),
('Deep Space 8K',    'deep_space',    'video',        'https://example.com/space-8k.mp4',     '16:9', '{"width":7680,"height":4320}', TRUE,  180),
('Minimal Gradient', 'minimal',       'metal_shader', 'shader://gradient',                    '16:9', '{"width":3840,"height":2160}', FALSE, 45)
ON CONFLICT DO NOTHING;
