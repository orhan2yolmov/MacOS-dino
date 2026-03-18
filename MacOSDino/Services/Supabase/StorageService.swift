// StorageService.swift
// MacOS-Dino – Supabase Storage Servisi
// Video upload/download, thumbnail yönetimi, kullanıcı upload'ları

import Foundation
import Supabase

final class StorageService {

    static let shared = StorageService()
    private init() {}

    // MARK: - Download

    /// Wallpaper video URL'ini al (signed veya public)
    func getWallpaperVideoURL(path: String, isPublic: Bool = true) async throws -> URL {
        if isPublic {
            let publicURL = try supabase.storage
                .from(SupabaseConfig.Buckets.wallpaperVideos)
                .getPublicURL(path: path)
            return publicURL
        } else {
            let signedURL = try await supabase.storage
                .from(SupabaseConfig.Buckets.wallpaperVideos)
                .createSignedURL(path: path, expiresIn: 3600)
            return signedURL
        }
    }

    /// Thumbnail URL'ini al
    func getThumbnailURL(path: String) throws -> URL {
        return try supabase.storage
            .from(SupabaseConfig.Buckets.thumbnails)
            .getPublicURL(path: path)
    }

    /// Video dosyasını yerel diske indir
    func downloadVideo(remotePath: String, localURL: URL) async throws {
        let data = try await supabase.storage
            .from(SupabaseConfig.Buckets.wallpaperVideos)
            .download(path: remotePath)

        try data.write(to: localURL)
        print("✅ Video indirildi: \(localURL.lastPathComponent)")
    }

    /// Thumbnail'i indir
    func downloadThumbnail(remotePath: String) async throws -> Data {
        return try await supabase.storage
            .from(SupabaseConfig.Buckets.thumbnails)
            .download(path: remotePath)
    }

    // MARK: - Upload

    /// Kullanıcı video upload (Pro kullanıcılar, max 5GB quota)
    func uploadUserVideo(
        userId: UUID,
        fileData: Data,
        fileName: String,
        contentType: String = "video/mp4"
    ) async throws -> String {
        let path = "\(userId.uuidString)/\(fileName)"

        try await supabase.storage
            .from(SupabaseConfig.Buckets.userUploads)
            .upload(
                path: path,
                file: fileData,
                options: FileOptions(
                    contentType: contentType,
                    upsert: false
                )
            )

        print("✅ Video yüklendi: \(path)")
        return path
    }

    /// Kullanıcı avatar upload
    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        let path = "avatars/\(userId.uuidString).webp"

        try await supabase.storage
            .from(SupabaseConfig.Buckets.thumbnails)
            .upload(
                path: path,
                file: imageData,
                options: FileOptions(
                    contentType: "image/webp",
                    upsert: true
                )
            )

        return path
    }

    // MARK: - Delete

    /// Kullanıcı upload'ını sil
    func deleteUserUpload(userId: UUID, fileName: String) async throws {
        let path = "\(userId.uuidString)/\(fileName)"
        try await supabase.storage
            .from(SupabaseConfig.Buckets.userUploads)
            .remove(paths: [path])
    }

    // MARK: - Cache Management

    /// Yerel cache dizinini al
    static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheDir = appSupport.appendingPathComponent("MacOS-Dino/Cache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }

        return cacheDir
    }

    /// Cache boyutunu hesapla (MB)
    func getCacheSize() -> Double {
        let cacheDir = Self.cacheDirectory
        guard let enumerator = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }

        return Double(totalSize) / (1024.0 * 1024.0)
    }

    /// Cache temizle
    func clearCache() throws {
        let cacheDir = Self.cacheDirectory
        let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
        for file in contents {
            try FileManager.default.removeItem(at: file)
        }
        print("🗑️ Cache temizlendi")
    }

    /// Wallpaper'ın yerel cache'de olup olmadığını kontrol et
    func cachedVideoURL(for wallpaperId: UUID) -> URL? {
        let localPath = Self.cacheDirectory.appendingPathComponent("\(wallpaperId.uuidString).mp4")
        return FileManager.default.fileExists(atPath: localPath.path) ? localPath : nil
    }
}
