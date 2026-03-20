// WallpaperCard.swift
// MacOS-Dino – Gallery Card (HTML pixel-perfect match)

import SwiftUI
import AVFoundation

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    @State private var thumbnail: NSImage?
    @State private var isHovered = false

    // HTML colors
    private let borderDark   = Color(red: 0.176, green: 0.227, blue: 0.329)  // #2d3a54
    private let primary      = Color(red: 0.051, green: 0.349, blue: 0.949)  // #0d59f2
    private let textSlate300 = Color(red: 0.79, green: 0.83, blue: 0.90)     // slate-300

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
                        .font(.system(size: 10, weight: .bold)) // text-[10px] font-bold
                        .tracking(1.5) // tracking-widest
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8) // px-2
                        .padding(.vertical, 4) // py-1
                        .background(RoundedRectangle(cornerRadius: 4).fill(primary)) // rounded bg-primary
                        .padding(.top, 12) // top-3
                        .padding(.trailing, 12) // right-3
                }
            }
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit) // aspect-[16/10]
        .clipShape(RoundedRectangle(cornerRadius: 12)) // rounded-xl (12pt default)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? primary : (isHovered ? primary.opacity(0.5) : borderDark),
                        lineWidth: isSelected ? 2 : 1) // border-2 for selected, border for default
        )
        .shadow( // shadow-[0_0_20px_rgba(13,89,242,0.3)]
            color: isSelected ? primary.opacity(0.3) : .clear,
            radius: 10, x: 0, y: 0
        )
        .saturation(isSelected ? 1.0 : (isHovered ? 1.0 : 0.8)) // grayscale-[0.2] group-hover:grayscale-0
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onHover { isHovered = $0 }
        .task(id: wallpaper.id) { await loadThumbnail() }
        .cursor(.pointingHand) // cursor-pointer
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func thumbnailView(width: CGFloat, height: CGFloat) -> some View {
        if let img = thumbnail {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill) // object-cover
                .frame(width: width, height: height) // w-full h-full
                .clipped()
        } else {
            ZStack {
                Color(red: 0.102, green: 0.133, blue: 0.204)   // surface-dark placeholder
                Image(systemName: "photo.fill")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundStyle(Color(red: 0.176, green: 0.227, blue: 0.329))
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Gradient Overlay

    @ViewBuilder
    private var gradientOverlay: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                // Info label at bottom (flex flex-col justify-end p-4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(wallpaper.name)
                        .font(.system(size: 14, weight: .bold)) // text-sm font-bold
                        .foregroundStyle(.white) // text-white
                    Text(wallpaper.category.displayName)
                        .font(.system(size: 12)) // text-xs
                        .foregroundStyle(textSlate300) // text-slate-300
                }
                .padding(16) // p-4
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.height) // inset-0
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.8), // from-black/80
                        Color.black.opacity(0.4), // via-transparent ish
                        Color.clear // to-transparent
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            // opacity-100 on selected, opacity-0 group-hover:opacity-100 on non-selected
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
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 480, height: 300)
        gen.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
        gen.requestedTimeToleranceAfter  = CMTime(seconds: 1, preferredTimescale: 600)

        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        do {
            let cgImage = try await gen.image(at: time).image
            return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        } catch {
            print("Thumbnail generation failed: \(error.localizedDescription)")
            return nil
        }
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
