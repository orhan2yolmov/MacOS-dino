// AuthService.swift
// MacOS-Dino – Supabase Authentication Servisi
// Email/Password + Apple Sign In + OAuth desteği

import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {

    static let shared = AuthService()

    // MARK: - Published State

    @Published var currentUser: User? = nil
    @Published var userProfile: UserProfile? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var authStateTask: Task<Void, Never>?

    private init() {
        listenToAuthChanges()
    }

    // MARK: - Auth State Listener

    private func listenToAuthChanges() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session {
                        self.currentUser = session.user
                        self.isAuthenticated = true
                        await self.fetchProfile()
                    }
                case .signedIn:
                    if let session {
                        self.currentUser = session.user
                        self.isAuthenticated = true
                        await self.fetchProfile()
                    }
                case .signedOut:
                    self.currentUser = nil
                    self.userProfile = nil
                    self.isAuthenticated = false
                case .tokenRefreshed:
                    break
                default:
                    break
                }
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )

            currentUser = response.user
            isAuthenticated = true

            // Profil oluştur
            await createProfile(userId: response.user.id, displayName: displayName)

            print("✅ Kayıt başarılı: \(email)")
        } catch {
            errorMessage = "Kayıt hatası: \(error.localizedDescription)"
            print("❌ Kayıt hatası: \(error)")
        }

        isLoading = false
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )

            currentUser = session.user
            isAuthenticated = true
            await fetchProfile()

            print("✅ Giriş başarılı: \(email)")
        } catch {
            errorMessage = "Giriş hatası: \(error.localizedDescription)"
            print("❌ Giriş hatası: \(error)")
        }

        isLoading = false
    }

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            currentUser = session.user
            isAuthenticated = true
            await fetchProfile()

            print("✅ Apple ile giriş başarılı")
        } catch {
            errorMessage = "Apple giriş hatası: \(error.localizedDescription)"
            print("❌ Apple giriş hatası: \(error)")
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
            print("✅ Çıkış yapıldı")
        } catch {
            errorMessage = "Çıkış hatası: \(error.localizedDescription)"
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ Şifre sıfırlama maili gönderildi: \(email)")
        } catch {
            errorMessage = "Şifre sıfırlama hatası: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Profile Management

    private func createProfile(userId: UUID, displayName: String) async {
        let profile = UserProfile(
            id: UUID(),
            userId: userId,
            displayName: displayName,
            avatarURL: nil,
            proUntil: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await supabase
                .from(SupabaseConfig.Tables.profiles)
                .insert(profile)
                .execute()

            self.userProfile = profile
        } catch {
            print("❌ Profil oluşturma hatası: \(error)")
        }
    }

    func fetchProfile() async {
        guard let userId = currentUser?.id else { return }

        do {
            let profile: UserProfile = try await supabase
                .from(SupabaseConfig.Tables.profiles)
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            self.userProfile = profile
        } catch {
            print("❌ Profil getirme hatası: \(error)")
        }
    }

    func updateProfile(displayName: String? = nil, avatarURL: String? = nil) async {
        guard let userId = currentUser?.id else { return }

        var updates: [String: String] = [:]
        if let name = displayName { updates["display_name"] = name }
        if let avatar = avatarURL { updates["avatar_url"] = avatar }
        updates["updated_at"] = ISO8601DateFormatter().string(from: Date())

        do {
            try await supabase
                .from(SupabaseConfig.Tables.profiles)
                .update(updates)
                .eq("user_id", value: userId)
                .execute()

            await fetchProfile()
        } catch {
            print("❌ Profil güncelleme hatası: \(error)")
        }
    }

    deinit {
        authStateTask?.cancel()
    }
}
