//
//  ModeSelectionViewModel.swift
//  ShamelaGPT
//

import Foundation

/// Backs the mode picker and the one-time gate that shows it.
@MainActor
final class ModeSelectionViewModel: ObservableObject {
    @Published var selected: ConversationMode = .research
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository, initial: ConversationMode = .research) {
        self.authRepository = authRepository
        // `unset` is a server state, never a highlighted card; default the cursor to
        // research so the picker always opens on a valid choice.
        self.selected = initial == .unset ? .research : initial
    }

    func select(_ mode: ConversationMode) {
        errorMessage = nil
        selected = mode
    }

    /// Persists the choice, then hands control back to the caller.
    ///
    /// The mode lives only on the server — there is no per-message field — so if this call
    /// fails we must not pretend it succeeded, or the user would see one mode in the UI and
    /// get answers from another.
    func confirm(onComplete: @escaping (ConversationMode) -> Void) {
        guard !isSaving else { return }
        Task {
            isSaving = true
            errorMessage = nil
            do {
                try await authRepository.setModePreference(selected)
                isSaving = false
                AppLogger.auth.logInfo("mode preference saved: \(selected.rawValue)")
                onComplete(selected)
            } catch {
                isSaving = false
                AppLogger.auth.logError("failed to save mode preference", error: error)
                errorMessage = error.userFacingMessage
            }
        }
    }
}
