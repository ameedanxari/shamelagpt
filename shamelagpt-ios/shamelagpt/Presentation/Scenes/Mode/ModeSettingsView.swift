//
//  ModeSettingsView.swift
//  ShamelaGPT
//
//  Settings entry point for changing conversation mode after onboarding.
//

import SwiftUI

/// Wraps `ModeSelectionView` for use from Settings.
///
/// Loads the current mode first so the picker opens on what is actually in effect rather
/// than a guess — the server is the source of truth and the app keeps no local copy.
struct ModeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ModeSelectionViewModel?
    @State private var loadFailed = false

    private let authRepository: AuthRepository? = DependencyContainer.shared.resolve(AuthRepository.self)

    var body: some View {
        Group {
            if let viewModel {
                ModeSelectionView(
                    viewModel: viewModel,
                    isGuest: false,
                    onComplete: { mode in
                        dismiss()
                        // Same reasoning as the onboarding gate: choosing Fact Check must
                        // land the user in claim capture, not just store a number.
                        if mode == .factCheck {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                NotificationCenter.default.post(name: .startFactCheckCapture, object: nil)
                            }
                        }
                    }
                )
            } else if loadFailed {
                VStack(spacing: 12) {
                    Text(LocalizationKeys.preferencesLoadFailed.localizedKey)
                        .multilineTextAlignment(.center)
                    Button(LocalizationKeys.errorRetry.localizedKey) {
                        loadFailed = false
                        Task { await load() }
                    }
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard viewModel == nil, let authRepository else {
            loadFailed = authRepository == nil
            return
        }
        do {
            let current = try await authRepository.getModePreference()
            viewModel = ModeSelectionViewModel(authRepository: authRepository, initial: current)
        } catch {
            AppLogger.app.logWarning("could not load current mode for settings")
            loadFailed = true
        }
    }
}
