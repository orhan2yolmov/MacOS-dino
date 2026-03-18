// Theme.swift
// MacOS-Dino – Tema & Stil Sabitleri
// Koyu tema, Liquid Glass uyumlu renkler

import SwiftUI

// MARK: - Color Theme

extension Color {
    // Ana renkler
    static let dinoBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
    static let dinoPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    static let dinoPink = Color(red: 0.9, green: 0.3, blue: 0.6)
    static let dinoGreen = Color(red: 0.2, green: 0.8, blue: 0.5)

    // Arka plan katmanları
    static let dinoBgPrimary = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let dinoBgSecondary = Color(red: 0.11, green: 0.12, blue: 0.18)
    static let dinoBgTertiary = Color(red: 0.14, green: 0.15, blue: 0.22)

    // Sidebar
    static let dinoSidebar = Color(red: 0.06, green: 0.07, blue: 0.12)

    // Kenar
    static let dinoBorder = Color.white.opacity(0.08)
    static let dinoActiveBorder = Color.blue.opacity(0.5)
}

// MARK: - Style Constants

enum DinoStyle {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 20

    // Animasyon
    static let quickAnimation: Animation = .spring(duration: 0.2)
    static let smoothAnimation: Animation = .spring(duration: 0.4, bounce: 0.15)
    static let slowAnimation: Animation = .easeInOut(duration: 0.6)
}

// MARK: - Glass Effect Modifier

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = DinoStyle.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            }
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = DinoStyle.cornerRadius) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
