//
//  TypingIndicatorView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A view that displays an animated typing indicator (three bouncing dots)
struct TypingIndicatorView: View {

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
            .background(AppTheme.Colors.aiMessageBackground)
            .cornerRadius(AppTheme.Layout.messageBubbleRadius)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xxs)
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

// MARK: - Preview Provider

#Preview {
    VStack {
        Spacer()
        TypingIndicatorView()
        Spacer()
    }
    .background(AppTheme.Colors.background)
}

#Preview("In Chat Context") {
    VStack {
        MessageBubbleView(message: Message.preview)
        TypingIndicatorView()
        Spacer()
    }
    .background(AppTheme.Colors.background)
}
