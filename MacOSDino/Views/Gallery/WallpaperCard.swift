// WallpaperCard.swift
// MacOS-Dino – Wallpaper Kart Bileşeni (Modern Redesign)

import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?
    @State private var isImageLoaded = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Thumbnail alanı
            GeometryReader { geo in
                ZStack {
                    // Arka plan gradient placeholder
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    wallpaper.category.color.opacity(0.25),
                                    Color(red: 0.08, green: 0.09, blue: 0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if let image = thumbnailImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .opacity(isImageLoaded ? 1 : 0)
                            .animation(.easeIn(duration: 0.4), value: isImageLoaded)
                    } else {
                        // Placeholder icon
                        VStack(spacing: 8) {
                            Image(systemName: wallpaper.contentType.icon)
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(wallpaper.category.color.opacity(0.6))

                            Text(wallpaper.category.displayName)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }

                    // Hover dark overlay + play icon
                    if isHovered {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.black.opacity(0.35))
                            .transition(.opacity)

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 8)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Seçili outline + parıltı
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    }
                }
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: isSelected ? .blue.opacity(0.35) : .black.opacity(0.3),
                radius: isSelected ? 12 : 6,
                y: 4
            )

            // Alt info katmanı
            HStack(alignment: .bottom) {
                // Tipler badge
                VStack(alignment: .leading, spacing: 3) {
                    if wallpaper.is8K {
                        SmallBadge(text: "8K", gradient: [.orange, .red])
                    } else if wallpaper.isUltraHD {
                        SmallBadge(text: "4K", gradient: [.blue, .cyan])
                    }
                    if wallpaper.contentType == .metalShader {
                        SmallBadge(text: "SHADER", gradient: [.purple, .pink])
                    }
                }

                Spacer()

                // Seçili checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 20, height: 20)
                        )
                }
            }
            .padding(10)
        }
        // İsim alt kısım
        .overlay(alignment: .bottomLeading) {
            if isHovered || isSelected {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 14,
                            topTrailingRadius: 0
                        )
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text(wallpaper.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    }
                }
                .transition(.opacity)
            }
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(duration: 0.25, bounce: 0.2), value: isHovered)
        .animation(.spring(duration: 0.25, bounce: 0.2), value: isSelected)
        .onHover { hovering in
            withAnimation { isHovered = hovering }
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let path = wallpaper.thumbnailPath else { return }
        do {
            let data = try await StorageService.shared.downloadThumbnail(remotePath: path)
            if let img = NSImage(data: data) {
                thumbnailImage = img
                withAnimation { isImageLoaded = true }
            }
        } catch {
            // Placeholder kalır
        }
    }
}

// MARK: - Small Gradient Badge

struct SmallBadge: View {
    let text: String
    let gradient: [Color]

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.85)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Badge (mevcut, uyumluluk için)

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
