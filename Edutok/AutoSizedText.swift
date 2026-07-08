/// AutoSizedText.swift
///
/// Text component that automatically scales down to fit within given bounds.
/// Uses SwiftUI's native `.minimumScaleFactor` for zero-overhead layout-time
/// scaling — no manual text measurement or binary search required.
import SwiftUI

struct AutoSizedText: View {
    let text: String
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let fontWeight: Font.Weight
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 32, weight: fontWeight))
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .minimumScaleFactor(0.25)
            .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }
}
