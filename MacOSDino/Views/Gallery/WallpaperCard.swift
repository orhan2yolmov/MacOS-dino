// WallpaperCard.swift
// MacOS-Dino – Wallpaper Kart Bileşeni
// Gallery grid'inde gösterilen wallpaper kartı

import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                // Arka plan
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .aspectRatio(16/9, contentMode: .fit)

                // Thumbnail görseli
                if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Placeholder
                    Image(systemName: wallpaper.contentType.icon)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                // Hover overlay
                if isHovered {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black.opacity(0.3))
                        .overlay {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                }

                // Badges
                VStack {
                    HStack {
                        Spacer()

                        // Content type badge
                        if wallpaper.contentType == .metalShader {
                            Badge(text: "SHADER", color: .purple)
                        }

                        // 4K/8K badge
                        if wallpaper.is8K {
                            Badge(text: "8K", color: .orange)
                        } else if wallpaper.isUltraHD {
                            Badge(text: "4K ULTRA HD", color: .blue)
                        }
                    }

                    Spacer()

                    HStack {
                        // İndirilmiş göstergesi
                        if wallpaper.isDownloaded {
                            Badge(text: "İNDİRİLDİ", color: .green)
                        }

                        Spacer()

                        // Süre göstergesi (video ise)
                        if wallpaper.contentType == .video {
                            HStack(spacing: 2) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 8))
                            }
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(8)

                // Selected indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 3)

                    // "SELECTED" badge
                    VStack {
                        HStack {
                            Badge(text: "SEÇİLDİ", color: .blue)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.2), radius: isSelected ? 8 : 4)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(duration: 0.2), value: isHovered)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let path = wallpaper.thumbnailPath else { return }

        do {
            let data = try await StorageService.shared.downloadThumbnail(remotePath: path)
            thumbnailImage = NSImage(data: data)
        } catch {
            // Thumbnail yüklenemedi – placeholder kalır
        }
    }
}

// MARK: - Badge Component

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
