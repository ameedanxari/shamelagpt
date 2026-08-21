//
//  MadhabPreferenceViewModel.swift
//  ShamelaGPT
//
//  Created by Codex on 21/08/2026.
//

import Foundation
import Combine

/// Owns the user's school-of-thought (madhhab) preference.
///
/// The server is the single source of truth — the same account can change this
/// on the web — so this view model never caches locally: it reads on appear and
/// writes through on every selection.
@MainActor
final class MadhabPreferenceViewModel: ObservableObject {

    /// The school currently applied on the server, as far as we know.
    @Published private(set) var selection: MadhabPreference = .all
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let authRepository: AuthRepository?
    private var hasLoaded = false

    init(authRepository: AuthRepository? = DependencyContainer.shared.resolve(AuthRepository.self)) {
        self.authRepository = authRepository
    }

    /// Whether the preference can be read/written at all. It is stored per
    /// account, so a guest has nothing to sync.
    var canEditPreference: Bool {
        guard let authRepository else { return false }
        return authRepository.isLoggedIn()
    }

    /// Loads the server value. Repeat calls are a no-op unless `force` is set,
    /// so re-entering Settings does not re-fetch on every appearance.
    func load(force: Bool = false) async {
        guard let authRepository else {
            AppLogger.app.logDebug("Skipping madhab preference load: auth repository unavailable")
            return
        }
        guard authRepository.isLoggedIn() else {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=madhabPreference.load.skipped reason=notAuthenticated"
            )
            return
        }
        guard force || !hasLoaded else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await authRepository.getMadhabPreference()
            selection = MadhabPreference.normalized(response.madhabPreference)
            hasLoaded = true
            errorMessage = nil
        } catch {
            AppLogger.app.logWarning("Failed to load madhab preference reason=\(type(of: error))")
            errorMessage = LanguageManager.shared.localizedString(forKey: LocalizationKeys.madhabLoadFailed)
        }
    }

    /// Persists `madhab` and adopts whatever the server echoes back.
    ///
    /// The UI is deliberately *not* updated optimistically: the selection only
    /// moves once the PUT succeeds. A failed write therefore leaves the picker
    /// showing the school that is actually applied server-side, rather than one
    /// the backend rejected.
    func select(_ madhab: MadhabPreference) async {
        guard let authRepository else {
            AppLogger.app.logDebug("Skipping madhab preference update: auth repository unavailable")
            return
        }
        guard authRepository.isLoggedIn() else {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=madhabPreference.update.skipped reason=notAuthenticated requested=\(madhab.rawValue)"
            )
            return
        }
        guard madhab != selection else { return }

        isSaving = true
        defer { isSaving = false }
        do {
            let response = try await authRepository.setMadhabPreference(
                MadhabPreferenceRequest(madhabPreference: madhab.rawValue)
            )
            selection = MadhabPreference.normalized(response.madhabPreference)
            hasLoaded = true
            errorMessage = nil
        } catch {
            AppLogger.app.logWarning("Failed to update madhab preference reason=\(type(of: error))")
            errorMessage = LanguageManager.shared.localizedString(forKey: LocalizationKeys.madhabUpdateFailed)
        }
    }
}
