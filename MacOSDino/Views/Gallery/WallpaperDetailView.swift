// WallpaperDetailView.swift
// MacOS-Dino – Right Sidebar Detail Panel (HTML pixel-perfect match)

import SwiftUI
import AVFoundation

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    @EnvironmentObject var engine: WallpaperEngine

    @State private var thumbnail: NSImage?
    @State private var isFavorite: Bool = false
    @State private var isSettingWallpaper = false
    @State private var lastSyncDate = Date()

    // HTML design tokens
    private let bg          = Color(red: 0.063, green: 0.086, blue: 0.133)  // #101622
    private let surface     = Color(red: 0.102, green: 0.133, blue: 0.204)  // #1a2234
    private let borderDark  = Color(red: 0.176, green: 0.227, blue: 0.329)  // #2d3a54
    private let primary     = Color(red: 0.051, green: 0.349, blue: 0.949)  // #0d59f2
    private let textSlate200 = Color(red: 0.89, green: 0.91, blue: 0.95)
    private let textSec     = Color(red: 0.59, green: 0.64, blue: 0.73)     // slate-400
    private let textDim     = Color(red: 0.40, green: 0.45, blue: 0.54)     // slate-500

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                displayConfigSection
                wallpaperDetailsSection
            }
        }
        .background(bg)
        .task(id: wallpaper.id) { await loadThumbnail() }
    }

    // MARK: - Display Configuration Section

    private var displayConfigSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("DISPLAY CONFIGURATION")
                .font(.system(size: 12, weight: .bold)) // text-xs font-bold
                .tracking(1.2) // tracking-wider
                .foregroundStyle(textDim) // text-slate-500
                .padding(.bottom, 16) // mb-4

            // Monitor preview container (aspect-video) bg-surface-dark/50 p-6 rounded-xl border border-border-dark mb-4
            HStack(spacing: 8) { // gap-2
                Spacer()

                // Monitor 1 (active with wallpaper)
                ZStack(alignment: .bottomTrailing) {
                    // thumbnail background
                    Group {
                        if let img = thumbnail {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.6)
                        } else {
                            Color(primary.opacity(0.1))
                        }
                    }
                    .frame(width: 96, height: 64) // w-24 h-16
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(primary, lineWidth: 2) // border-2 border-primary
                    )

                    // "1" badge: absolute text-[8px] font-bold text-white bg-primary px-1 bottom-0 right-0
                    Text("1")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4) // px-1
                        .padding(.vertical, 2)
                        .background(primary)
                        .cornerRadius(2)
                }

                // Monitor 2 (empty)
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderDark, lineWidth: 1))
                        Image(systemName: "display")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.28, green: 0.33, blue: 0.42)) // text-slate-600
                    }
                    .frame(width: 96, height: 64)

                    // "2" badge
                    Text("2")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(red: 0.28, green: 0.33, blue: 0.42)) // text-slate-600
                        .padding(.horizontal, 4) // px-1
                        .padding(.vertical, 2)
                        .background(surface)
                        .cornerRadius(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24) // p-6 roughly since it's an aspect-video box
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(surface.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderDark, lineWidth: 1))
            )
            .padding(.bottom, 16) // mb-4

            // Remove button
            Button {
                engine.removeWallpaper(for: nil)
            } label: {
                HStack(spacing: 8) { // gap-2
                    Image(systemName: "rectangle.slash")
                        .font(.system(size: 14)) // text-sm
                    Text("Remove Display Wallpaper")
                        .font(.system(size: 12, weight: .medium)) // text-xs font-medium
                }
                .foregroundStyle(textSec) // text-slate-400 hover:text-white handled via generic hover natively
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) // py-2
                .background(
                    RoundedRectangle(cornerRadius: 8) // rounded-lg
                        .stroke(borderDark, lineWidth: 1) // border border-border-dark
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(24) // p-6
    }

    // MARK: - Wallpaper Details Section

    private var wallpaperDetailsSection: some View {
        VStack(alignment: .leading, spacing: 24) { // space-y-6 pt-0
            // Divider h-px bg-border-dark w-full
            Rectangle().fill(borderDark).frame(height: 1).frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                // Name mb-1
                Text(wallpaper.name)
                    .font(.system(size: 20, weight: .bold)) // text-xl font-bold
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 4) // mb-1

                // Badges mb-4
                HStack(spacing: 8) { // gap-2
                    if wallpaper.isDownloaded {
                        Text("DOWNLOADED")
                            .font(.system(size: 10, weight: .bold)) // text-[10px] font-bold
                            .foregroundStyle(Color.green) // text-green-500
                            .padding(.horizontal, 8) // px-2
                            .padding(.vertical, 2) // py-0.5
                            .background(
                                RoundedRectangle(cornerRadius: 4) // rounded
                                    .fill(Color.green.opacity(0.1)) // bg-green-500/10
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.green.opacity(0.2), lineWidth: 1))
                            )
                    }
                    if wallpaper.isUltraHD || wallpaper.is8K {
                        Text(wallpaper.is8K ? "8K ULTRA HD" : "4K ULTRA HD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(textSec) // text-slate-400
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(surface))
                    }
                }
                .padding(.bottom, 24) // mb-6 slightly larger to match HTML space between badges and grid

                // 2×2 info grid (grid grid-cols-2 gap-4 text-sm mb-6)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    infoCell(label: "Dimensions", value: wallpaper.dimensionsFormatted)
                    infoCell(label: "File Size",  value: wallpaper.fileSizeFormatted)
                    infoCell(label: "Format",     value: wallpaper.contentType.displayName)
                    infoCell(label: "Category",   value: wallpaper.category.displayName)
                }
                .padding(.bottom, 24) // mb-6

                // Set as Wallpaper button mb-4
                Button {
                    setAsWallpaper()
                } label: {
                    HStack(spacing: 12) { // gap-3
                        if isSettingWallpaper {
                            ProgressView().progressViewStyle(.circular).scaleEffect(0.7).tint(.white)
                        } else {
                            Image(systemName: "desktopcomputer") // desktop_windows
                                .font(.system(size: 18))
                        }
                        Text(isSettingWallpaper ? "Setting…" : "Set as Wallpaper")
                            .font(.system(size: 16, weight: .bold)) // font-bold
                    }
                    .foregroundStyle(.white) // text-white
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16) // py-4
                    .background(
                        RoundedRectangle(cornerRadius: 12) // rounded-xl
                            .fill(primary) // bg-primary
                            .shadow(color: primary.opacity(0.2), radius: 12, y: 4) // shadow-lg shadow-primary/20
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSettingWallpaper)
                .padding(.bottom, 16) // mb-4

                // Add to Favorites checkbox row & report link (flex flex-col gap-3)
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { isFavorite.toggle() }
                    } label: {
                        HStack(spacing: 12) { // gap-3
                            // Checkbox
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isFavorite ? surface : surface) // bg-surface-dark
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(borderDark, lineWidth: 1))
                                    .frame(width: 16, height: 16)
                                if isFavorite {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(primary) // text-primary
                                }
                            }

                            HStack(spacing: 8) { // gap-2 inside
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 14)) // text-sm
                                    .foregroundStyle(primary) // text-primary fill-1

                                Text("Add to Favorites")
                                    .font(.system(size: 14, weight: .medium)) // text-sm font-medium
                                    .foregroundStyle(textSlate200) // text-slate-200
                            }

                            Spacer()
                        }
                        .padding(12) // p-3
                        .background(
                            RoundedRectangle(cornerRadius: 8) // rounded-lg
                                .stroke(borderDark, lineWidth: 1) // border border-border-dark
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Report link
                    Button {
                        // TODO: report
                    } label: {
                        HStack(spacing: 4) { // gap-1
                            Image(systemName: "exclamationmark.triangle") // report
                                .font(.system(size: 14)) // text-sm
                            Text("Report this wallpaper")
                                .font(.system(size: 12)) // text-xs
                        }
                        .foregroundStyle(textDim) // text-slate-500
                        .padding(.vertical, 4) // py-1
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Version / Help footer: mt-8 pt-8 border-t border-border-dark space-y-4 pb-8
            VStack(spacing: 16) { // space-y-4
                Rectangle().fill(borderDark).frame(height: 1).frame(maxWidth: .infinity)
                    .padding(.top, 8) // simulate mt-8 roughly with padding

                HStack { // justify-between
                    Text("VERSION 4.2.0-STABLE")
                        .font(.system(size: 10, weight: .bold)) // text-[10px] font-bold
                        .tracking(1.5) // tracking-widest
                        .foregroundStyle(textDim) // text-slate-500
                    Spacer()
                    Text("LAST SYNC: 2M AGO")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(textDim)
                }

                HStack(spacing: 16) { // gap-4
                    Button {
                        // Help Center
                    } label: {
                        HStack(spacing: 8) { // gap-2
                            Image(systemName: "questionmark.circle") // help
                                .font(.system(size: 16)) // text-base
                            Text("Help Center")
                                .font(.system(size: 12)) // text-xs
                        }
                        .foregroundStyle(textSec) // text-slate-400
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Feedback
                    } label: {
                        HStack(spacing: 8) { // gap-2
                            Image(systemName: "bubble.left") // chat_bubble
                                .font(.system(size: 16)) // text-base
                            Text("Feedback")
                                .font(.system(size: 12)) // text-xs
                        }
                        .foregroundStyle(textSec) // text-slate-400
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24) // p-6 but pt-0 is handled by ignoring top padding
    }

    // MARK: - Helper Views

    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12)) // text-xs
                .foregroundStyle(textDim) // text-slate-500
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14, weight: .medium)) // text-sm font-medium
                .foregroundStyle(textSlate200) // text-slate-200
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func setAsWallpaper() {
        guard !isSettingWallpaper else { return }
        isSettingWallpaper = true
        Task {
            await engine.setWallpaper(wallpaper)
            lastSyncDate = Date()
            isSettingWallpaper = false
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        if let localURL = wallpaper.localURL {
            if let img = await generateThumbnail(from: localURL) {
                thumbnail = img; return
            }
        }
        if let path = wallpaper.thumbnailPath, let url = URL(string: path) {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = NSImage(data: data) {
                thumbnail = img
            }
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
