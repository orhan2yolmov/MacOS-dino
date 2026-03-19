// AppDelegate.swift
// MacOS-Dino – NSApplicationDelegate
// Login item + sistem event dinleyicileri

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only app – Dock simgesi gösterme
        NSApp.setActivationPolicy(.accessory)

        // Wallpaper engine'i başlat
        Task {
            await WallpaperEngine.shared.initialize()
        }

        // Ekran değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Space değişikliklerini dinle
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Sleep/Wake dinle
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Ekran kilidi – DistributedNotificationCenter ile
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenUnlocked),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )

        print("🦕 MacOS-Dino başlatıldı!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        WallpaperEngine.shared.shutdown()
        print("🦕 MacOS-Dino kapatılıyor...")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - System Event Handlers

    @objc private func screenParametersChanged(_ notification: Notification) {
        Task { @MainActor in
            await WallpaperEngine.shared.handleScreenChange()
        }
    }

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        Task { @MainActor in
            WallpaperEngine.shared.handleSpaceChange()
        }
    }

    @objc private func systemWillSleep(_ notification: Notification) {
        Task { @MainActor in
            WallpaperEngine.shared.pause()
        }
    }

    @objc private func systemDidWake(_ notification: Notification) {
        Task { @MainActor in
            WallpaperEngine.shared.resume()
        }
    }

    @objc private func screenLocked(_ notification: Notification) {
        Task { @MainActor in
            WallpaperEngine.shared.pause()
        }
    }

    @objc private func screenUnlocked(_ notification: Notification) {
        Task { @MainActor in
            WallpaperEngine.shared.resume()
        }
    }
}
