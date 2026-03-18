// MenuBarView.swift
// MacOS-Dino – Menu Bar Ana Görünüm
// LSUIElement = true, sadece menu bar'da yaşar

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService

    var body: some View {
        VStack(spacing: 0) {
            // Üst: Şu anki wallpaper durumu
            currentWallpaperStatus

            Divider()

            // Hızlı aksiyonlar
            quickActions

            Divider()

            // Performans göstergesi
            performanceIndicator

            Divider()

            // Alt: Ayarlar ve çıkış
            bottomActions
        }
        .frame(width: 280)
        .padding(.vertical, 8)
    }

    // MARK: - Current Status

    private var currentWallpaperStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title3)
                    .foregroundStyle(.blue)

                Text("MacOS-Dino")
                    .font(.headline)

                Spacer()

                // Durum göstergesi
                Circle()
                    .fill(engine.isRunning ? .green : .red)
                    .frame(width: 8, height: 8)
            }

            if let wallpaper = engine.currentWallpaper {
                HStack(spacing: 8) {
                    // Thumbnail placeholder
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 32)
                        .overlay {
                            Image(systemName: wallpaper.contentType.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(wallpaper.category.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Aktif wallpaper yok")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(spacing: 2) {
            // Oynat/Duraklat
            Button {
                if engine.isPaused {
                    engine.resume()
                } else {
                    engine.pause()
                }
            } label: {
                Label(
                    engine.isPaused ? "Devam Et" : "Duraklat",
                    systemImage: engine.isPaused ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Galeri aç
            Button {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title.contains("Galeri") }) {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Label("Galeri Aç", systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Dosyadan ekle
            Button {
                Task {
                    if let wallpaper = try? await WallpaperManager.shared.importLocalVideo() {
                        await engine.setWallpaper(wallpaper)
                    }
                }
            } label: {
                Label("Video İçe Aktar...", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Wallpaper kaldır
            if engine.currentWallpaper != nil {
                Button(role: .destructive) {
                    engine.removeWallpaper()
                } label: {
                    Label("Wallpaper Kaldır", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Performance

    private var performanceIndicator: some View {
        HStack(spacing: 16) {
            Label(String(format: "%.1f%%", engine.cpuUsage), systemImage: "cpu")
                .font(.caption2)
            Label(String(format: "%.0f MB", engine.memoryUsage), systemImage: "memorychip")
                .font(.caption2)
            Label(String(format: "%.0f FPS", engine.fps), systemImage: "gauge.with.dots.needle.33percent")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Bottom

    private var bottomActions: some View {
        VStack(spacing: 2) {
            // Kullanıcı durumu
            if auth.isAuthenticated {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text(auth.userProfile?.displayName ?? "Kullanıcı")
                        .font(.caption)
                    Spacer()
                    Text(SubscriptionManager.shared.currentPlan.displayName)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            // Ayarlar
            SettingsLink {
                Label("Ayarlar...", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Çıkış
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("MacOS-Dino'dan Çık", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.vertical, 4)
    }
}
