// WallpaperDetailView.swift
// MacOS-Dino – Right Sidebar Detail Panel (HTML pixel-perfect match)

import SwiftUI
import AVFoundation
import CoreMedia

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
    private let textSec     = Color(red: 0.6,   green: 0.65,  blue: 0.76)
    private let textDim     = Color(red: 0.38,  green: 0.44,  blue: 0.56)

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
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(textDim)
                .padding(.bottom, 14)

            // Monitor preview container (aspect-video)
            HStack(spacing: 12) {
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
                    .frame(width: 96, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(primary, lineWidth: 2)
                    )

                    // "1" badge
                    Text("1")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(primary))
                        .offset(x: 6, y: 6)
                }

                // Monitor 2 (empty)
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(borderDark, lineWidth: 1))
                        Image(systemName: "display")
                            .font(.system(size: 22, weight: .ultraLight))
                            .foregroundStyle(textDim.opacity(0.5))
                    }
                    .frame(width: 96, height: 64)

                    Text("2")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(textDim)
                        .offset(x: 4, y: 4)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(surface.opacity(0.5))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderDark, lineWidth: 1))
            )
            .padding(.bottom, 12)

            // Remove button
            Button {
                engine.removeWallpaper(for: nil)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.slash")
                        .font(.system(size: 11))
                    Text("Remove Display Wallpaper")
                        .font(.system(size: 11))
                }
                .foregroundStyle(textSec)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderDark, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .overlay(
            Rectangle().fill(borderDark).frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Wallpaper Details Section

    private var wallpaperDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Divider
            Rectangle().fill(borderDark).frame(height: 1).frame(maxWidth: .infinity)

            // Name + badges
            VStack(alignment: .leading, spacing: 8) {
                Text(wallpaper.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if wallpaper.isDownloaded {
                        badgeView(text: "DOWNLOADED", bg: Color.green.opacity(0.1),
                                  border: Color.green.opacity(0.2), fg: .green)
                    }
                    if wallpaper.isUltraHD || wallpaper.is8K {
                        badgeView(text: wallpaper.is8K ? "8K" : "4K ULTRA HD",
                                  bg: surface, border: .clear, fg: textSec)
                    }
                }
            }

            // 2×2 info grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                infoCell(label: "Dimensions", value: wallpaper.dimensionsFormatted)
                infoCell(label: "File Size",  value: wallpaper.fileSizeFormatted)
                infoCell(label: "Format",     value: wallpaper.contentType.displayName)
                infoCell(label: "Category",   value: wallpaper.category.displayName)
            }

            // Set as Wallpaper button
            Button {
                setAsWallpaper()
            } label: {
                HStack(spacing: 10) {
                    if isSettingWallpaper {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.7).tint(.white)
                    } else {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 16))
                    }
                    Text(isSettingWallpaper ? "Setting…" : "Set as Wallpaper")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primary)
                        .shadow(color: primary.opacity(0.3), radius: 12, y: 4)
                )
            }
            .buttonStyle(.plain)
            .disabled(isSettingWallpaper)

            // Add to Favorites checkbox row
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isFavorite.toggle() }
            } label: {
                HStack(spacing: 12) {
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isFavorite ? primary : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(isFavorite ? primary : borderDark, lineWidth: 1.5))
                            .frame(width: 18, height: 18)
                        if isFavorite {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(isFavorite ? primary : textSec)

                    Text("Add to Favorites")
                        .font(.system(size: 13))
                        .foregroundStyle(isFavorite ? .white : textSec)

                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderDark, lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.clear))
                )
            }
            .buttonStyle(.plain)

            // Report link
            Button {
                // TODO: report
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 10))
                    Text("Report this wallpaper")
                        .font(.system(size: 11))
                }
                .foregroundStyle(textDim)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            // Version / Help footer
            VStack(spacing: 10) {
                Rectangle().fill(borderDark).frame(height: 1).frame(maxWidth: .infinity)

                HStack {
                    Text("VERSION 4.2.0-STABLE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(textDim)
                    Spacer()
                    Text("LAST SYNC: 2M AGO")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(textDim)
                }

                HStack(spacing: 20) {
                    Button {
                        // Help Center
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 11))
                            Text("Help Center")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(textDim)
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Feedback
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope")
                                .font(.system(size: 11))
                            Text("Feedback")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(textDim)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .padding(.top, 0)
    }

    // MARK: - Helper Views

    private func badgeView(text: String, bg: Color, border: Color, fg: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bg)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: 1))
            )
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(textDim)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.87, green: 0.89, blue: 0.95))
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
        return await Task.detached(priority: .background) {
            let asset = AVURLAsset(url: url)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 320, height: 200)
            gen.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
            gen.requestedTimeToleranceAfter  = CMTime(seconds: 1, preferredTimescale: 600)
            let time = CMTime(seconds: 1, preferredTimescale: 600)
            if let cg = try? gen.copyCGImage(at: time, actualTime: nil) {
                return NSImage(cgImage: cg, size: CGSize(width: cg.width, height: cg.height))
            }
            return nil
        }.value
    }
}
