//
//  StartupRestoreView.swift
//  ShamelaGPT
//

import SwiftUI

struct StartupRestoreView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var quoteIndex: Int = 0

    private let quotes = [
        LocalizationKeys.startupQuote1.localizedKey,
        LocalizationKeys.startupQuote2.localizedKey,
        LocalizationKeys.startupQuote3.localizedKey
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.Brand.emerald,
                    DesignSystem.Brand.teal,
                    DesignSystem.Brand.cyan
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .accessibilityHidden(true)

                Text(LocalizationKeys.startupRestoringTitle.localizedKey)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(quotes[quoteIndex])
                    .id(quoteIndex)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(Color.white.opacity(colorScheme == .dark ? 0.94 : 0.98))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)

                Text(LocalizationKeys.startupRestoringMessage.localizedKey)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(LocalizationKeys.startupRestoringTitle.localizedKey). \(quotes[quoteIndex])")
            .accessibilityAddTraits(.updatesFrequently)
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 2_800_000_000)
                } catch {
                    break
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    quoteIndex = (quoteIndex + 1) % quotes.count
                }
            }
        }
    }
}

#Preview {
    StartupRestoreView()
}
