//
//  TypingIndicatorView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A view that displays an animated typing indicator (three bouncing dots)
struct TypingIndicatorView: View {

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var animationPhase = 0

    // MARK: - Constants

    private let dotSize: CGFloat = 8
    private let animationDuration: Double = 0.6

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.xs) {
            // Indicator bubble
            HStack(spacing: AppTheme.Spacing.xxs) {
                ForEach(0..<3) { index in
                    dot(at: index)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(DesignSystem.Colors.surface(colorScheme))
            .cornerRadius(AppTheme.Layout.messageBubbleRadius)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .accessibilityIdentifier(AccessibilityID.Chat.typingIndicator)
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Subviews

    private func dot(at index: Int) -> some View {
        Circle()
            .fill(AppTheme.Colors.secondaryText)
            .frame(width: dotSize, height: dotSize)
            .offset(y: offsetForDot(at: index))
            .animation(
                Animation
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2),
                value: animationPhase
            )
    }

    // MARK: - Helpers

    private func offsetForDot(at index: Int) -> CGFloat {
        animationPhase == 1 ? -4 : 0
    }

    private func startAnimation() {
        withAnimation {
            animationPhase = 1
        }
    }
}

#if DEBUG
struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                Spacer()
                TypingIndicatorView()
                Spacer()
            }
            .background(DesignSystem.Colors.background(.light))

            VStack {
                MessageBubbleView(message: .preview)
                TypingIndicatorView()
                Spacer()
            }
            .background(AppTheme.Colors.background)
            .previewDisplayName("In Chat Context")
        }
    }
}
#endif
