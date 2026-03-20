// WallpaperCard.swift
// MacOS-Dino – Gallery Card (HTML pixel-perfect match)

import SwiftUI
import AVFoundation
import CoreMedia

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    // HTML colors
    private let borderDark   = Color(red: 0.176, green: 0.227, blue: 0.329)  // #2d3a54
    private let primary      = Color(red: 0.051, green: 0.349, blue: 0.949)  // #0d59f2

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Thumbnail image
                thumbnailView(width: geo.size.width, height: geo.size.height)

                // Gradient overlay
                gradientOverlay

                // SELECTED badge (top-right, always when selected)
                if isSelected {
                    Text("SELECTED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(primary))
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                }
            }
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? primary : (isHovered ? primary.opacity(0.5) : borderDark),
                        lineWidth: isSelected ? 2 : 1)
        )
        .shadow(
            color: isSelected ? primary.opacity(0.3) : .clear,
            radius: 10
        )
        .saturation(isSelected ? 1.0 : (isHovered ? 1.0 : 0.8))
        .scaleEffect(isHovered ? 1.025 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { isHovered = $0 }
        .task(id: wallpaper.id) { await loadThumbnail() }
        .cursor(.pointingHand)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func thumbnailView(width: CGFloat, height: CGFloat) -> some View {
        if let img = thumbnail {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: isHovered)
        } else {
            ZStack {
                Color(red: 0.102, green: 0.133, blue: 0.204)   // surface-dark placeholder
                Image(systemName: "photo.fill")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundStyle(Color(red: 0.176, green: 0.227, blue: 0.329))
            }
        }
    }

    // MARK: - Gradient Overlay

    @ViewBuilder
    private var gradientOverlay: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                // Info label at bottom
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text(wallpaper.category.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.78, green: 0.82, blue: 0.91))
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(isSelected ? 0.8 : 0.6),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .center
                )
            )
            .opacity(isSelected ? 1.0 : (isHovered ? 1.0 : 0.0))
            .animation(.easeInOut(duration: 0.25), value: isHovered)
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        // 1. Local file → AVAssetImageGenerator
        if let localURL = wallpaper.localURL {
            if let img = await generateThumbnail(from: localURL) {
                thumbnail = img
                return
            }
        }

        // 2. Remote thumbnail URL
        if let path = wallpaper.thumbnailPath,
           let url = URL(string: path) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let img = NSImage(data: data) { thumbnail = img }
            } catch {}
        }
    }

    private func generateThumbnail(from url: URL) async -> NSImage? {
        return await Task.detached(priority: .background) {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 480, height: 300)
            gen.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
            gen.requestedTimeToleranceAfter  = CMTime(seconds: 1, preferredTimescale: 600)

            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            if let cgImage = try? gen.copyCGImage(at: time, actualTime: nil) {
                return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
            }
            return nil
        }.value
    }
}

// MARK: - NSCursor helper

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
