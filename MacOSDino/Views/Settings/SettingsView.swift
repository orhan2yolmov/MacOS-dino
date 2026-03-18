// SettingsView.swift
// MacOS-Dino – Ayarlar Penceresi
// Display, Performans, Hesap ayarları

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(engine)
                .tabItem {
                    Label("Genel", systemImage: "gear")
                }

            DisplaySettingsView()
                .environmentObject(engine)
                .tabItem {
                    Label("Ekran", systemImage: "display")
                }

            PerformanceSettingsView()
                .environmentObject(engine)
                .tabItem {
                    Label("Performans", systemImage: "gauge.with.dots.needle.67percent")
                }

            AccountSettingsView()
                .environmentObject(auth)
                .environmentObject(subscription)
                .tabItem {
                    Label("Hesap", systemImage: "person.crop.circle")
                }

            AboutView()
                .tabItem {
                    Label("Hakkında", systemImage: "info.circle")
                }
        }
        .frame(width: 550, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @AppStorage("MacOSDino.launchAtLogin") private var launchAtLogin = true
    @AppStorage("MacOSDino.showInDock") private var showInDock = false
    @AppStorage("MacOSDino.pauseOnBattery") private var pauseOnBattery = true
    @AppStorage("MacOSDino.pauseWhenOccluded") private var pauseWhenOccluded = true

    var body: some View {
        Form {
            Section("Başlangıç") {
                Toggle("Oturum açıldığında başlat", isOn: $launchAtLogin)
                Toggle("Dock'ta göster", isOn: $showInDock)
            }

            Section("Enerji Tasarrufu") {
                Toggle("Pil modunda duraklat", isOn: $pauseOnBattery)
                    .onChange(of: pauseOnBattery) { _, newValue in
                        engine.pauseOnBattery = newValue
                    }

                Toggle("Masaüstü kapalıyken duraklat", isOn: $pauseWhenOccluded)
                    .onChange(of: pauseWhenOccluded) { _, newValue in
                        engine.pauseWhenOccluded = newValue
                    }
            }

            Section("Etkileşim") {
                Toggle("Fare etkileşimi aktif", isOn: $engine.enableMouseInteraction)
                Toggle("Ses reaktif mod", isOn: $engine.enableAudioReactive)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @State private var selectedDisplay: DisplayConfiguration?

    var body: some View {
        Form {
            Section("Aktif Ekranlar") {
                ForEach(engine.activeDisplays) { display in
                    HStack {
                        Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(display.name)
                                .fontWeight(.medium)
                            Text(display.displayDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if display.isMain {
                            Badge(text: "ANA", color: .blue)
                        }
                        if display.isProMotion {
                            Badge(text: "ProMotion", color: .purple)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Wallpaper Ayarları") {
                Text("Her ekran için ayrı wallpaper ayarlayabilirsiniz.\nGaleri'den wallpaper seçip sağ panelden ekran seçin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Performance Settings

struct PerformanceSettingsView: View {
    @EnvironmentObject var engine: WallpaperEngine
    @AppStorage("MacOSDino.preferredFPS") private var preferredFPS = 60

    var body: some View {
        Form {
            Section("Kare Hızı") {
                Picker("Hedef FPS", selection: $preferredFPS) {
                    Text("24 FPS (Sinematik)").tag(24)
                    Text("30 FPS (Normal)").tag(30)
                    Text("60 FPS (Akıcı)").tag(60)
                    if DisplayLinkManager.isProMotionSupported {
                        Text("120 FPS (ProMotion)").tag(120)
                    }
                }
                .onChange(of: preferredFPS) { _, newValue in
                    engine.preferredFPS = newValue
                }

                Text("Yüksek FPS daha fazla enerji tüketir")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Mevcut Performans") {
                LabeledContent("CPU Kullanımı") {
                    Text(String(format: "%.2f%%", engine.cpuUsage))
                        .foregroundStyle(engine.cpuUsage > 0.5 ? .red : .green)
                }
                LabeledContent("RAM Kullanımı") {
                    Text(String(format: "%.0f MB", engine.memoryUsage))
                        .foregroundStyle(engine.memoryUsage > 135 ? .red : .green)
                }
                LabeledContent("FPS") {
                    Text(String(format: "%.0f", engine.fps))
                        .foregroundStyle(engine.fps < Double(preferredFPS - 10) ? .orange : .green)
                }
            }

            Section("Cache") {
                LabeledContent("Cache Boyutu") {
                    Text(String(format: "%.1f MB", StorageService.shared.getCacheSize()))
                }

                Button("Cache Temizle", role: .destructive) {
                    try? StorageService.shared.clearCache()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var subscription: SubscriptionManager

    var body: some View {
        Form {
            if auth.isAuthenticated {
                Section("Profil") {
                    LabeledContent("Ad") {
                        Text(auth.userProfile?.displayName ?? "—")
                    }
                    LabeledContent("Plan") {
                        Text(subscription.currentPlan.displayName)
                            .foregroundStyle(.blue)
                    }
                }

                Section("Abonelik") {
                    if !subscription.isProUser {
                        Button("Pro'ya Yükselt – $9.99 (Lifetime)") {
                            Task { await subscription.purchase(.lifetimePro) }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !subscription.hasContentPass {
                        Button("Content Pass – $0.99/ay") {
                            Task { await subscription.purchase(.contentPassMonthly) }
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Satın Almaları Geri Yükle") {
                        Task { await subscription.restorePurchases() }
                    }
                }

                Section {
                    Button("Çıkış Yap", role: .destructive) {
                        Task { await auth.signOut() }
                    }
                }
            } else {
                Section {
                    Text("Favori ve indirmelerinizi senkronize etmek için giriş yapın.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Giriş Yap / Kayıt Ol") {
                        // Auth sheet göster
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("MacOS-Dino")
                .font(.title)
                .fontWeight(.bold)

            Text("Dinamik Hareketli Arka Plan Uygulaması")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Versiyon 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(width: 200)

            Text("macOS Tahoe 26 • Liquid Glass • Apple Silicon")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("Metal Shaders • AVFoundation • Supabase")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Link("GitHub", destination: URL(string: "https://github.com")!)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
