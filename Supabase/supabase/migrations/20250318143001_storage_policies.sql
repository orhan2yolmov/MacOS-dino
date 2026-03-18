-- MacOS-Dino – Storage Bucket Politikaları
-- Migration: 002_storage_policies.sql
-- NOT: Bucket'lar Supabase Dashboard'dan oluşturulmalıdır
-- Bu dosya sadece storage RLS politikalarını tanımlar

-- =============================================================
-- wallpaper-videos bucket politikaları
-- =============================================================

-- Herkes public wallpaper videolarını okuyabilir
CREATE POLICY "Public wallpaper videos are viewable by everyone"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'wallpaper-videos');

-- Sadece admin video yükleyebilir
CREATE POLICY "Only admins can upload wallpaper videos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'wallpaper-videos'
        AND auth.jwt()->>'role' = 'service_role'
    );

-- =============================================================
-- thumbnails bucket politikaları
-- =============================================================

-- Herkes thumbnail okuyabilir
CREATE POLICY "Thumbnails are public"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'thumbnails');

-- Kullanıcılar kendi avatarlarını yükleyebilir
CREATE POLICY "Users can upload their own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'thumbnails'
        AND (
            auth.jwt()->>'role' = 'service_role'
            OR (storage.foldername(name))[1] = 'avatars'
        )
    );

-- =============================================================
-- user-uploads bucket politikaları
-- =============================================================

-- Kullanıcı kendi dosyalarını okuyabilir
CREATE POLICY "Users can read own uploads"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Kullanıcı kendi klasörüne yükleyebilir
CREATE POLICY "Users can upload to own folder"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Kullanıcı kendi dosyalarını silebilir
CREATE POLICY "Users can delete own uploads"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'user-uploads'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
