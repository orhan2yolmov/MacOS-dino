// SupabaseClient.swift
// MacOS-Dino – Supabase İstemci Yapılandırması
// Veritabanı Projesi: Yolmov (https://uwslxmciglqxpvfbgjzm.supabase.co)

import Foundation
import Supabase

// MARK: - Supabase Configuration

enum SupabaseConfig {
    /// Yolmov Supabase Project URL
    static let projectURL = URL(string: "https://uwslxmciglqxpvfbgjzm.supabase.co")!

    /// Publishable Key – Frontend kullanımı, RLS aktif tablolarda güvenli
    static let publishableKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3c2x4bWNpZ2xxeHB2ZmJnanptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMzU3NDcsImV4cCI6MjA3OTkxMTc0N30.Pzk2Zrp08-f93VoApIj6QjWx_9nEQSkZFRU_t1UX_ow"

    // MARK: - Table Names
    enum Tables {
        static let profiles = "dino_profiles"
        static let wallpapers = "dino_wallpapers"
        static let userLibrary = "dino_user_library"
        static let subscriptions = "dino_subscriptions"
        static let analyticsEvents = "dino_analytics_events"
    }

    // MARK: - Storage Buckets
    enum Buckets {
        static let wallpaperVideos = "dino-wallpaper-videos"
        static let thumbnails = "dino-thumbnails"
        static let userUploads = "dino-user-uploads"
    }

    // MARK: - Realtime Channels
    enum Channels {
        static let wallpapers = "wallpapers-changes"
        static let userLibrary = "user-library-changes"
    }
}

// MARK: - Shared Client

/// Uygulama genelinde kullanılan Supabase istemci örneği
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.publishableKey
)
