// SettingsView.swift
// MacOS-Dino – Professional Dark Theme Settings

import SwiftUI
import ServiceManagement

// MARK: - Color Theme (shared)

enum DinoColors {
    static let bg        = Color(red: 0.063, green: 0.086, blue: 0.133)
    static let surface   = Color(red: 0.102, green: 0.133, blue: 0.204)
    static let border    = Color(red: 0.176, green: 0.227, blue: 0.329)
    static let primary   = Color(red: 0.051, green: 0.349, blue: 0.949)
    static let textPri   = Color.white
    static let textSec   = Color.white.opacity(0.5)
    static let textDim   = Color.white.opacity(0.3)
    static let danger    = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let success   = Color(red: 0.2, green: 0.85, blue: 0.5)
    static let mainBg    = Color(red: 0.039, green: 0.059, blue: 0.094)
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
            settingsSidebar
            Rectangle().fill(DinoColors.border.opacity(0.5)).frame(width: 1)
            settingsContent
        }
        .frame(width: 680, height: 520)
        .background(DinoColors.bg)
        .preferredColorScheme(.dark)
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [DinoColors.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "sparkles.rectangle.stack").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ayarlar").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    Text("MacOS-Dino").font(.system(size: 10)).foregroundStyle(DinoColors.textDim)
                }
            }
            .padding(.bottom, 16)

            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon).font(.system(size: 13)).foregroundStyle(selectedTab == tab ? DinoColors.primary : DinoColors.textSec).frame(width: 20)
                        Text(tab.rawValue).font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular)).foregroundStyle(selectedTab == tab ? .white : DinoColors.textSec)
                        Spacer()
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(selectedTab == tab ? DinoColors.primary.opacity(0.15) : Color.clear))
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Text("v1.0.0").font(.system(size: 10, design: .monospaced)).foregroundStyle(DinoColors.textDim)
        }
        .padding(16)
        .frame(width: 180)
        .background(DinoColors.surface.opacity(0.5))
    }

    private var settingsContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                switch selectedTab {
                case .playback:   playbackPanel
                case .display:    displayPanel
                case .performance: performancePanel
                case .account:    accountPanel
                case .about:      aboutPanel
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Playback

    private var playbackPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Oynatma Ayarları").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

            SettingsCard(title: "Oynatma Hızı", icon: "gauge.with.dots.needle.33percent") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Hız").font(.system(size: 11)).foregroundStyle(DinoColors.textSec)
                        Spacer()
                        Text(String(format: "%.0f%%", engine.playbackSpeed * 100))
                            .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(DinoColors.primary)
                    }
                    Slider(value: Binding(get: { Double(engine.playbackSpeed) }, set: { engine.playbackSpeed = Float($0) }), in: 0.1...1.0, step: 0.05).tint(DinoColors.primary)

                    HStack(spacing: 8) {
                        ForEach([("¼×", Float(0.25)), ("⅓×", Float(0.33)), ("½×", Float(0.5)), ("¾×", Float(0.75)), ("1×", Float(1.0))], id: \.1) { name, value in
                            Button { engine.playbackSpeed = value } label: {
                                Text(name).font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(abs(engine.playbackSpeed - value) < 0.02 ? .white : DinoColors.textSec)
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(abs(engine.playbackSpeed - value) < 0.02 ? DinoColors.primary : DinoColors.border.opacity(0.4)))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            SettingsCard(title: "Geçiş Efekti", icon: "arrow.triangle.2.circlepath") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Crossfade Süresi").font(.system(size: 11)).foregroundStyle(DinoColors.textSec)
                        Spacer()
                        Text(String(format: "%.1f sn", engine.crossfadeDuration)).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(DinoColors.primary)
                    }
                    Slider(value: $engine.crossfadeDuration, in: 0.5...5.0, step: 0.5).tint(DinoColors.primary)
                }
            }
        }
    }

    // MARK: - Display

    private var displayPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Görüntü Ayarları").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

            SettingsCard(title: "Aktif Monitörler", icon: "display.2") {
                VStack(spacing: 8) {
                    if engine.activeDisplays.isEmpty {
                        HStack { Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange); Text("Monitör bulunamadı").font(.system(size: 12)).foregroundStyle(DinoColors.textSec) }
                    } else {
                        ForEach(engine.activeDisplays, id: \.displayID) { display in
                            HStack(spacing: 12) {
                                Image(systemName: display.isMain ? "display" : "rectangle.on.rectangle").foregroundStyle(display.isMain ? DinoColors.primary : DinoColors.textSec).frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(display.name).font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
                                    Text("\(Int(display.frame.width))×\(Int(display.frame.height))").font(.system(size: 10)).foregroundStyle(DinoColors.textDim)
                                }
                                Spacer()
                                if display.isMain { Text("ANA").font(.system(size: 9, weight: .bold)).foregroundStyle(DinoColors.primary).padding(.horizontal, 6).padding(.vertical, 3).background(DinoColors.primary.opacity(0.15)).clipShape(Capsule()) }
                            }
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.bg))
                        }
                    }
                }
            }

            SettingsCard(title: "Etkileşim", icon: "cursorarrow.motionlines") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) { Text("Mouse Etkileşimi").font(.system(size: 12, weight: .medium)).foregroundStyle(.white); Text("Cursor wallpaper ile etkileşir").font(.system(size: 10)).foregroundStyle(DinoColors.textDim) }
                    Spacer()
                    Toggle("", isOn: $engine.enableMouseInteraction).toggleStyle(.switch).tint(DinoColors.primary).scaleEffect(0.8)
                }
            }
        }
    }

    // MARK: - Performance

    private var performancePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performans Ayarları").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

            SettingsCard(title: "Kare Hızı", icon: "speedometer") {
                HStack(spacing: 10) {
                    ForEach([30, 60], id: \.self) { fps in
                        Button { engine.preferredFPS = fps } label: {
                            VStack(spacing: 4) {
                                Text("\(fps)").font(.system(size: 18, weight: .bold, design: .monospaced))
                                Text("FPS").font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(engine.preferredFPS == fps ? .white : DinoColors.textSec)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(engine.preferredFPS == fps ? DinoColors.primary : DinoColors.border.opacity(0.3)))
                        }.buttonStyle(.plain)
                    }
                }
            }

            SettingsCard(title: "Güç Yönetimi", icon: "battery.75percent") {
                VStack(spacing: 10) {
                    HStack { VStack(alignment: .leading) { Text("Pilde Duraklat").font(.system(size: 12, weight: .medium)).foregroundStyle(.white); Text("Şarj çıkınca oynatma durur").font(.system(size: 10)).foregroundStyle(DinoColors.textDim) }; Spacer(); Toggle("", isOn: $engine.pauseOnBattery).toggleStyle(.switch).tint(DinoColors.primary).scaleEffect(0.8) }
                    Divider().opacity(0.15)
                    HStack { VStack(alignment: .leading) { Text("Gizlenince Duraklat").font(.system(size: 12, weight: .medium)).foregroundStyle(.white); Text("Pencere arkada kalınca CPU tasarrufu").font(.system(size: 10)).foregroundStyle(DinoColors.textDim) }; Spacer(); Toggle("", isOn: $engine.pauseWhenOccluded).toggleStyle(.switch).tint(DinoColors.primary).scaleEffect(0.8) }
                }
            }

            SettingsCard(title: "Başlangıç", icon: "power") {
                HStack {
                    VStack(alignment: .leading) { Text("Sistem Açılışında Başlat").font(.system(size: 12, weight: .medium)).foregroundStyle(.white); Text("Mac açılınca otomatik başlar").font(.system(size: 10)).foregroundStyle(DinoColors.textDim) }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { SMAppService.mainApp.status == .enabled },
                        set: { val in try? val ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
                    )).toggleStyle(.switch).tint(DinoColors.primary).scaleEffect(0.8)
                }
            }
        }
    }

    // MARK: - Account

    private var accountPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hesap").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

            if auth.isAuthenticated {
                SettingsCard(title: "Profil", icon: "person.fill") {
                    HStack(spacing: 14) {
                        Circle().fill(LinearGradient(colors: [DinoColors.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 48, height: 48)
                            .overlay(Text(auth.userProfile?.initials ?? "U").font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.userProfile?.displayName ?? "Kullanıcı").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            Text(auth.userProfile?.email ?? "").font(.system(size: 11)).foregroundStyle(DinoColors.textDim)
                        }
                        Spacer()
                        Text(subscription.currentPlan.displayName).font(.system(size: 11, weight: .bold)).foregroundStyle(DinoColors.primary).padding(.horizontal, 10).padding(.vertical, 5).background(DinoColors.primary.opacity(0.15)).clipShape(Capsule())
                    }
                }
                Button { Task { await auth.signOut() } } label: {
                    HStack { Image(systemName: "rectangle.portrait.and.arrow.right"); Text("Çıkış Yap") }
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(DinoColors.danger).frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.danger.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 8).stroke(DinoColors.danger.opacity(0.3), lineWidth: 1)))
                }.buttonStyle(.plain)
            } else {
                SettingsCard(title: "Giriş", icon: "person.badge.plus") {
                    VStack(spacing: 12) {
                        Text("Premium wallpaper'lara erişmek için giriş yapın.").font(.system(size: 12)).foregroundStyle(DinoColors.textSec)
                        Button {
                            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 560), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
                            w.center(); w.titlebarAppearsTransparent = true; w.title = ""; w.isReleasedWhenClosed = false
                            w.contentView = NSHostingView(rootView: LoginView().environmentObject(AuthService.shared))
                            w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
                        } label: {
                            HStack { Image(systemName: "person.badge.plus"); Text("Giriş Yap / Kayıt Ol") }
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(DinoColors.primary))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - About

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hakkında").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
            SettingsCard(title: "MacOS-Dino", icon: "sparkles.rectangle.stack") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [DinoColors.primary, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 56, height: 56)
                            .overlay(Image(systemName: "sparkles.rectangle.stack").font(.system(size: 24, weight: .semibold)).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MacOS-Dino").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            Text("Dinamik Masaüstü Duvar Kağıdı Motoru").font(.system(size: 11)).foregroundStyle(DinoColors.textSec)
                            Text("Sürüm 1.0.0").font(.system(size: 10, design: .monospaced)).foregroundStyle(DinoColors.textDim)
                        }
                    }
                    Divider().opacity(0.15)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { Text("Platform").font(.system(size: 11)).foregroundStyle(DinoColors.textDim).frame(width: 80, alignment: .leading); Text("macOS 14+").font(.system(size: 11, weight: .medium)).foregroundStyle(DinoColors.textSec) }
                        HStack { Text("Motor").font(.system(size: 11)).foregroundStyle(DinoColors.textDim).frame(width: 80, alignment: .leading); Text("AVFoundation + Metal").font(.system(size: 11, weight: .medium)).foregroundStyle(DinoColors.textSec) }
                        HStack { Text("Crossfade").font(.system(size: 11)).foregroundStyle(DinoColors.textDim).frame(width: 80, alignment: .leading); Text("Dual-Layer Transition").font(.system(size: 11, weight: .medium)).foregroundStyle(DinoColors.textSec) }
                    }
                }
            }
        }
    }
}

// MARK: - Settings Card

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(DinoColors.primary)
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(DinoColors.surface).overlay(RoundedRectangle(cornerRadius: 12).stroke(DinoColors.border.opacity(0.4), lineWidth: 1)))
    }
}
