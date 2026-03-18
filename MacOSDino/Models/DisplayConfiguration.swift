// DisplayConfiguration.swift
// MacOS-Dino – Ekran Yapılandırma Modeli

import Foundation
import CoreGraphics

struct DisplayConfiguration: Identifiable, Hashable {
    let displayID: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let visibleFrame: CGRect
    let scaleFactor: CGFloat
    let refreshRate: Double
    let isMain: Bool
    let isBuiltIn: Bool
    let isRetina: Bool
    let resolution: DisplayResolution

    var id: CGDirectDisplayID { displayID }

    var displayDescription: String {
        "\(name) – \(resolution.width)×\(resolution.height) @ \(Int(refreshRate))Hz"
    }

    var isProMotion: Bool {
        refreshRate > 60.0
    }
}

struct DisplayResolution: Hashable, Codable {
    let width: Int
    let height: Int

    var label: String {
        if width >= 7680 { return "8K" }
        if width >= 5120 { return "5K" }
        if width >= 3840 { return "4K Ultra HD" }
        if width >= 2560 { return "QHD" }
        if width >= 1920 { return "Full HD" }
        return "\(width)×\(height)"
    }
}

// MARK: - User Library Item

struct UserLibraryItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let wallpaperId: UUID
    var customTransform: String?
    var isFavorite: Bool?
    var addedAt: Date
    var wallpaper: Wallpaper?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wallpaperId = "wallpaper_id"
        case customTransform = "custom_transform"
        case isFavorite = "is_favorite"
        case addedAt = "added_at"
        case wallpaper = "dino_wallpapers"
    }
}
