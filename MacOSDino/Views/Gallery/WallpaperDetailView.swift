// WallpaperDetailView.swift
// MacOS-Dino – Professional Detail Panel (Dark Theme)
// Display Configuration + Set as Wallpaper + Favorites + Info Grid

import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    @EnvironmentObject var engine: WallpaperEngine
    @State private var selectedDisplayID: CGDirectDisplayID?
    @State private var isFavorite = false
    @State private var isDownloading = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {

                // MARK: - Display Configuration
                displayConfigSection

                divider

                // MARK: - Wallpaper Info
                wallpaperInfoSection

                divider

                // MARK: - Info Grid
                infoGridSection

                divider

                // MARK: - Actions
                actionSection

                Spacer(minLength: 10)

                // MARK: - Footer
                footerSection
            }
            .padding(18)
        }
        .background(Color(red: 0.047, green: 0.067, blue: 0.106))
    }

    private var divider: some View {
        Rectangle().fill(DinoColors.border.opacity(0.3)).frame(height: 1)
    }

    // MARK: - Display Configuration

    private var displayConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("EKRAN YAPILANDIRMASI")

            // Monitor preview boxes
            if engine.activeDisplays.isEmpty {
                HStack(spacing: 8) {
                    monitorBox(number: 1, label: "Ana Ekran", isMain: true)
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(engine.activeDisplays.enumerated()), id: \.element.displayID) { index, display in
                        monitorBox(
                            number: index + 1,
                            label: display.name,
                            isMain: display.isMain,
                            displayID: display.displayID
                        )
                    }
                }
            }

            // Remove wallpaper button
            if engine.currentWallpaper?.id == wallpaper.id {
                Button {
                    engine.removeWallpaper(for: selectedDisplayID)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.rectangle").font(.system(size: 11))
                        Text("Ekran Wallpaper'ını Kaldır").font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(DinoColors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.danger.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(DinoColors.danger.opacity(0.3), lineWidth: 1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func monitorBox(number: Int, label: String, isMain: Bool, displayID: CGDirectDisplayID? = nil) -> some View {
        let isActive = (displayID != nil && selectedDisplayID == displayID) || (displayID == nil)
        return Button {
            if let id = displayID { selectedDisplayID = id }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? DinoColors.primary.opacity(0.2) : DinoColors.surface)
                    .frame(height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? DinoColors.primary : DinoColors.border.opacity(0.4), lineWidth: isActive ? 1.5 : 1)
                    )
                    .overlay(
                        Text("\(number)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(isActive ? DinoColors.primary : DinoColors.textDim)
                    )
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(DinoColors.textDim)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Wallpaper Info

    private var wallpaperInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(wallpaper.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            // Badges
            HStack(spacing: 6) {
                if wallpaper.isDownloaded {
                    Badge(text: "İNDİRİLDİ", color: DinoColors.success)
                }
                if wallpaper.isUltraHD {
                    Badge(text: "4K ULTRA HD", color: DinoColors.primary)
                }
                if wallpaper.is8K {
                    Badge(text: "8K", color: .purple)
                }
                Badge(text: wallpaper.contentType.displayName.uppercased(), color: DinoColors.surface)
            }
        }
    }

    // MARK: - Info Grid

    private var infoGridSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                infoCell(title: "Boyut", value: wallpaper.dimensionsFormatted)
                Rectangle().fill(DinoColors.border.opacity(0.3)).frame(width: 1)
                infoCell(title: "Dosya Boyutu", value: wallpaper.fileSizeFormatted)
            }
            Rectangle().fill(DinoColors.border.opacity(0.3)).frame(height: 1)
            HStack(spacing: 0) {
                infoCell(title: "Format", value: wallpaper.contentType.displayName)
                Rectangle().fill(DinoColors.border.opacity(0.3)).frame(width: 1)
                infoCell(title: "Kategori", value: wallpaper.category.displayName)
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(DinoColors.border.opacity(0.3), lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func infoCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(DinoColors.textDim)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 10) {
            // Set as Wallpaper – prominent blue button
            Button {
                Task { await engine.setWallpaper(wallpaper, for: selectedDisplayID) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "display").font(.system(size: 13))
                    Text("Wallpaper Olarak Ayarla").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(DinoColors.primary))
            }
            .buttonStyle(.plain)

            // Favorite toggle
            Button {
                isFavorite.toggle()
                Task {
                    guard let userId = AuthService.shared.currentUser?.id else { return }
                    _ = try? await WallpaperService.shared.toggleFavorite(userId: userId, wallpaperId: wallpaper.id)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(isFavorite ? .yellow : DinoColors.textSec)
                    Text(isFavorite ? "Favorilere Eklendi" : "Favorilere Ekle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DinoColors.textSec)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Download button (if not already downloaded)
            if !wallpaper.isDownloaded {
                Button {
                    isDownloading = true
                    Task {
                        try? await WallpaperManager.shared.downloadWallpaper(wallpaper)
                        isDownloading = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isDownloading {
                            ProgressView().controlSize(.small).tint(DinoColors.textSec)
                        } else {
                            Image(systemName: "arrow.down.circle").font(.system(size: 12))
                        }
                        Text(isDownloading ? "İndiriliyor..." : "İndir")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(DinoColors.textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.surface).overlay(RoundedRectangle(cornerRadius: 8).stroke(DinoColors.border.opacity(0.4), lineWidth: 1)))
                }
                .buttonStyle(.plain)
                .disabled(isDownloading)
            }

            // Report link
            HStack {
                Image(systemName: "exclamationmark.triangle").font(.system(size: 10))
                Text("Bu wallpaper'ı bildir").font(.system(size: 10))
            }
            .foregroundStyle(DinoColors.textDim)
            .padding(.top, 4)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 6) {
            Rectangle().fill(DinoColors.border.opacity(0.2)).frame(height: 1)
            HStack {
                Text("VERSION 1.0.0")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(DinoColors.textDim)
                Spacer()
                Text("Yardım").font(.system(size: 9)).foregroundStyle(DinoColors.textDim)
                Text("·").foregroundStyle(DinoColors.textDim)
                Text("Geri Bildirim").font(.system(size: 9)).foregroundStyle(DinoColors.textDim)
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(DinoColors.textDim)
    }
}

// MARK: - Helper Views

struct InfoCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption).fontWeight(.medium)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.medium)
        }
    }
}
