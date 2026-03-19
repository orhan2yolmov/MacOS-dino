// LoginView.swift
// MacOS-Dino – Giriş / Kayıt Ekranı  (Modern Redesign)

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var animateGradient = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Animasyonlu gradient arka plan
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.05, blue: 0.22),
                    Color(red: 0.04, green: 0.08, blue: 0.18)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateGradient)
            .onAppear { animateGradient = true }

            // Arka dekoratif daireler
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 300, height: 300)
                .offset(x: -80, y: -100)
                .blur(radius: 60)

            Circle()
                .fill(Color.purple.opacity(0.10))
                .frame(width: 250, height: 250)
                .offset(x: 100, y: 120)
                .blur(radius: 50)

            // Ana kart
            VStack(spacing: 0) {
                // Logo alanı
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 64, height: 64)
                            .shadow(color: .blue.opacity(0.4), radius: 16)

                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    Text("MacOS-Dino")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(isSignUp ? "Yeni Hesap Oluştur" : "Hoş Geldin 👋")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 36)
                .padding(.bottom, 28)

                // Form
                VStack(spacing: 12) {
                    if isSignUp {
                        DinoTextField(
                            icon: "person.fill",
                            placeholder: "Ad Soyad",
                            text: $displayName
                        )
                    }

                    DinoTextField(
                        icon: "envelope.fill",
                        placeholder: "E-posta adresi",
                        text: $email
                    )

                    DinoSecureField(
                        icon: "lock.fill",
                        placeholder: "Şifre",
                        text: $password
                    )

                    if isSignUp {
                        DinoSecureField(
                            icon: "lock.fill",
                            placeholder: "Şifreyi Onayla",
                            text: $confirmPassword
                        )
                    }
                }
                .padding(.horizontal, 28)

                // Hata mesajı
                if let error = auth.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                }

                // Ana buton
                Button {
                    Task {
                        if isSignUp {
                            guard password == confirmPassword else {
                                auth.errorMessage = "Şifreler eşleşmiyor"
                                return
                            }
                            await auth.signUp(email: email, password: password, displayName: displayName)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                        if auth.isAuthenticated { dismiss() }
                    }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text(isSignUp ? "Kayıt Ol" : "Giriş Yap")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: email.isEmpty || password.isEmpty
                                ? [Color.white.opacity(0.1), Color.white.opacity(0.1)]
                                : [Color.blue, Color(red: 0.4, green: 0.2, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 28)
                .padding(.top, 16)

                // Ayırıcı
                HStack {
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                    Text("veya")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                    Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)

                // Apple Sign In
                Button {
                    // Apple Sign In flow
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 15, weight: .medium))
                        Text("Apple ile Devam Et")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)

                // Geçiş butonları
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            isSignUp.toggle()
                            auth.errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Zaten hesabın var mı? " + "Giriş Yap →" : "Hesabın yok mu? " + "Kayıt Ol →")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    if !isSignUp {
                        Button {
                            Task { await auth.resetPassword(email: email) }
                        } label: {
                            Text("Şifremi Unuttum")
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .disabled(email.isEmpty)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .frame(width: 380)
            .background(.ultraThinMaterial.opacity(0.6))
            .background(Color(red: 0.08, green: 0.09, blue: 0.16).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 40)
        }
        .frame(width: 480, height: isSignUp ? 640 : 560)
    }
}

// MARK: - Custom TextField Components

private struct DinoTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct DinoSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)

            if isVisible {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            } else {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

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
