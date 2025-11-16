//
//  LoadingView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A reusable loading view with various styles
struct LoadingView: View {
    let message: String
    let style: LoadingStyle

    init(message: String = "Loading...", style: LoadingStyle = .standard) {
        self.message = message
        self.style = style
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            switch style {
            case .standard:
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))

            case .spinner:
                SpinnerView()

            case .pulsing:
                PulsingCircleView()
            }

            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }

    enum LoadingStyle {
        case standard
        case spinner
        case pulsing
    }
}

/// A custom spinner view with rotation animation
struct SpinnerView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AppTheme.Colors.primary,
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
            .accessibilityHidden(true)
    }
}

/// A pulsing circle loading indicator
struct PulsingCircleView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.primary.opacity(0.3))
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .opacity(opacity)

            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: 30, height: 30)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                scale = 1.5
                opacity = 0
            }
        }
        .accessibilityHidden(true)
    }
}

/// An inline loading indicator for smaller spaces
struct InlineLoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))

            Text(message)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// A fullscreen loading overlay
struct LoadingOverlay: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.md) {
                SpinnerView()

                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white)
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// A skeleton loading view for content placeholders
struct SkeletonLoadingView: View {
    @State private var animating = false

    let height: CGFloat
    let cornerRadius: CGFloat

    init(height: CGFloat = 60, cornerRadius: CGFloat = 8) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray6),
                        Color(.systemGray5)
                    ]),
                    startPoint: animating ? .leading : .trailing,
                    endPoint: animating ? .trailing : .leading
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    animating.toggle()
                }
            }
            .accessibilityHidden(true)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .previewDisplayName("Standard Loading")

            LoadingView(message: "Please wait...", style: .spinner)
                .previewDisplayName("Spinner Loading")

            LoadingView(message: "Processing...", style: .pulsing)
                .previewDisplayName("Pulsing Loading")

            InlineLoadingView(message: "Syncing...")
                .previewDisplayName("Inline Loading")

            ZStack {
                Color.gray.ignoresSafeArea()
                LoadingOverlay(message: "Sending message...")
            }
            .previewDisplayName("Loading Overlay")

            VStack(spacing: 12) {
                SkeletonLoadingView()
                SkeletonLoadingView(height: 80)
                SkeletonLoadingView(height: 100)
            }
            .padding()
            .previewDisplayName("Skeleton Loading")
        }
    }
}
