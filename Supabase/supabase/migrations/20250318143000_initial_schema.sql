-- MacOS-Dino – Supabase Veritabanı Şeması (Yolmov)
-- Migration: 001_initial_schema.sql
-- Tüm tablolar, RLS politikaları, indeksler, fonksiyonlar

-- =============================================================
-- 1. EXTENSIONS
-- =============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Full-text search için

-- =============================================================
-- 2. PROFILES TABLOSU
-- =============================================================
CREATE TABLE IF NOT EXISTS profiles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_url  TEXT,
    pro_until   TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT profiles_user_id_unique UNIQUE(user_id)
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes profil okuyabilir"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Kullanıcı kendi profilini güncelleyebilir"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı kendi profilini oluşturabilir"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Yeni kayıt olunca otomatik profil oluştur
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (user_id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================================
-- 3. WALLPAPERS TABLOSU
-- =============================================================
CREATE TABLE IF NOT EXISTS wallpapers (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name              TEXT NOT NULL,
    category          TEXT NOT NULL DEFAULT 'abstract',
    content_type      TEXT NOT NULL DEFAULT 'video', -- video, metal_shader, html_widget, static_image
    remote_url        TEXT NOT NULL,
    thumbnail_path    TEXT,
    storage_path      TEXT,          -- Supabase Storage path
    shader_name       TEXT,
    shader_parameters JSONB DEFAULT '{}',
    loop_start_time   DOUBLE PRECISION,
    loop_end_time     DOUBLE PRECISION,
    aspect_ratio      TEXT NOT NULL DEFAULT '16:9',
    dimensions        JSONB,         -- {"width": 3840, "height": 2160}
    file_size         BIGINT,        -- bytes
    is_featured       BOOLEAN NOT NULL DEFAULT FALSE,
    popularity_score  INTEGER NOT NULL DEFAULT 0,
    tags              TEXT[] DEFAULT '{}',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indeksler
CREATE INDEX IF NOT EXISTS idx_wallpapers_category ON wallpapers(category);
CREATE INDEX IF NOT EXISTS idx_wallpapers_content_type ON wallpapers(content_type);
CREATE INDEX IF NOT EXISTS idx_wallpapers_popularity ON wallpapers(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_wallpapers_featured ON wallpapers(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_wallpapers_name_trgm ON wallpapers USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_wallpapers_created_at ON wallpapers(created_at DESC);

-- RLS
ALTER TABLE wallpapers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes wallpaper okuyabilir"
    ON wallpapers FOR SELECT
    USING (true);

-- Admin-only insert/update/delete (service_role kullanılacak)
CREATE POLICY "Sadece admin wallpaper ekleyebilir"
    ON wallpapers FOR INSERT
    WITH CHECK (auth.jwt()->>'role' = 'service_role');

CREATE POLICY "Sadece admin wallpaper güncelleyebilir"
    ON wallpapers FOR UPDATE
    USING (auth.jwt()->>'role' = 'service_role');

-- Popülerlik artırma fonksiyonu
CREATE OR REPLACE FUNCTION increment_popularity(wallpaper_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE wallpapers
    SET popularity_score = popularity_score + 1
    WHERE id = wallpaper_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================
-- 4. USER_LIBRARY TABLOSU
-- =============================================================
CREATE TABLE IF NOT EXISTS user_library (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    wallpaper_id    UUID NOT NULL REFERENCES wallpapers(id) ON DELETE CASCADE,
    custom_transform TEXT,
    is_favorite     BOOLEAN NOT NULL DEFAULT FALSE,
    added_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_library_unique UNIQUE(user_id, wallpaper_id)
);

-- Indeksler
CREATE INDEX IF NOT EXISTS idx_user_library_user ON user_library(user_id);
CREATE INDEX IF NOT EXISTS idx_user_library_favorites ON user_library(user_id) WHERE is_favorite = TRUE;

-- RLS
ALTER TABLE user_library ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi kütüphanesini okuyabilir"
    ON user_library FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı kütüphanesine ekleyebilir"
    ON user_library FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcı kütüphanesini güncelleyebilir"
    ON user_library FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı kütüphanesinden silebilir"
    ON user_library FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================================
-- 5. SUBSCRIPTIONS TABLOSU
-- =============================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan              TEXT NOT NULL DEFAULT 'free', -- free, pro, content_only, pro_with_content
    is_pro            BOOLEAN NOT NULL DEFAULT FALSE,
    has_content_pass  BOOLEAN NOT NULL DEFAULT FALSE,
    apple_transaction_id TEXT,
    started_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at        TIMESTAMPTZ,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT subscriptions_user_unique UNIQUE(user_id)
);

-- RLS
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi aboneliğini okuyabilir"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı abonelik oluşturabilir"
    ON subscriptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Kullanıcı aboneliğini güncelleyebilir"
    ON subscriptions FOR UPDATE
    USING (auth.uid() = user_id);

-- =============================================================
-- 6. ANALYTICS_EVENTS TABLOSU
-- =============================================================
CREATE TABLE IF NOT EXISTS analytics_events (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event       TEXT NOT NULL,
    properties  JSONB DEFAULT '{}',
    app_version TEXT,
    os_version  TEXT,
    timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partition by month for performance (opsiyonel)
CREATE INDEX IF NOT EXISTS idx_analytics_event ON analytics_events(event);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON analytics_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_user ON analytics_events(user_id);

-- RLS
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes analytics yazabilir"
    ON analytics_events FOR INSERT
    WITH CHECK (true);

-- Admin-only okuma
CREATE POLICY "Sadece admin analytics okuyabilir"
    ON analytics_events FOR SELECT
    USING (auth.jwt()->>'role' = 'service_role');

-- =============================================================
-- 7. REALTIME YAYIN
-- =============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE wallpapers;
ALTER PUBLICATION supabase_realtime ADD TABLE user_library;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- =============================================================
-- 8. STORAGE BUCKETS (SQL ile oluşturulamaz, Supabase Dashboard'dan)
-- Notlar:
--   wallpaper-videos: Public + signed URL, max 500MB per file
--   thumbnails: Public, max 5MB per file, WebP preferred
--   user-uploads: Private, RLS enabled, 5GB quota per pro user
-- =============================================================

-- =============================================================
-- 9. SEED DATA – Örnek wallpaper'lar
-- =============================================================
INSERT INTO wallpapers (name, category, content_type, remote_url, aspect_ratio, dimensions, is_featured, popularity_score) VALUES
('Nebula 4K', 'deep_space', 'video', 'https://example.com/nebula.mp4', '16:9', '{"width": 3840, "height": 2160}', TRUE, 150),
('Ocean Waves', 'nature', 'video', 'https://example.com/ocean.mp4', '16:9', '{"width": 3840, "height": 2160}', TRUE, 120),
('Neon City', 'cityscape', 'video', 'https://example.com/neon-city.mp4', '16:9', '{"width": 3840, "height": 2160}', FALSE, 95),
('Liquid Glass', 'abstract', 'metal_shader', 'shader://liquidGlass', '16:9', '{"width": 3840, "height": 2160}', TRUE, 200),
('Audio Visualizer', 'visual_music', 'metal_shader', 'shader://audioReactive', '16:9', '{"width": 3840, "height": 2160}', FALSE, 80),
('Simple Wave', 'abstract', 'metal_shader', 'shader://simpleWave', '16:9', '{"width": 3840, "height": 2160}', FALSE, 110),
('Cursor Particles', 'abstract', 'metal_shader', 'shader://cursorRepel', '16:9', '{"width": 3840, "height": 2160}', TRUE, 175),
('Cherry Blossom', 'nature', 'video', 'https://example.com/cherry.mp4', '16:9', '{"width": 3840, "height": 2160}', FALSE, 65),
('Gaming Setup', 'game', 'video', 'https://example.com/gaming.mp4', '16:9', '{"width": 3840, "height": 2160}', FALSE, 88),
('Anime Night', 'animation', 'video', 'https://example.com/anime-night.mp4', '16:9', '{"width": 3840, "height": 2160}', FALSE, 72),
('Totoro Forest', 'cartoon', 'video', 'https://example.com/totoro.mp4', '4:3', '{"width": 2560, "height": 1920}', TRUE, 140),
('Matrix Rain', 'abstract', 'metal_shader', 'shader://matrix', '16:9', '{"width": 3840, "height": 2160}', FALSE, 99),
('Cute Cats', 'cute_pet', 'video', 'https://example.com/cats.mp4', '16:9', '{"width": 1920, "height": 1080}', FALSE, 55),
('Deep Space 8K', 'deep_space', 'video', 'https://example.com/space-8k.mp4', '16:9', '{"width": 7680, "height": 4320}', TRUE, 180),
('Minimal Gradient', 'minimal', 'metal_shader', 'shader://gradient', '16:9', '{"width": 3840, "height": 2160}', FALSE, 45);
