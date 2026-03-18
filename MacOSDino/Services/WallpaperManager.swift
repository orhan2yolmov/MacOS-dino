// WallpaperManager.swift
// MacOS-Dino – Yerel Wallpaper Yönetimi
// İndirme, cache, import, yerel dosya yönetimi

import Foundation
import AppKit

@MainActor
final class WallpaperManager: ObservableObject {

    static let shared = WallpaperManager()

    @Published var downloadedWallpapers: [Wallpaper] = []
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var isImporting = false

    private let storageService = StorageService.shared
    private let wallpaperService = WallpaperService.shared

    private init() {
        loadDownloadedWallpapers()
    }

    // MARK: - Download

    func downloadWallpaper(_ wallpaper: Wallpaper) async throws {
        let wallpaperId = wallpaper.id

        // Zaten indirilmiş mi?
        if storageService.cachedVideoURL(for: wallpaperId) != nil {
            print("ℹ️ Wallpaper zaten indirilmiş: \(wallpaper.name)")
            return
        }

        downloadProgress[wallpaperId] = 0.0

        // Remote URL'den indir
        let localURL = StorageService.cacheDirectory.appendingPathComponent("\(wallpaperId.uuidString).mp4")

        if let remotePath = wallpaper.storagePath {
            try await storageService.downloadVideo(remotePath: remotePath, localURL: localURL)
        } else {
            // Direct URL'den indir
            let (data, _) = try await URLSession.shared.data(from: wallpaper.remoteURL)
            try data.write(to: localURL)
        }

        downloadProgress[wallpaperId] = 1.0

        // Wallpaper'ı güncelle (local URL ekle)
        var downloaded = wallpaper
        downloaded.localURL = localURL
        downloaded.isDownloaded = true

        // Listeye ekle
        downloadedWallpapers.append(downloaded)
        saveDownloadedWallpapers()

        // Analytics
        await AnalyticsService.shared.trackEvent(.wallpaperDownloaded, properties: [
            "wallpaper_id": wallpaperId.uuidString
        ])

        print("✅ İndirme tamamlandı: \(wallpaper.name)")
    }

    func deleteDownloadedWallpaper(_ wallpaper: Wallpaper) throws {
        if let localURL = wallpaper.localURL {
            try FileManager.default.removeItem(at: localURL)
        }
        downloadedWallpapers.removeAll { $0.id == wallpaper.id }
        saveDownloadedWallpapers()
    }

    // MARK: - Import Local File

    func importLocalVideo() async throws -> Wallpaper? {
        isImporting = true
        defer { isImporting = false }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Video Seç – MacOS-Dino"
        panel.message = "Arka plan olarak kullanmak istediğiniz video dosyasını seçin"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }

        // Cache'e kopyala
        let wallpaperId = UUID()
        let ext = url.pathExtension
        let localURL = StorageService.cacheDirectory.appendingPathComponent("\(wallpaperId.uuidString).\(ext)")
        try FileManager.default.copyItem(at: url, to: localURL)

        let wallpaper = Wallpaper(
            id: wallpaperId,
            name: url.deletingPathExtension().lastPathComponent,
            category: .personal,
            contentType: .video,
            remoteURL: url,
            localURL: localURL,
            thumbnailPath: nil,
            storagePath: nil,
            shaderName: nil,
            shaderParameters: nil,
            loopStartTime: nil,
            loopEndTime: nil,
            aspectRatio: .widescreen,
            dimensions: nil,
            fileSize: nil,
            isDownloaded: true,
            isFeatured: false,
            popularityScore: 0,
            createdAt: Date()
        )

        downloadedWallpapers.append(wallpaper)
        saveDownloadedWallpapers()

        return wallpaper
    }

    // MARK: - Persistence

    private func saveDownloadedWallpapers() {
        if let data = try? JSONEncoder().encode(downloadedWallpapers) {
            UserDefaults.standard.set(data, forKey: "MacOSDino.downloadedWallpapers")
        }
    }

    private func loadDownloadedWallpapers() {
        guard let data = UserDefaults.standard.data(forKey: "MacOSDino.downloadedWallpapers"),
              let wallpapers = try? JSONDecoder().decode([Wallpaper].self, from: data) else {
            return
        }
        // Sadece dosyası hâlâ var olanları yükle
        downloadedWallpapers = wallpapers.filter { wp in
            guard let localURL = wp.localURL else { return false }
            return FileManager.default.fileExists(atPath: localURL.path)
        }
    }
}
