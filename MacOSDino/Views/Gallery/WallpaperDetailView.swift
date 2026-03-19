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
    @State private var playbackRate: Float = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Display Configuration
                displayConfigSection

                Divider()

                // MARK: - Wallpaper Info
                wallpaperInfoSection

                Divider()

                // MARK: - Video Playback Controls (video ise)
                if wallpaper.contentType == .video {
                    playbackControlSection
                    Divider()
                }

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

    // MARK: - Playback Controls

    private var playbackControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VİDEO OYNATMA")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            // Hız slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Oynatma Hızı")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(playbackRateLabel)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }

                Slider(value: Binding(
                    get: { Double(playbackRate) },
                    set: { val in
                        playbackRate = Float(val)
                        engine.videoPlayers.values.forEach { $0.setPlaybackRate(playbackRate) }
                    }
                ), in: 0.1...1.0, step: 0.05)
                .tint(.blue)

                // Preset butonları
                HStack(spacing: 6) {
                    ForEach([(0.25, "¼×"), (0.5, "½×"), (0.75, "¾×"), (1.0, "1×")], id: \.0) { rate, lbl in
                        Button {
                            playbackRate = Float(rate)
                            engine.videoPlayers.values.forEach { $0.setPlaybackRate(Float(rate)) }
                        } label: {
                            Text(lbl)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(abs(playbackRate - Float(rate)) < 0.01 ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(abs(playbackRate - Float(rate)) < 0.01 ? Color.blue : Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Fade geçiş süresi
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Geçiş (Fade) Süresi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1fs", engine.videoPlayers.values.first?.fadeDuration ?? 1.5))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.purple)
                        .fontWeight(.semibold)
                }
                Slider(value: Binding(
                    get: { engine.videoPlayers.values.first?.fadeDuration ?? 1.5 },
                    set: { val in engine.videoPlayers.values.forEach { $0.fadeDuration = val } }
                ), in: 0.3...4.0, step: 0.1)
                .tint(.purple)
            }
        }
    }

    private var playbackRateLabel: String {
        switch playbackRate {
        case ..<0.3: return "Çok Yavaş"
        case ..<0.6: return "Yavaş"
        case ..<0.9: return "Orta"
        default: return "Normal"
        }
    }

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
