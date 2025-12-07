//
//  RTLModifier.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

// MARK: - RTL Support Utilities

/// View modifier that applies RTL layout based on the current language
struct RTLModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, layoutDirection)
    }
}

/// Extension to easily apply RTL support to any view
extension View {
    /// Applies RTL layout support
    func supportRTL() -> some View {
        modifier(RTLModifier())
    }

    /// Mirrors the view horizontally in RTL mode
    func mirrorInRTL() -> some View {
        modifier(MirrorInRTLModifier())
    }

    /// Flips alignment from leading/trailing in RTL mode
    func flippedInRTL() -> some View {
        modifier(FlippedInRTLModifier())
    }
}

/// Modifier that mirrors views in RTL mode (useful for asymmetric icons)
struct MirrorInRTLModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        if layoutDirection == .rightToLeft {
            content.scaleEffect(x: -1, y: 1, anchor: .center)
        } else {
            content
        }
    }
}

/// Modifier that flips layout direction
struct FlippedInRTLModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, layoutDirection == .leftToRight ? .rightToLeft : .leftToRight)
    }
}

// MARK: - RTL-Aware Alignment

extension HorizontalAlignment {
    /// Returns leading in LTR and trailing in RTL
    static func leadingRTL(layoutDirection: LayoutDirection) -> HorizontalAlignment {
        layoutDirection == .leftToRight ? .leading : .trailing
    }

    /// Returns trailing in LTR and leading in RTL
    static func trailingRTL(layoutDirection: LayoutDirection) -> HorizontalAlignment {
        layoutDirection == .leftToRight ? .trailing : .leading
    }
}

// MARK: - Language Detection Utilities

extension String {
    /// Checks if the string contains primarily Arabic characters
    var isArabic: Bool {
        let arabicPattern = "[\u{0600}-\u{06FF}\u{0750}-\u{077F}\u{08A0}-\u{08FF}\u{FB50}-\u{FDFF}\u{FE70}-\u{FEFF}]"
        return range(of: arabicPattern, options: .regularExpression) != nil
    }

    /// Determines the natural layout direction for the string
    var naturalLayoutDirection: LayoutDirection {
        isArabic ? .rightToLeft : .leftToRight
    }
}

// MARK: - RTL-Aware Padding

extension View {
    /// Applies padding on the leading edge (automatically flips in RTL)
    func paddingLeading(_ length: CGFloat) -> some View {
        padding(.leading, length)
    }

    /// Applies padding on the trailing edge (automatically flips in RTL)
    func paddingTrailing(_ length: CGFloat) -> some View {
        padding(.trailing, length)
    }
}

// MARK: - Bidirectional Text Support

/// A view that properly displays bidirectional text
struct BidirectionalText: View {
    let text: String
    var font: Font = .body
    var foregroundColor: Color = .primary
    var alignment: TextAlignment = .leading

    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(effectiveAlignment)
            .environment(\.layoutDirection, text.naturalLayoutDirection)
    }

    private var effectiveAlignment: TextAlignment {
        if text.isArabic && layoutDirection == .rightToLeft {
            return .trailing
        } else if text.isArabic {
            return .leading
        }
        return alignment
    }
}

struct RTLModifier_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("English Text - Left to Right")
                .font(.title)

            Text("النص العربي - من اليمين إلى اليسار")
                .font(.title)
                .environment(\.layoutDirection, .rightToLeft)

            BidirectionalText(
                text: "مرحبا بك في ShamelaGPT",
                font: .title,
                foregroundColor: .primary
            )

            HStack {
                Image(systemName: "arrow.right")
                    .mirrorInRTL()
                Text("Arrow mirrors in RTL")
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding()
        .previewDisplayName("RTL Text")
    }
}
