// WallpaperManager.swift
// MacOS-Dino – Yerel Wallpaper Yönetimi
// İndirme, cache, import, yerel dosya yönetimi + Bundled wallpapers

import Foundation
import AppKit
import AVFoundation

@MainActor
final class WallpaperManager: ObservableObject {

    static let shared = WallpaperManager()

    @Published var downloadedWallpapers: [Wallpaper] = []
    @Published var bundledWallpapers: [Wallpaper] = []
    @Published var downloadProgress: [UUID: Double] = [:]
    @Published var isImporting = false

    private let storageService = StorageService.shared
    private let wallpaperService = WallpaperService.shared

    /// All locally available wallpapers (bundled + downloaded)
    var allLocalWallpapers: [Wallpaper] {
        bundledWallpapers + downloadedWallpapers
    }

    private init() {
        loadDownloadedWallpapers()
        loadBundledWallpapers()
    }

    // MARK: - Bundled Wallpapers

    private func loadBundledWallpapers() {
        let bundledFiles: [(filename: String, displayName: String, category: WallpaperCategory)] = [
            ("13687213_1920_1080_30fps", "Deep Ocean Flow", .nature),
            ("14311853-uhd_3840_2160_29fps", "Aurora Borealis 4K", .deepSpace),
            ("14828390_1920_1080_30fps", "Neon City Pulse", .cityscape),
            ("MacbookAirBG", "Macbook Air Gradient", .abstract),
        ]

        var loaded: [Wallpaper] = []

        for item in bundledFiles {
            guard let url = Bundle.main.url(forResource: item.filename, withExtension: "mp4") else {
                print("⚠️ Bundled video bulunamadı: \(item.filename).mp4")
                continue
            }

            // Video dimensions
            let asset = AVURLAsset(url: url)
            var dims: WallpaperDimensions? = nil
            var ratio: AspectRatio = .widescreen
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                let w = Int(abs(size.width))
                let h = Int(abs(size.height))
                dims = WallpaperDimensions(width: w, height: h)
                let aspect = Double(w) / Double(max(h, 1))
                if aspect > 2.5 { ratio = .superUltrawide }
                else if aspect > 2.0 { ratio = .ultrawide }
                else if aspect > 1.2 { ratio = .widescreen }
                else if aspect > 0.8 { ratio = .standard }
                else { ratio = .portrait }
            }

            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

            let stableID = UUID(uuidString: stableUUID(for: item.filename)) ?? UUID()

            let wallpaper = Wallpaper(
                id: stableID,
                name: item.displayName,
                category: item.category,
                contentType: .video,
                remoteURL: url,
                localURL: url,
                thumbnailPath: nil,
                storagePath: nil,
                shaderName: nil,
                shaderParameters: nil,
                loopStartTime: nil,
                loopEndTime: nil,
                aspectRatio: ratio,
                dimensions: dims,
                fileSize: fileSize,
                isDownloaded: true,
                isFeatured: true,
                popularityScore: 100,
                createdAt: Date(timeIntervalSince1970: 1710000000)
            )
            loaded.append(wallpaper)
        }

        bundledWallpapers = loaded
        print("📦 \(loaded.count) bundled wallpaper yüklendi")
    }

    private func stableUUID(for name: String) -> String {
        var hash = name.hashValue
        if hash < 0 { hash = -hash }
        let hex = String(format: "%08x", hash & 0xFFFFFFFF)
        return "00000000-0000-4000-8000-\(hex)0000"
    }

    // MARK: - Download

    func downloadWallpaper(_ wallpaper: Wallpaper) async throws {
        let wallpaperId = wallpaper.id

        if storageService.cachedVideoURL(for: wallpaperId) != nil {
            print("ℹ️ Wallpaper zaten indirilmiş: \(wallpaper.name)")
            return
        }

        downloadProgress[wallpaperId] = 0.0

        let localURL = StorageService.cacheDirectory.appendingPathComponent("\(wallpaperId.uuidString).mp4")

        if let remotePath = wallpaper.storagePath {
            try await storageService.downloadVideo(remotePath: remotePath, localURL: localURL)
        } else {
            let (data, _) = try await URLSession.shared.data(from: wallpaper.remoteURL)
            try data.write(to: localURL)
        }

        downloadProgress[wallpaperId] = 1.0

        var downloaded = wallpaper
        downloaded.localURL = localURL
        downloaded.isDownloaded = true

        downloadedWallpapers.append(downloaded)
        saveDownloadedWallpapers()

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
        downloadedWallpapers = wallpapers.filter { wp in
            guard let localURL = wp.localURL else { return false }
            return FileManager.default.fileExists(atPath: localURL.path)
        }
    }
}
