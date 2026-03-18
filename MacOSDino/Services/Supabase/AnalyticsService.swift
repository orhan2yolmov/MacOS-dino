// AnalyticsService.swift
// MacOS-Dino – Supabase Analytics Servisi
// Kullanıcı etkileşim takibi, kullanım istatistikleri

import Foundation

final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Event Types

    enum EventType: String {
        case wallpaperApplied = "wallpaper_applied"
        case wallpaperPreviewed = "wallpaper_previewed"
        case wallpaperDownloaded = "wallpaper_downloaded"
        case wallpaperFavorited = "wallpaper_favorited"
        case shaderUsed = "shader_used"
        case categoryBrowsed = "category_browsed"
        case searchPerformed = "search_performed"
        case settingsChanged = "settings_changed"
        case appLaunched = "app_launched"
        case appClosed = "app_closed"
        case subscriptionStarted = "subscription_started"
        case subscriptionCancelled = "subscription_cancelled"
    }

    // MARK: - Track Event

    func trackEvent(
        _ event: EventType,
        properties: [String: String] = [:]
    ) async {
        let userId = try? await supabase.auth.session.user.id

        var record: [String: String] = [
            "event": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString
        ]

        if let userId {
            record["user_id"] = userId.uuidString
        }

        // Properties ekle
        for (key, value) in properties {
            record["prop_\(key)"] = value
        }

        do {
            try await supabase
                .from(SupabaseConfig.Tables.analyticsEvents)
                .insert(record)
                .execute()
        } catch {
            // Analytics hatası uygulamayı bozmamalı
            print("⚠️ Analytics kaydı başarısız: \(error.localizedDescription)")
        }
    }

    // MARK: - Batch Tracking

    private var eventQueue: [[String: String]] = []
    private let batchSize = 10

    func queueEvent(_ event: EventType, properties: [String: String] = [:]) {
        var record: [String: String] = [
            "event": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        for (key, value) in properties {
            record["prop_\(key)"] = value
        }
        eventQueue.append(record)

        if eventQueue.count >= batchSize {
            Task { await flushEvents() }
        }
    }

    func flushEvents() async {
        guard !eventQueue.isEmpty else { return }

        let batch = eventQueue
        eventQueue.removeAll()

        do {
            try await supabase
                .from(SupabaseConfig.Tables.analyticsEvents)
                .insert(batch)
                .execute()
        } catch {
            // Hatalıysa geri ekle
            eventQueue.append(contentsOf: batch)
        }
    }
}
