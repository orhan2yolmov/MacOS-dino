-- MacOS-Dino – Storage Bucket'lar ve Politikaları

-- =============================================================
-- 1. BUCKET'LARI OLUŞTUR
-- =============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('dino-wallpaper-videos', 'dino-wallpaper-videos', true,  524288000, ARRAY['video/mp4','video/quicktime','video/x-m4v','video/webm']),
    ('dino-thumbnails',       'dino-thumbnails',       true,  5242880,   ARRAY['image/webp','image/png','image/jpeg','image/avif']),
    ('dino-user-uploads',     'dino-user-uploads',     false, 524288000, ARRAY['video/mp4','video/quicktime','video/x-m4v','image/png','image/jpeg','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 2. WALLPAPER VIDEOS – herkes okuyabilir, admin yükler
-- =============================================================
CREATE POLICY "dino_wv_select"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'dino-wallpaper-videos');

CREATE POLICY "dino_wv_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'dino-wallpaper-videos'
        AND auth.jwt()->>'role' = 'service_role'
    );

-- =============================================================
-- 3. THUMBNAILS – herkes okuyabilir, admin + avatar klasörü
-- =============================================================
CREATE POLICY "dino_th_select"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'dino-thumbnails');

CREATE POLICY "dino_th_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'dino-thumbnails'
        AND (
            auth.jwt()->>'role' = 'service_role'
            OR (storage.foldername(name))[1] = 'avatars'
        )
    );

-- =============================================================
-- 4. USER UPLOADS – kullanıcı kendi klasörüne CRUD
-- =============================================================
CREATE POLICY "dino_uu_select"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'dino-user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "dino_uu_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'dino-user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "dino_uu_delete"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'dino-user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
