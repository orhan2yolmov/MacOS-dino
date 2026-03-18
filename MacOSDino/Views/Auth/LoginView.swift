// LoginView.swift
// MacOS-Dino – Giriş / Kayıt Ekranı
// Email + Apple Sign In

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Logo
            VStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("MacOS-Dino")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Form
            VStack(spacing: 12) {
                if isSignUp {
                    TextField("Ad Soyad", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField("Şifre", text: $password)
                    .textFieldStyle(.roundedBorder)

                if isSignUp {
                    SecureField("Şifre Tekrar", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Error mesajı
            if let error = auth.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Butonlar
            VStack(spacing: 10) {
                Button {
                    Task {
                        if isSignUp {
                            guard password == confirmPassword else {
                                auth.errorMessage = "Şifreler eşleşmiyor"
                                return
                            }
                            await auth.signUp(
                                email: email,
                                password: password,
                                displayName: displayName
                            )
                        } else {
                            await auth.signIn(email: email, password: password)
                        }

                        if auth.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    if auth.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(isSignUp ? "Kayıt Ol" : "Giriş Yap")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                // Apple Sign In
                Divider()

                Button {
                    // Apple Sign In flow
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Apple ile Devam Et")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Toggle sign up / sign in
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        auth.errorMessage = nil
                    }
                } label: {
                    Text(isSignUp ? "Zaten hesabım var → Giriş Yap" : "Hesabım yok → Kayıt Ol")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                // Şifremi unuttum
                if !isSignUp {
                    Button {
                        Task {
                            await auth.resetPassword(email: email)
                        }
                    } label: {
                        Text("Şifremi Unuttum")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(email.isEmpty)
                }
            }
        }
        .padding(32)
        .frame(width: 360)
    }
}
