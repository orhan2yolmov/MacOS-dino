// MenuBarView.swift
// MacOS-Dino – Menu Bar Ana Görünüm (Modern Redesign)

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @State private var showingAuth = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Başlık
            headerSection

            Divider().opacity(0.15)

            // ── Aktif wallpaper durumu
            wallpaperStatusSection

            Divider().opacity(0.15)

            // ── Hızlı aksiyonlar
            quickActionsSection

            Divider().opacity(0.15)

            // ── Performans mini bar
            performanceSection

            Divider().opacity(0.15)

            // ── Alt aksiyonlar
            footerSection
        }
        .frame(width: 300)
        .background(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.97))
        .sheet(isPresented: $showingAuth) {
            LoginView()
                .environmentObject(auth)
        }
    }

    // MARK: – Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("MacOS-Dino")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            // Durum pill
            HStack(spacing: 5) {
                Circle()
                    .fill(engine.isRunning ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                    .shadow(color: engine.isRunning ? .green.opacity(0.6) : .red.opacity(0.4), radius: 3)
                Text(engine.isRunning ? (engine.isPaused ? "Durduruldu" : "Aktif") : "Kapalı")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.07))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: – Wallpaper Status

    private var wallpaperStatusSection: some View {
        Group {
            if let wallpaper = engine.currentWallpaper {
                HStack(spacing: 10) {
                    // Thumbnail placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(wallpaper.category.color.opacity(0.2))
                            .frame(width: 52, height: 34)
                        Image(systemName: wallpaper.contentType.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(wallpaper.category.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(wallpaper.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(wallpaper.category.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                            if wallpaper.isUltraHD {
                                Text("4K")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Spacer()

                    // Pause/Play toggle
                    Button {
                        engine.isPaused ? engine.resume() : engine.pause()
                    } label: {
                        Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("Aktif wallpaper yok")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: – Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 1) {
            MenuActionRow(icon: "square.grid.2x2", label: "Galeri Aç", color: .blue) {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first { $0.title.contains("Galeri") }?.makeKeyAndOrderFront(nil)
            }

            MenuActionRow(icon: "square.and.arrow.down", label: "Video İçe Aktar...", color: .cyan) {
                Task {
                    if let wallpaper = try? await WallpaperManager.shared.importLocalVideo() {
                        await engine.setWallpaper(wallpaper)
                    }
                }
            }

            if engine.currentWallpaper != nil {
                MenuActionRow(icon: "xmark.circle", label: "Wallpaper Kaldır", color: .red) {
                    engine.removeWallpaper()
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: – Performance

    private var performanceSection: some View {
        HStack(spacing: 0) {
            MiniStat(icon: "cpu", value: String(format: "%.1f%%", engine.cpuUsage), label: "CPU")
            Spacer()
            MiniStat(icon: "memorychip", value: String(format: "%.0fMB", engine.memoryUsage), label: "RAM")
            Spacer()
            MiniStat(icon: "gauge.with.dots.needle.33percent", value: String(format: "%.0f", engine.fps), label: "FPS")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: – Footer

    private var footerSection: some View {
        VStack(spacing: 1) {
            // Kullanıcı
            if auth.isAuthenticated {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 26, height: 26)
                        Text(auth.userProfile?.initials ?? "U")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(auth.userProfile?.displayName ?? "Kullanıcı")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(SubscriptionManager.shared.currentPlan.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider().opacity(0.15)
            } else {
                Button {
                    showingAuth = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(.blue)
                        Text("Giriş Yap / Kayıt Ol")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().opacity(0.15)
            }

            SettingsLink {
                MenuActionRow(icon: "gear", label: "Ayarlar...", color: .gray) {}
            }
            .buttonStyle(.plain)

            MenuActionRow(icon: "power", label: "MacOS-Dino'dan Çık", color: .red.opacity(0.8)) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views

private struct MenuActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isHovered ? .white.opacity(0.06) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private struct MiniStat: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}
