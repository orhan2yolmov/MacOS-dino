// WallpaperDetailView.swift
// MacOS-Dino – Wallpaper Detay Paneli (Sağ sidebar)
// Referans: Display configuration + Set as Wallpaper + Favorites

import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    @EnvironmentObject var engine: WallpaperEngine
    @State private var selectedDisplayID: CGDirectDisplayID?
    @State private var isFavorite = false
    @State private var isDownloading = false
    @State private var showReport = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Display Configuration
                displayConfigSection

                Divider()

                // MARK: - Wallpaper Info
                wallpaperInfoSection

                Divider()

                // MARK: - Actions
                actionButtons

                Divider()

                // MARK: - Technical Details
                technicalDetails

                Spacer()

                // MARK: - Footer
                footerInfo
            }
            .padding()
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Display Config

    private var displayConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EKRAN YAPILANDIRMASI")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            // Monitör önizlemesi
            DisplayPreview(
                displays: engine.activeDisplays,
                selectedDisplayID: $selectedDisplayID
            )
            .frame(height: 100)

            // Wallpaper kaldır butonu
            if engine.currentWallpaper?.id == wallpaper.id {
                Button {
                    engine.removeWallpaper(for: selectedDisplayID)
                } label: {
                    Label("Ekran Wallpaper'ını Kaldır", systemImage: "xmark.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Wallpaper Info

    private var wallpaperInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // İsim
            Text(wallpaper.name)
                .font(.title2)
                .fontWeight(.bold)

            // Badges
            HStack(spacing: 6) {
                if wallpaper.isDownloaded {
                    Badge(text: "İNDİRİLDİ", color: .green)
                }
                if wallpaper.isUltraHD {
                    Badge(text: "4K ULTRA HD", color: .blue)
                }
                Badge(text: wallpaper.contentType.displayName.uppercased(), color: .gray)
            }

            // Teknik bilgiler grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                InfoCell(title: "Boyut", value: wallpaper.dimensionsFormatted)
                InfoCell(title: "Dosya Boyutu", value: wallpaper.fileSizeFormatted)
                InfoCell(title: "Format", value: wallpaper.contentType.displayName)
                InfoCell(title: "Kategori", value: wallpaper.category.displayName)
            }
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Set as Wallpaper butonu
            Button {
                Task {
                    await engine.setWallpaper(wallpaper, for: selectedDisplayID)
                }
            } label: {
                HStack {
                    Image(systemName: "display")
                    Text("Wallpaper Olarak Ayarla")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            // Favori toggle
            Button {
                isFavorite.toggle()
                Task {
                    guard let userId = AuthService.shared.currentUser?.id else { return }
                    _ = try? await WallpaperService.shared.toggleFavorite(
                        userId: userId,
                        wallpaperId: wallpaper.id
                    )
                }
            } label: {
                HStack {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .primary)
                    Text(isFavorite ? "Favorilere Eklendi" : "Favorilere Ekle")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            // İndir butonu
            if !wallpaper.isDownloaded {
                Button {
                    isDownloading = true
                    Task {
                        try? await WallpaperManager.shared.downloadWallpaper(wallpaper)
                        isDownloading = false
                    }
                } label: {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                        Text(isDownloading ? "İndiriliyor..." : "İndir")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isDownloading)
            }

            // Report butonu
            Button {
                showReport = true
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Bildir")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Technical Details

    private var technicalDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Teknik Detaylar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            if let ratio = wallpaper.aspectRatio.displayName as String? {
                DetailRow(label: "En-Boy Oranı", value: ratio)
            }
            if wallpaper.contentType == .video {
                if let start = wallpaper.loopStartTime {
                    DetailRow(label: "Loop Başlangıcı", value: "\(start)s")
                }
                if let end = wallpaper.loopEndTime {
                    DetailRow(label: "Loop Bitişi", value: "\(end)s")
                }
            }
            if let shader = wallpaper.shaderName {
                DetailRow(label: "Shader", value: shader)
            }
        }
    }

    // MARK: - Footer

    private var footerInfo: some View {
        HStack {
            Text("VERSION 1.0.0")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Yardım") {}
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button("Geri Bildirim") {}
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Helper Views

struct InfoCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
