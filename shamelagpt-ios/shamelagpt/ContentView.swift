//
//  ContentView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "book.circle.fill")
                .resizable()
                .frame(width: AppTheme.Layout.largeIconSize, height: AppTheme.Layout.largeIconSize)
                .foregroundColor(AppTheme.Colors.primary)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("ShamelaGPT")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Text("AI-Powered Islamic Knowledge")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            Text("Project structure initialized successfully!")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.accent)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background(colorScheme))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
