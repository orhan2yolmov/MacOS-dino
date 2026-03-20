// WallpaperCard.swift
// MacOS-Dino – Professional Wallpaper Card (Dark Theme)
// aspect-[16/10], gradient overlay, SELECTED badge, hover effects

import SwiftUI
import AVFoundation
import CoreMedia

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    @State private var isHovered = false
    @State private var thumbnailImage: NSImage?
    @State private var loadFailed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Thumbnail / Placeholder
            thumbnailLayer

            // Bottom gradient overlay
            LinearGradient(
                colors: [.clear, .clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // SELECTED badge (top-right)
            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Text("SEÇİLİ")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DinoColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                    }
                    Spacer()
                }
            }

            // Quality badge (top-left)
            VStack {
                HStack {
                    if wallpaper.isUltraHD {
                        Text("4K")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                    } else if wallpaper.is8K {
                        Text("8K")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                    }
                    Spacer()
                }
                Spacer()
            }

            // Info overlay (bottom, visible on hover or always for selected)
            if isHovered || isSelected {
                VStack(alignment: .leading, spacing: 3) {
                    Spacer()
                    Text(wallpaper.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(wallpaper.category.displayName)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
        .aspectRatio(16/10, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? DinoColors.primary : DinoColors.border.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: isSelected ? DinoColors.primary.opacity(0.3) : .clear, radius: isSelected ? 12 : 0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .task { await loadThumbnail() }
    }

    // MARK: - Thumbnail Layer

    @ViewBuilder
    private var thumbnailLayer: some View {
        if let image = thumbnailImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if loadFailed {
            // Fallback gradient
            cardGradient
                .overlay(
                    Image(systemName: wallpaper.contentType.icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white.opacity(0.3))
                )
        } else {
            // Loading placeholder
            cardGradient
                .overlay(ProgressView().controlSize(.small).tint(.white.opacity(0.4)))
        }
    }

    private var cardGradient: some View {
        LinearGradient(
            colors: [wallpaper.category.color.opacity(0.4), DinoColors.surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        // For local/bundled videos, generate thumbnail from video
        if let localURL = wallpaper.localURL {
            if let image = await generateVideoThumbnail(from: localURL) {
                thumbnailImage = image
                return
            }
        }

        // Try loading from Supabase thumbnail
        if let thumbnailPath = wallpaper.thumbnailPath {
            do {
                let url = try StorageService.shared.getThumbnailURL(path: thumbnailPath)
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = NSImage(data: data) {
                    thumbnailImage = image
                    return
                }
            } catch {
                // Fall through to failure
            }
        }

        // Try generating thumbnail from remote URL for video type
        if wallpaper.contentType == .video {
            if let image = await generateVideoThumbnail(from: wallpaper.remoteURL) {
                thumbnailImage = image
                return
            }
        }

        loadFailed = true
    }

    private func generateVideoThumbnail(from url: URL) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 400, height: 250)

            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                if let image {
                    continuation.resume(returning: NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height)))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Badge View

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
