// Wallpaper.swift
// MacOS-Dino – Wallpaper Veri Modeli
// Supabase 'wallpapers' tablosuna map'lenir

import Foundation

struct Wallpaper: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: WallpaperCategory
    var contentType: WallpaperContentType
    var remoteURL: URL
    var localURL: URL?
    var thumbnailPath: String?
    var storagePath: String?     // Supabase Storage path
    var shaderName: String?
    var shaderParameters: [String: Double]?
    var loopStartTime: Double?
    var loopEndTime: Double?
    var aspectRatio: AspectRatio
    var dimensions: WallpaperDimensions?
    var fileSize: Int64?         // bytes
    var isDownloaded: Bool
    var isFeatured: Bool
    var popularityScore: Int
    var createdAt: Date

    // MARK: - Computed

    var fileSizeFormatted: String {
        guard let size = fileSize else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var dimensionsFormatted: String {
        guard let d = dimensions else { return "—" }
        return "\(d.width) × \(d.height)"
    }

    var isUltraHD: Bool {
        guard let d = dimensions else { return false }
        return d.width >= 3840
    }

    var is8K: Bool {
        guard let d = dimensions else { return false }
        return d.width >= 7680
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case contentType = "content_type"
        case remoteURL = "remote_url"
        case localURL = "local_url"
        case thumbnailPath = "thumbnail_path"
        case storagePath = "storage_path"
        case shaderName = "shader_name"
        case shaderParameters = "shader_parameters"
        case loopStartTime = "loop_start_time"
        case loopEndTime = "loop_end_time"
        case aspectRatio = "aspect_ratio"
        case dimensions
        case fileSize = "file_size"
        case isDownloaded = "is_downloaded"
        case isFeatured = "is_featured"
        case popularityScore = "popularity_score"
        case createdAt = "created_at"
    }
}

// MARK: - Wallpaper Content Type

enum WallpaperContentType: String, Codable, CaseIterable {
    case video = "video"
    case metalShader = "metal_shader"
    case htmlWidget = "html_widget"
    case staticImage = "static_image"

    var displayName: String {
        switch self {
        case .video: return "Video"
        case .metalShader: return "Metal Shader"
        case .htmlWidget: return "HTML Widget"
        case .staticImage: return "Statik Görsel"
        }
    }

    var icon: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .metalShader: return "wand.and.stars"
        case .htmlWidget: return "globe"
        case .staticImage: return "photo.fill"
        }
    }
}

// MARK: - Wallpaper Dimensions

struct WallpaperDimensions: Codable, Hashable {
    let width: Int
    let height: Int
}
