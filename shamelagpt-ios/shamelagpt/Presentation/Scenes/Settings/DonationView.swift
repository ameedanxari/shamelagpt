//
//  DonationView.swift
//  ShamelaGPT
//

import StoreKit
import SwiftUI

struct DonationView: View {
    @StateObject private var viewModel = DonationViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    headerSection
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, DesignSystem.Spacing.xl)
                    } else if viewModel.products.isEmpty {
                        emptyState
                    } else {
                        productsSection
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(DesignSystem.Colors.error)
                            .font(DesignSystem.Typography.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    footerSection
                }
                .padding()
            }
            .background(DesignSystem.Colors.background(colorScheme).ignoresSafeArea())
            .navigationTitle(LocalizationKeys.donateSheetTitle.localizedKey)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationKeys.cancel.localizedKey) { dismiss() }
                }
            }
            .alert(LocalizationKeys.donateSuccessTitle.localizedKey, isPresented: $viewModel.purchaseSuccess) {
                Button(LocalizationKeys.done.localizedKey) { dismiss() }
            } message: {
                Text(LocalizationKeys.donateSuccessMessage.localizedKey)
            }
            .task { viewModel.loadProducts() }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text(LocalizationKeys.donateSheetTitle.localizedKey)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)

            Text(LocalizationKeys.donateSheetSubtitle.localizedKey)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.md)
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(viewModel.products, id: \.productIdentifier) { product in
                DonationTierRow(
                    product: product,
                    isPurchasing: viewModel.isPurchasing
                ) {
                    viewModel.purchase(product)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text(LocalizationKeys.donateLoadFailed.localizedKey)
            .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
            .font(DesignSystem.Typography.subheadline)
            .multilineTextAlignment(.center)
            .padding()
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(LocalizationKeys.donateFooter.localizedKey)
                .font(DesignSystem.Typography.footnote)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)

            Button(LocalizationKeys.donateRestore.localizedKey) {
                viewModel.restorePurchases()
            }
            .font(DesignSystem.Typography.footnote)
            .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
        }
        .padding(.bottom, DesignSystem.Spacing.md)
    }
}

// MARK: - Tier Row

private struct DonationTierRow: View {
    let product: SKProduct
    let isPurchasing: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.localizedTitle)
                        .font(DesignSystem.Typography.body.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                    Text(product.localizedDescription)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.localizedPrice)
                        .font(DesignSystem.Typography.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(AppTheme.Layout.cornerRadius)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface(colorScheme))
            .cornerRadius(AppTheme.Layout.cornerRadius)
        }
        .disabled(isPurchasing)
        .accessibilityIdentifier("donationTier_\(product.productIdentifier)")
    }
}

// MARK: - SKProduct price helper

private extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
}
