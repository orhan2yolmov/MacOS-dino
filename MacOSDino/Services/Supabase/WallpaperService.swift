// WallpaperService.swift
// MacOS-Dino – Supabase Wallpaper CRUD Servisi
// Wallpaper listeleme, filtreleme, favoriler, kullanıcı kütüphanesi

import Foundation
import Supabase

final class WallpaperService {

    static let shared = WallpaperService()
    private init() {}

    // MARK: - Fetch Wallpapers

    /// Tüm wallpaper'ları getir (sayfalama destekli)
    func fetchWallpapers(
        page: Int = 0,
        pageSize: Int = 20,
        category: WallpaperCategory? = nil,
        ratio: AspectRatio? = nil,
        sortBy: WallpaperSortOption = .hot
    ) async throws -> [Wallpaper] {
        var query = supabase
            .from(SupabaseConfig.Tables.wallpapers)
            .select()

        // Kategori filtresi
        if let category {
            query = query.eq("category", value: category.rawValue)
        }

        // En-boy oranı filtresi
        if let ratio {
            query = query.eq("aspect_ratio", value: ratio.rawValue)
        }

        // Sıralama
        switch sortBy {
        case .hot:
            query = query.order("popularity_score", ascending: false)
        case .new:
            query = query.order("created_at", ascending: false)
        case .featured:
            query = query.eq("is_featured", value: true).order("created_at", ascending: false)
        }

        // Sayfalama
        let from = page * pageSize
        let to = from + pageSize - 1
        query = query.range(from: from, to: to)

        let wallpapers: [Wallpaper] = try await query.execute().value
        return wallpapers
    }

    /// Tek wallpaper detayını getir
    func fetchWallpaper(id: UUID) async throws -> Wallpaper {
        let wallpaper: Wallpaper = try await supabase
            .from(SupabaseConfig.Tables.wallpapers)
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return wallpaper
    }

    /// Wallpaper ara
    func searchWallpapers(query: String) async throws -> [Wallpaper] {
        let wallpapers: [Wallpaper] = try await supabase
            .from(SupabaseConfig.Tables.wallpapers)
            .select()
            .ilike("name", pattern: "%\(query)%")
            .order("popularity_score", ascending: false)
            .limit(50)
            .execute()
            .value

        return wallpapers
    }

    // MARK: - User Library

    /// Kullanıcının kütüphanesindeki wallpaper'ları getir
    func fetchUserLibrary(userId: UUID) async throws -> [UserLibraryItem] {
        let items: [UserLibraryItem] = try await supabase
            .from(SupabaseConfig.Tables.userLibrary)
            .select("*, dino_wallpapers(*)")
            .eq("user_id", value: userId)
            .order("added_at", ascending: false)
            .execute()
            .value

        return items
    }

    /// Kütüphaneye wallpaper ekle
    func addToLibrary(userId: UUID, wallpaperId: UUID) async throws {
        let item = UserLibraryItem(
            id: UUID(),
            userId: userId,
            wallpaperId: wallpaperId,
            customTransform: nil,
            addedAt: Date()
        )

        try await supabase
            .from(SupabaseConfig.Tables.userLibrary)
            .insert(item)
            .execute()
    }

    /// Kütüphaneden wallpaper kaldır
    func removeFromLibrary(userId: UUID, wallpaperId: UUID) async throws {
        try await supabase
            .from(SupabaseConfig.Tables.userLibrary)
            .delete()
            .eq("user_id", value: userId)
            .eq("wallpaper_id", value: wallpaperId)
            .execute()
    }

    // MARK: - Favorites

    /// Favorilere ekle/çıkar
    func toggleFavorite(userId: UUID, wallpaperId: UUID) async throws -> Bool {
        // Favori var mı kontrol et
        let existing: [UserLibraryItem] = try await supabase
            .from(SupabaseConfig.Tables.userLibrary)
            .select()
            .eq("user_id", value: userId)
            .eq("wallpaper_id", value: wallpaperId)
            .eq("is_favorite", value: true)
            .execute()
            .value

        if existing.isEmpty {
            // Favoriye ekle
            try await supabase
                .from(SupabaseConfig.Tables.userLibrary)
                .upsert([
                    "user_id": userId.uuidString,
                    "wallpaper_id": wallpaperId.uuidString,
                    "is_favorite": "true"
                ])
                .execute()
            return true
        } else {
            // Favoriden çıkar
            try await supabase
                .from(SupabaseConfig.Tables.userLibrary)
                .update(["is_favorite": "false"])
                .eq("user_id", value: userId)
                .eq("wallpaper_id", value: wallpaperId)
                .execute()
            return false
        }
    }

    /// Favori wallpaper'ları getir
    func fetchFavorites(userId: UUID) async throws -> [Wallpaper] {
        let items: [UserLibraryItem] = try await supabase
            .from(SupabaseConfig.Tables.userLibrary)
            .select("*, dino_wallpapers(*)")
            .eq("user_id", value: userId)
            .eq("is_favorite", value: true)
            .order("added_at", ascending: false)
            .execute()
            .value

        return items.compactMap { $0.wallpaper }
    }

    // MARK: - Popularity

    /// Wallpaper popülerlik skorunu artır
    func incrementPopularity(wallpaperId: UUID) async {
        do {
            try await supabase.rpc("increment_popularity", params: [
                "wallpaper_id": wallpaperId.uuidString
            ]).execute()
        } catch {
            print("⚠️ Popülerlik artırılamadı: \(error)")
        }
    }
}

// MARK: - Sort Options

enum WallpaperSortOption: String, CaseIterable {
    case hot = "hot"
    case new = "new"
    case featured = "featured"

    var displayName: String {
        switch self {
        case .hot: return "Popüler"
        case .new: return "Yeni"
        case .featured: return "Öne Çıkan"
        }
    }

    var icon: String {
        switch self {
        case .hot: return "flame.fill"
        case .new: return "sparkles"
        case .featured: return "star.fill"
        }
    }
}
