//
//  AppCoordinator.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI
import UIKit

/// Coordinates navigation throughout the app using the Coordinator pattern
class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Navigation routes stack for programmatic navigation (iOS 15 compatible)
    @Published var navigationRoutes: [AppRoute] = []

    /// Determines whether to show the welcome screen
    @Published var shouldShowWelcome: Bool

    /// Currently selected tab in MainTabView
    @Published var selectedTab: Int = 0

    // MARK: - Private Properties

    /// UserDefaults key for first launch tracking
    private let hasSeenWelcomeKey = "hasSeenWelcome"

    /// UserDefaults key for last selected tab
    private let lastSelectedTabKey = "lastSelectedTab"

    /// UserDefaults instance
    private let userDefaults: UserDefaults
    private let chatSessionState: ChatSessionState

    // MARK: - Initialization

    init(
        userDefaults: UserDefaults = .standard,
        chatSessionState: ChatSessionState,
        shouldShowWelcome: Bool = true,
        initialSelectedTab: Int? = nil
    ) {
        self.userDefaults = userDefaults
        self.chatSessionState = chatSessionState

        self.shouldShowWelcome = shouldShowWelcome

        // Restore last selected tab if present, but ensure initial first tab is always Chat (index 0).
        // This prevents RTL/layout mirroring from causing a different tab to appear selected on first load.
        if let initialSelectedTab {
            self.selectedTab = initialSelectedTab
            userDefaults.set(initialSelectedTab, forKey: lastSelectedTabKey)
            AppLogger.app.logInfo("Initial selectedTab override=\(initialSelectedTab)")
        } else if userDefaults.object(forKey: lastSelectedTabKey) != nil {
            let savedTab = userDefaults.integer(forKey: lastSelectedTabKey)
            self.selectedTab = savedTab
            AppLogger.app.logInfo("Restored previously saved selectedTab=\(savedTab)")
        } else {
            self.selectedTab = 0
            AppLogger.app.logInfo("No saved tab found; defaulting selectedTab to Chat (0)")
        }
    }

    // MARK: - Navigation Methods

    /// Start the app with the appropriate initial route
    @MainActor func start() {
        if shouldShowWelcome {
            // First launch - show welcome screen
            navigate(to: .welcome)
        } else {
            // Returning user - restore previous state or go to chat
            restorePreviousState()
        }
    }

    /// Navigate to a specific route
    /// - Parameter route: The destination route
    @MainActor func navigate(to route: AppRoute) {
        switch route {
        case .welcome:
            // Welcome is handled by shouldShowWelcome state
            break

        case .chat(let conversationId):
            // Navigate to chat with optional conversation ID
            navigationRoutes.append(route)
            if let conversationId = conversationId {
                chatSessionState.set(.existing(id: conversationId))
            }

        case .history:
            // Switch to history tab
            selectedTab = 1

        case .settings:
            // Switch to settings tab
            selectedTab = 2

        case .languageSelection, .about, .privacyPolicy, .termsOfService:
            // These are sub-routes, handled by navigation in their respective tabs
            navigationRoutes.append(route)
        }
    }

    /// Pop the last view from the navigation stack
    func pop() {
        if !navigationRoutes.isEmpty {
            navigationRoutes.removeLast()
        }
    }

    /// Pop to the root view of the current navigation stack
    func popToRoot() {
        navigationRoutes.removeAll()
    }

    /// Dismiss the welcome screen
    func dismissWelcome() {
        shouldShowWelcome = false
        resetTabSelectionToChat()
        // No longer saving to UserDefaults as we want to show it every time if not logged in
    }

    /// Navigate to a new conversation
    @MainActor func startNewConversation() {
        // Switch to chat tab and clear navigation path
        selectedTab = 0
        popToRoot()

        chatSessionState.resetToNew()

        // Navigate to chat without pre-creating a conversation
        navigate(to: .chat(conversationId: nil))
    }

    /// Navigate to a specific conversation
    /// - Parameter conversationId: The ID of the conversation to open
    @MainActor func openConversation(_ conversationId: String) {
        // Switch to chat tab
        selectedTab = 0

        // Persist and publish the selected conversation immediately so listeners (MainTabView) can react
        chatSessionState.set(.existing(id: conversationId))
        AppLogger.app.logInfo("Coordinator openConversation -> conversationId=\(conversationId)")

        // Navigate to specific conversation
        navigate(to: .chat(conversationId: conversationId))
    }

    // MARK: - State Persistence

    /// Save the currently selected tab
    func saveSelectedTab(_ tab: Int) {
        selectedTab = tab
        userDefaults.set(tab, forKey: lastSelectedTabKey)
    }

    /// Force the selected tab back to Chat and persist that choice.
    func resetTabSelectionToChat() {
        selectedTab = 0
        userDefaults.set(0, forKey: lastSelectedTabKey)
    }

    /// Clear saved state (useful for testing or logout)
    @MainActor func clearSavedState() {
        userDefaults.removeObject(forKey: lastSelectedTabKey)
        selectedTab = 0
        chatSessionState.resetToNew()
    }

    /// Restore previous app state
    private func restorePreviousState() {
        // Tab selection is already restored in init
        // Additional restoration logic can be added here if needed
    }

    // MARK: - Deep Linking Support

    /// Handle a deep link URL
    /// - Parameter url: The URL to handle
    /// - Returns: Whether the URL was handled successfully
    @MainActor func handleDeepLink(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        // Support both custom scheme (shamelagpt://) and universal links (https://shamelagpt.com/...)
        let scheme = components.scheme?.lowercased()

        if scheme == "shamelagpt" {
            // Handle custom URL scheme like shamelagpt://chat?id=...
            switch components.host {
            case "chat":
                if let conversationId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                    openConversation(conversationId)
                } else {
                    startNewConversation()
                }
                return true

            case "history":
                navigate(to: .history)
                return true

            case "settings":
                navigate(to: .settings)
                return true

            case "factcheck":
                if let payload = FactCheckImportManager.shared.ingestFromPasteboard() {
                    FactCheckImportManager.shared.setPending(payload)
                    resetTabSelectionToChat()
                    startNewConversation()
                    NotificationCenter.default.post(name: .importFactCheckPayload, object: nil)
                    return true
                }
                AppLogger.app.logWarning("Fact-check deep link received but no payload found in pasteboard")
                return false

            default:
                return false
            }
        }

        if scheme == "https" || scheme == "http" {
            // Handle universal links for shamelagpt.com and www.shamelagpt.com
            guard let host = components.host?.lowercased(), host == "shamelagpt.com" || host == "www.shamelagpt.com" else {
                return false
            }

            let path = components.path.lowercased()

            if path.hasPrefix("/chat") {
                if let conversationId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                    openConversation(conversationId)
                } else {
                    startNewConversation()
                }
                return true
            }

            if path.hasPrefix("/history") {
                navigate(to: .history)
                return true
            }

            if path.hasPrefix("/settings") {
                navigate(to: .settings)
                return true
            }

            return false
        }

        return false
    }
}

// MARK: - Fact-check handoff helpers

struct FactCheckPayload: Equatable {
    let text: String?
    let detectedLanguage: String?
    let imageData: Data?
}

private struct FactCheckTransferPayload: Codable {
    let text: String
    let detectedLanguage: String?
    let imageDataBase64: String?
}

final class FactCheckImportManager {
    static let shared = FactCheckImportManager()
    private init() {}

    private let pasteboardType = "com.shamelagpt.factcheck"
    private var pendingPayload: FactCheckPayload?

    func setPending(_ payload: FactCheckPayload) {
        pendingPayload = payload
    }

    func consume() -> FactCheckPayload? {
        defer { pendingPayload = nil }
        return pendingPayload
    }

    func ingestFromPasteboard() -> FactCheckPayload? {
        let pasteboard = UIPasteboard.general
        guard let data = pasteboard.data(forPasteboardType: pasteboardType) else { return nil }
        guard let transfer = try? JSONDecoder().decode(FactCheckTransferPayload.self, from: data) else { return nil }

        let imageData = transfer.imageDataBase64.flatMap { Data(base64Encoded: $0) }
        let trimmed = transfer.text.trimmingCharacters(in: .whitespacesAndNewlines)

        return FactCheckPayload(
            text: trimmed.isEmpty ? nil : trimmed,
            detectedLanguage: transfer.detectedLanguage,
            imageData: imageData
        )
    }
}

extension Notification.Name {
    static let importFactCheckPayload = Notification.Name("importFactCheckPayload")
}
