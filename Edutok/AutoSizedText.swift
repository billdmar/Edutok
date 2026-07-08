/// General-purpose auto-sizing text component that fits content within given bounds.
import SwiftUI
import Foundation

struct AutoSizedText: View {
    let text: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let fontWeight: Font.Weight
    let color: Color

    @State private var fontSize: CGFloat = 20

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxWidth)
            .onAppear {
                calculateOptimalFontSize()
            }
            .onChange(of: text) { _, _ in
                calculateOptimalFontSize()
            }
    }

    private func calculateOptimalFontSize() {
        let maxFontSize: CGFloat = 32
        let minFontSize: CGFloat = 8
        var bestSize: CGFloat = minFontSize

        // Binary search for the optimal font size
        var low: CGFloat = minFontSize
        var high: CGFloat = maxFontSize

        while high - low > 0.5 {
            let mid = (low + high) / 2
            let textSize = measureText(fontSize: mid)

            if textSize.width <= maxWidth && textSize.height <= maxHeight {
                bestSize = mid
                low = mid
            } else {
                high = mid - 0.5
            }
        }

        // Final verification and adjustment
        var finalSize = bestSize
        while finalSize > minFontSize {
            let testSize = measureText(fontSize: finalSize)
            if testSize.width <= maxWidth && testSize.height <= maxHeight {
                break
            }
            finalSize -= 0.5
        }

        fontSize = max(finalSize, minFontSize)
    }

    private func measureText(fontSize: CGFloat) -> CGSize {
        let font = UIFont.systemFont(ofSize: fontSize, weight: uiFontWeight(from: fontWeight))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Use a slightly smaller width for measurement to account for padding
        let constraintWidth = maxWidth - 4
        let constraintSize = CGSize(width: constraintWidth, height: CGFloat.greatestFiniteMagnitude)

        let boundingRect = attributedString.boundingRect(
            with: constraintSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        // Add small buffer to ensure no truncation
        return CGSize(
            width: ceil(boundingRect.width) + 2,
            height: ceil(boundingRect.height) + 2
        )
    }

    private func uiFontWeight(from fontWeight: Font.Weight) -> UIFont.Weight {
        switch fontWeight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
