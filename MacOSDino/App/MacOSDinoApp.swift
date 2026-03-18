// MacOSDinoApp.swift
// MacOS-Dino – Dinamik Hareketli Arka Plan Uygulaması
// Supabase DB: Yolmov

import SwiftUI

@main
struct MacOSDinoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var wallpaperEngine = WallpaperEngine.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        // Menu Bar Only – LSUIElement = true
        MenuBarExtra {
            MenuBarPopover()
                .environmentObject(wallpaperEngine)
                .environmentObject(authService)
                .environmentObject(subscriptionManager)
        } label: {
            Image(systemName: "sparkles.rectangle.stack")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        // Ayarlar penceresi
        Settings {
            SettingsView()
                .environmentObject(wallpaperEngine)
                .environmentObject(authService)
                .environmentObject(subscriptionManager)
        }

        // Ana galeri penceresi (Window menüsünden veya menu bar'dan açılır)
        Window("MacOS-Dino Galeri", id: "gallery") {
            GalleryView()
                .environmentObject(wallpaperEngine)
                .environmentObject(authService)
                .environmentObject(subscriptionManager)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
