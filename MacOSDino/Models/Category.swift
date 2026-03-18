// Category.swift
// MacOS-Dino – Wallpaper Kategorileri ve En-Boy Oranları

import Foundation
import SwiftUI

// MARK: - Wallpaper Category

enum WallpaperCategory: String, Codable, CaseIterable, Identifiable {
    case cartoon = "cartoon"
    case game = "game"
    case animation = "animation"
    case nature = "nature"
    case cutePet = "cute_pet"
    case movieStar = "movie_star"
    case personal = "personal"
    case visualMusic = "visual_music"
    case deepSpace = "deep_space"
    case abstract = "abstract"
    case minimal = "minimal"
    case cityscape = "cityscape"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cartoon: return "Karikatür"
        case .game: return "Oyun"
        case .animation: return "Animasyon"
        case .nature: return "Doğa"
        case .cutePet: return "Sevimli Hayvanlar"
        case .movieStar: return "Film & Dizi"
        case .personal: return "Kişisel"
        case .visualMusic: return "Görsel Müzik"
        case .deepSpace: return "Uzay"
        case .abstract: return "Soyut"
        case .minimal: return "Minimal"
        case .cityscape: return "Şehir Manzarası"
        }
    }

    var icon: String {
        switch self {
        case .cartoon: return "theatermask.and.paintbrush"
        case .game: return "gamecontroller.fill"
        case .animation: return "play.circle.fill"
        case .nature: return "leaf.fill"
        case .cutePet: return "pawprint.fill"
        case .movieStar: return "film.fill"
        case .personal: return "person.fill"
        case .visualMusic: return "music.note"
        case .deepSpace: return "sparkles"
        case .abstract: return "paintpalette.fill"
        case .minimal: return "circle.hexagongrid"
        case .cityscape: return "building.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .cartoon: return .orange
        case .game: return .green
        case .animation: return .pink
        case .nature: return .mint
        case .cutePet: return .yellow
        case .movieStar: return .red
        case .personal: return .blue
        case .visualMusic: return .purple
        case .deepSpace: return .indigo
        case .abstract: return .cyan
        case .minimal: return .gray
        case .cityscape: return .teal
        }
    }
}

// MARK: - Aspect Ratio

enum AspectRatio: String, Codable, CaseIterable, Identifiable {
    case standard = "4:3"
    case widescreen = "16:9"
    case ultrawide = "21:9"
    case superUltrawide = "32:9"
    case portrait = "9:16"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "4:3 (Standart)"
        case .widescreen: return "16:9 (Geniş Ekran)"
        case .ultrawide: return "21:9 (Ultra Geniş)"
        case .superUltrawide: return "32:9 (Süper Ultra Geniş)"
        case .portrait: return "9:16 (Dikey)"
        }
    }

    var widthRatio: CGFloat {
        switch self {
        case .standard: return 4
        case .widescreen: return 16
        case .ultrawide: return 21
        case .superUltrawide: return 32
        case .portrait: return 9
        }
    }

    var heightRatio: CGFloat {
        switch self {
        case .standard: return 3
        case .widescreen: return 9
        case .ultrawide: return 9
        case .superUltrawide: return 9
        case .portrait: return 16
        }
    }
}
