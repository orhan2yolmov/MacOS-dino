// SettingsView.swift
// MacOS-Dino – Professional Dark Theme Settings

import SwiftUI
import ServiceManagement

// MARK: - Color Theme

private enum DinoTheme {
    static let bg        = Color(red: 0.063, green: 0.086, blue: 0.133)   // #101622
    static let surface   = Color(red: 0.102, green: 0.133, blue: 0.204)   // #1a2234
    static let border    = Color(red: 0.176, green: 0.227, blue: 0.329)   // #2d3a54
    static let primary   = Color(red: 0.051, green: 0.349, blue: 0.949)   // #0d59f2
    static let textPri   = Color.white
    static let textSec   = Color.white.opacity(0.5)
    static let textDim   = Color.white.opacity(0.3)
    static let danger    = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let success   = Color(red: 0.2, green: 0.85, blue: 0.5)
}

// MARK: - Main Settings View

struct SettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    @State private var selectedTab: SettingsTab = .playback

    enum SettingsTab: String, CaseIterable {
        case playback = "Oynatma"
        case display = "Görüntü"
        case performance = "Performans"
        case account = "Hesap"
        case about = "Hakkında"

        var icon: String {
            switch self {
            case .playback: return "play.circle"
            case .display: return "display"
            case .performance: return "gauge.with.dots.needle.67percent"
            case .account: return "person.circle"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // ── Sidebar
            sidebar

            // ── Divider
            Rectangle()
                .fill(DinoTheme.border.opacity(0.5))
                .frame(width: 1)

            // ── Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .playback:   PlaybackSettingsPanel(engine: engine)
                    case .display:    DisplaySettingsPanel(engine: engine)
                    case .performance: PerformanceSettingsPanel(engine: engine)
                    case .account:    AccountSettingsPanel(auth: auth, subscription: subscription)
                    case .about:      AboutPanel()
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 680, height: 520)
        .background(DinoTheme.bg)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Logo
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [DinoTheme.primary, Color(red: 0.4, green: 0.2, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ayarlar")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DinoTheme.textPri)
                    Text("MacOS-Dino")
                        .font(.system(size: 10))
                        .foregroundStyle(DinoTheme.textDim)
                }
            }
            .padding(.bottom, 16)

            // Tab buttons
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SidebarTabButton(
                    icon: tab.icon,
                    label: tab.rawValue,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }

            Spacer()

            // Version
            Text("v1.0.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(DinoTheme.textDim)
        }
        .padding(16)
        .frame(width: 180)
        .background(DinoTheme.surface.opacity(0.5))
    }
}

// MARK: - Sidebar Tab Button

private struct SidebarTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? DinoTheme.primary : DinoTheme.textSec)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? DinoTheme.textPri : DinoTheme.textSec)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? DinoTheme.primary.opacity(0.15) : (isHovered ? DinoTheme.border.opacity(0.3) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? DinoTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Section Container

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DinoTheme.primary)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DinoTheme.textPri)
            }
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DinoTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DinoTheme.border.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Setting Row

private struct SettingRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let trailing: Trailing

    init(title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DinoTheme.textPri)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(DinoTheme.textDim)
                }
            }
            Spacer()
            trailing
        }
    }
}

// MARK: - ═══════════════ TAB PANELS ═══════════════

// MARK: - Playback Settings

private struct PlaybackSettingsPanel: View {
    @ObservedObject var engine: WallpaperEngine

    private let speedPresets: [(String, Float)] = [
        ("¼×", 0.25), ("⅓×", 0.33), ("½×", 0.5), ("¾×", 0.75), ("1×", 1.0)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Oynatma Ayarları")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoTheme.textPri)

            // ── Speed Control
            SettingsSection(title: "Oynatma Hızı", icon: "gauge.with.dots.needle.33percent") {
                VStack(spacing: 14) {
                    // Hız slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Hız")
                                .font(.system(size: 11))
                                .foregroundStyle(DinoTheme.textSec)
                            Spacer()
                            Text(String(format: "%.0f%%", engine.playbackSpeed * 100))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(DinoTheme.primary)
                        }
                        Slider(value: Binding(
                            get: { Double(engine.playbackSpeed) },
                            set: { engine.playbackSpeed = Float($0) }
                        ), in: 0.1...1.0, step: 0.05)
                        .tint(DinoTheme.primary)
                    }

                    // Preset buttons
                    HStack(spacing: 8) {
                        ForEach(speedPresets, id: \.1) { name, value in
                            Button {
                                engine.playbackSpeed = value
                            } label: {
                                Text(name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(
                                        abs(engine.playbackSpeed - value) < 0.02
                                        ? .white : DinoTheme.textSec
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                abs(engine.playbackSpeed - value) < 0.02
                                                ? DinoTheme.primary : DinoTheme.border.opacity(0.4)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Açıklama
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(DinoTheme.textDim)
                        Text("Düşük hız sinematik slow-motion efekti verir. macOS Aerial tarzı görünüm için ¼× - ⅓× önerilir.")
                            .font(.system(size: 10))
                            .foregroundStyle(DinoTheme.textDim)
                    }
                }
            }

            // ── Crossfade
            SettingsSection(title: "Geçiş Efekti", icon: "arrow.triangle.2.circlepath") {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Crossfade Süresi")
                                .font(.system(size: 11))
                                .foregroundStyle(DinoTheme.textSec)
                            Spacer()
                            Text(String(format: "%.1f sn", engine.crossfadeDuration))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(DinoTheme.primary)
                        }
                        Slider(value: $engine.crossfadeDuration, in: 0.5...5.0, step: 0.5)
                            .tint(DinoTheme.primary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(DinoTheme.textDim)
                        Text("Video döngüsü sırasında iki kare arasındaki yumuşak geçiş süresi.")
                            .font(.system(size: 10))
                            .foregroundStyle(DinoTheme.textDim)
                    }
                }
            }

            // ── Audio
            SettingsSection(title: "Ses", icon: "speaker.wave.2") {
                SettingRow(title: "Sesli Tepki Modu", subtitle: "Wallpaper müziğe tepki verir") {
                    DinoToggle(isOn: $engine.enableAudioReactive)
                }
            }
        }
    }
}

// MARK: - Display Settings

private struct DisplaySettingsPanel: View {
    @ObservedObject var engine: WallpaperEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Görüntü Ayarları")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoTheme.textPri)

            // ── Monitörler
            SettingsSection(title: "Aktif Monitörler", icon: "display.2") {
                VStack(spacing: 10) {
                    if engine.activeDisplays.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Monitör bulunamadı")
                                .font(.system(size: 12))
                                .foregroundStyle(DinoTheme.textSec)
                        }
                    } else {
                        ForEach(engine.activeDisplays, id: \.displayID) { display in
                            HStack(spacing: 12) {
                                Image(systemName: display.isMain ? "display" : "rectangle.on.rectangle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(display.isMain ? DinoTheme.primary : DinoTheme.textSec)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(display.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(DinoTheme.textPri)
                                    Text("\(Int(display.frame.width))×\(Int(display.frame.height)) • \(display.scaleFactor > 1 ? "Retina" : "Standard")")
                                        .font(.system(size: 10))
                                        .foregroundStyle(DinoTheme.textDim)
                                }

                                Spacer()

                                if display.isMain {
                                    Text("ANA")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(DinoTheme.primary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(DinoTheme.primary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DinoTheme.bg)
                            )
                        }
                    }
                }
            }

            // ── Mouse
            SettingsSection(title: "Etkileşim", icon: "cursorarrow.motionlines") {
                SettingRow(title: "Mouse Etkileşimi", subtitle: "Cursor wallpaper ile etkileşir") {
                    DinoToggle(isOn: $engine.enableMouseInteraction)
                }
            }
        }
    }
}

// MARK: - Performance Settings

private struct PerformanceSettingsPanel: View {
    @ObservedObject var engine: WallpaperEngine

    private let fpsOptions = [30, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performans Ayarları")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoTheme.textPri)

            // ── FPS
            SettingsSection(title: "Kare Hızı", icon: "speedometer") {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        ForEach(fpsOptions, id: \.self) { fps in
                            Button {
                                engine.preferredFPS = fps
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(fps)")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    Text("FPS")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(engine.preferredFPS == fps ? .white : DinoTheme.textSec)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(engine.preferredFPS == fps ? DinoTheme.primary : DinoTheme.border.opacity(0.3))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // ── Battery & Occlusion
            SettingsSection(title: "Güç Yönetimi", icon: "battery.75percent") {
                VStack(spacing: 12) {
                    SettingRow(title: "Pilde Duraklat", subtitle: "Şarj kablosu çıkınca oynatma durur") {
                        DinoToggle(isOn: $engine.pauseOnBattery)
                    }
                    Divider().opacity(0.15)
                    SettingRow(title: "Gizlenince Duraklat", subtitle: "Pencere arkada kalınca CPU tasarrufu") {
                        DinoToggle(isOn: $engine.pauseWhenOccluded)
                    }
                }
            }

            // ── Live stats
            SettingsSection(title: "Canlı İstatistik", icon: "chart.bar") {
                HStack(spacing: 0) {
                    StatBox(label: "CPU", value: String(format: "%.1f%%", engine.cpuUsage), color: engine.cpuUsage > 50 ? DinoTheme.danger : DinoTheme.success)
                    Spacer()
                    StatBox(label: "RAM", value: String(format: "%.0f MB", engine.memoryUsage), color: DinoTheme.primary)
                    Spacer()
                    StatBox(label: "FPS", value: String(format: "%.0f", engine.fps), color: engine.fps < 30 ? .orange : DinoTheme.success)
                }
            }

            // ── Startup
            SettingsSection(title: "Başlangıç", icon: "power") {
                SettingRow(title: "Sistem Açılışında Başlat", subtitle: "Mac açılınca otomatik başlar") {
                    DinoToggle(isOn: Binding(
                        get: { SMAppService.mainApp.status == .enabled },
                        set: { newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                print("⚠️ Login item: \(error)")
                            }
                        }
                    ))
                }
            }
        }
    }
}

// MARK: - Account Settings

private struct AccountSettingsPanel: View {
    @ObservedObject var auth: AuthService
    @ObservedObject var subscription: SubscriptionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hesap")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoTheme.textPri)

            if auth.isAuthenticated {
                // ── Profil
                SettingsSection(title: "Profil", icon: "person.fill") {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [DinoTheme.primary, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 48, height: 48)
                            Text(auth.userProfile?.initials ?? "U")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.userProfile?.displayName ?? "Kullanıcı")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DinoTheme.textPri)
                            Text(auth.userProfile?.email ?? "")
                                .font(.system(size: 11))
                                .foregroundStyle(DinoTheme.textDim)
                        }

                        Spacer()

                        Text(subscription.currentPlan.displayName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DinoTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DinoTheme.primary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                // ── Çıkış
                Button {
                    Task { await auth.signOut() }
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Çıkış Yap")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DinoTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DinoTheme.danger.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DinoTheme.danger.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            } else {
                // ── Giriş yap
                SettingsSection(title: "Giriş", icon: "person.badge.plus") {
                    VStack(spacing: 12) {
                        Text("Premium wallpaper'lara erişmek ve ayarlarınızı senkronize etmek için giriş yapın.")
                            .font(.system(size: 12))
                            .foregroundStyle(DinoTheme.textSec)

                        Button {
                            openLoginFromSettings()
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Giriş Yap / Kayıt Ol")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DinoTheme.primary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func openLoginFromSettings() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: LoginView()
                .environmentObject(AuthService.shared)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - About Panel

private struct AboutPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hakkında")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DinoTheme.textPri)

            SettingsSection(title: "MacOS-Dino", icon: "sparkles.rectangle.stack") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [DinoTheme.primary, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("MacOS-Dino")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(DinoTheme.textPri)
                            Text("Dinamik Masaüstü Duvar Kağıdı Motoru")
                                .font(.system(size: 11))
                                .foregroundStyle(DinoTheme.textSec)
                            Text("Sürüm 1.0.0")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(DinoTheme.textDim)
                        }
                    }

                    Divider().opacity(0.15)

                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow(label: "Platform", value: "macOS 14+")
                        InfoRow(label: "Motor", value: "AVFoundation + Metal")
                        InfoRow(label: "Crossfade", value: "Dual-Layer Transition")
                        InfoRow(label: "Lisans", value: "Proprietary")
                    }
                }
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DinoTheme.textDim)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DinoTheme.textSec)
        }
    }
}

// MARK: - Custom Components

private struct DinoToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(.switch)
            .tint(DinoTheme.primary)
            .scaleEffect(0.8)
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DinoTheme.textDim)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DinoTheme.bg)
        )
    }
}
