/// DesignSystem.swift
///
/// Centralized brand palette, semantic color tokens, and reusable button styles.
/// Edutok is intentionally dark-only (see `App.preferredColorScheme(.dark)`), so the
/// tokens below are tuned for a dark surface and chosen to meet WCAG AA contrast for
/// body text.
import SwiftUI

/// Brand colors and semantic tokens. Use `Theme` instead of scattering
/// `Color.purple.opacity(...)` literals so the palette can change in one place.
enum Theme {
    // Brand palette.
    static let purple = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let pink = Color(red: 0.9, green: 0.4, blue: 0.6)
    static let blue = Color(red: 0.3, green: 0.6, blue: 0.9)

    // Semantic tokens (dark surface).
    static let accent = pink
    /// Primary body text on a dark background.
    static let textPrimary = Color.white
    /// Secondary text — ~70% white meets WCAG AA (>4.5:1) on the near-black surface.
    static let textSecondary = Color.white.opacity(0.7)
    /// Tertiary/caption text — use sparingly; large text only.
    static let textTertiary = Color.white.opacity(0.55)

    /// The signature brand gradient (top-leading → bottom-trailing).
    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [purple, pink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// A filled, gradient capsule button with a press-scale effect — the app's primary CTA.
struct PrimaryButtonStyle: ButtonStyle {
    var colors: [Color] = [Theme.pink, Theme.purple]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(gradient: Gradient(colors: colors),
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: colors.first?.opacity(0.45) ?? .clear, radius: 16, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A subtle translucent "chip"/secondary button used for tags and inline actions.
struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
