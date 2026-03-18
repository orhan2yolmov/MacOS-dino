// RealtimeService.swift
// MacOS-Dino – Supabase Realtime Servisi
// Wallpaper ve kullanıcı kütüphanesi canlı değişiklik takibi

import Foundation
import Supabase
import Realtime

@MainActor
final class RealtimeService: ObservableObject {

    static let shared = RealtimeService()

    // MARK: - Callbacks

    var onWallpaperAdded: ((Wallpaper) -> Void)?
    var onWallpaperUpdated: ((Wallpaper) -> Void)?
    var onWallpaperDeleted: ((UUID) -> Void)?
    var onLibraryChanged: (() -> Void)?

    // MARK: - Channels

    private var wallpapersChannel: RealtimeChannelV2?
    private var libraryChannel: RealtimeChannelV2?

    private init() {}

    // MARK: - Subscribe

    func subscribeToWallpapers() async {
        let channel = supabase.realtimeV2.channel(SupabaseConfig.Channels.wallpapers)

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: SupabaseConfig.Tables.wallpapers
        )

        await channel.subscribe()
        wallpapersChannel = channel

        Task {
            for await change in changes {
                await handleWallpaperChange(change)
            }
        }

        print("📡 Wallpapers realtime dinleniyor")
    }

    func subscribeToUserLibrary(userId: UUID) async {
        let channel = supabase.realtimeV2.channel(SupabaseConfig.Channels.userLibrary)

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: SupabaseConfig.Tables.userLibrary,
            filter: "user_id=eq.\(userId.uuidString)"
        )

        await channel.subscribe()
        libraryChannel = channel

        Task {
            for await _ in changes {
                self.onLibraryChanged?()
            }
        }

        print("📡 User library realtime dinleniyor: \(userId)")
    }

    // MARK: - Unsubscribe

    func unsubscribeAll() async {
        if let channel = wallpapersChannel {
            await channel.unsubscribe()
            wallpapersChannel = nil
        }
        if let channel = libraryChannel {
            await channel.unsubscribe()
            libraryChannel = nil
        }
    }

    // MARK: - Handle Changes

    private func handleWallpaperChange(_ change: AnyAction) async {
        switch change {
        case .insert(let action):
            if let record = action.record as? [String: Any],
               let wallpaper = try? decodeWallpaper(from: record) {
                onWallpaperAdded?(wallpaper)
            }
        case .update(let action):
            if let record = action.record as? [String: Any],
               let wallpaper = try? decodeWallpaper(from: record) {
                onWallpaperUpdated?(wallpaper)
            }
        case .delete(let action):
            if let oldRecord = action.oldRecord as? [String: Any],
               let idString = oldRecord["id"] as? String,
               let id = UUID(uuidString: idString) {
                onWallpaperDeleted?(id)
            }
        default:
            break
        }
    }

    private func decodeWallpaper(from record: [String: Any]) throws -> Wallpaper? {
        let data = try JSONSerialization.data(withJSONObject: record)
        return try JSONDecoder().decode(Wallpaper.self, from: data)
    }
}
