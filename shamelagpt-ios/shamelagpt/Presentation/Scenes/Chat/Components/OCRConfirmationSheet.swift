//
//  OCRConfirmationSheet.swift
//  ShamelaGPT
//
//  Created by Auto-Agent on 05/12/2025.
//

import SwiftUI

struct OCRConfirmationSheet: View {
    @Binding var text: String
    let imageData: Data?
    let detectedLanguage: String?
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()

            NavigationView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Image Preview
                            if let data = imageData, let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(DesignSystem.Layout.cornerRadiusLarge)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
                                            .stroke(DesignSystem.Colors.border(colorScheme), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                if let detectedLanguage {
                                    Text("Detected language: \(detectedLanguage)")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                                }

                                Text("Extracted Text")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))

                                Text("Edit the text below if needed before sending.")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary(colorScheme))

                                TextEditor(text: $text)
                                    .font(AppTheme.Typography.body)
                                    .frame(minHeight: 150)
                                    .padding(AppTheme.Spacing.xs)
                                    .background(DesignSystem.Colors.inputBackground(colorScheme))
                                    .cornerRadius(DesignSystem.Layout.cornerRadiusLarge)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadiusLarge)
                                            .stroke(DesignSystem.Colors.border(colorScheme), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }

                    // Action Buttons
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Button(action: {
                            onConfirm(text)
                        }) {
                            Text(LocalizationKeys.sendForFactCheck.localizedKey)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button(action: onCancel) {
                            Text(LocalizationKeys.cancel.localizedKey)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(AppTheme.Spacing.lg)
                }
                .navigationTitle("Confirm Text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(LocalizationKeys.cancel.localizedKey) {
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(LocalizationKeys.done.localizedKey) {
                            onConfirm(text)
                        }
                        .font(AppTheme.Typography.body.weight(.bold))
                    }
                }
            }
        }
    }
}
