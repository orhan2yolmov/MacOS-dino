// UserProfile.swift
// MacOS-Dino – Kullanıcı Profil Modeli
// Supabase 'profiles' tablosuna map'lenir

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var displayName: String
    var email: String?
    var avatarURL: String?
    var proUntil: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed

    var isPro: Bool {
        guard let proUntil else { return false }
        return proUntil > Date()
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case email
        case avatarURL = "avatar_url"
        case proUntil = "pro_until"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
