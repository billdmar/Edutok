/// FlashcardView-specific button styles and action components.
import SwiftUI

enum CardTransitionDirection {
    case none, fromTop, fromBottom
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .brightness(configuration.isPressed ? 0.2 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct HeartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// One of the on-card action buttons (Skip / Got it). Both shared the same ~85-line chrome
/// (gradient capsule + stroke + shadow + bounce-scale + 3D-flip sync) differing only in
/// icon/label/colors/effect/action — extracted here to remove that duplication.
struct CardActionButton: View {
    enum Effect { case bounce, pulse }

    let icon: String
    let label: String
    let symbolEffect: Effect
    let colors: [Color]
    let shadowColor: Color
    let isCurrentCard: Bool
    let showAnswer: Bool
    let cardRotation: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                symbol
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: Gradient(colors: colors),
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2))
                    .shadow(color: shadowColor.opacity(0.5), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(isCurrentCard ? 1.0 : 0.8)
        .buttonStyle(BouncyButtonStyle())
        .rotation3DEffect(
            .degrees(isCurrentCard && showAnswer ? -cardRotation : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .accessibilityLabel(label)
    }

    @ViewBuilder private var symbol: some View {
        let image = Image(systemName: icon).font(.title2).foregroundColor(.white)
        switch symbolEffect {
        case .bounce:
            image.symbolEffect(.bounce, options: .repeat(.continuous).speed(0.5))
        case .pulse:
            image.symbolEffect(.pulse, options: .repeat(.continuous).speed(0.7))
        }
    }
}
