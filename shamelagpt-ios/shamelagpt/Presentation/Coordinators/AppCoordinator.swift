//
//  AppCoordinator.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// Coordinates navigation throughout the app using the Coordinator pattern
class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Navigation routes stack for programmatic navigation (iOS 15 compatible)
    @Published var navigationRoutes: [AppRoute] = []

    /// Determines whether to show the welcome screen
    @Published var shouldShowWelcome: Bool

    /// Currently selected tab in MainTabView
    @Published var selectedTab: Int = 0

    /// Last accessed conversation ID (for state restoration)
    @Published var lastConversationId: String?

    // MARK: - Private Properties

    /// UserDefaults key for first launch tracking
    private let hasSeenWelcomeKey = "hasSeenWelcome"

    /// UserDefaults key for last selected tab
    private let lastSelectedTabKey = "lastSelectedTab"

    /// UserDefaults key for last conversation
    private let lastConversationIdKey = "lastConversationId"
    /// UserDefaults key for guest conversation id
    private let guestConversationIdKey = "guest_conversation_id"

    /// UserDefaults instance
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Welcome screen state is now controlled by the App struct based on auth state
        // defaulting to false here, but will be overridden or ignored by ShamelaGPTApp
        self.shouldShowWelcome = true

        // Restore last selected tab if present, but ensure initial first tab is always Chat (index 0).
        // This prevents RTL/layout mirroring from causing a different tab to appear selected on first load.
        if userDefaults.object(forKey: lastSelectedTabKey) != nil {
            let savedTab = userDefaults.integer(forKey: lastSelectedTabKey)
            self.selectedTab = savedTab
            AppLogger.app.logInfo("Restored previously saved selectedTab=\(savedTab)")
        } else {
            self.selectedTab = 0
            AppLogger.app.logInfo("No saved tab found; defaulting selectedTab to Chat (0)")
        }

        // Restore last conversation ID (support guest persisted conversation)
        if userDefaults.bool(forKey: "is_guest") {
            self.lastConversationId = userDefaults.string(forKey: guestConversationIdKey)
        } else {
            self.lastConversationId = userDefaults.string(forKey: lastConversationIdKey)
        }
    }

    // MARK: - Navigation Methods

    /// Start the app with the appropriate initial route
    func start() {
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
    func navigate(to route: AppRoute) {
        switch route {
        case .welcome:
            // Welcome is handled by shouldShowWelcome state
            break

        case .chat(let conversationId):
            // Navigate to chat with optional conversation ID
            navigationRoutes.append(route)
            if let conversationId = conversationId {
                saveLastConversationId(conversationId)
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
    func startNewConversation() {
        // Switch to chat tab and clear navigation path
        selectedTab = 0
        popToRoot()

        clearLastConversationId()

        // Navigate to chat without pre-creating a conversation
        navigate(to: .chat(conversationId: nil))
    }

    /// Navigate to a specific conversation
    /// - Parameter conversationId: The ID of the conversation to open
    func openConversation(_ conversationId: String) {
        // Switch to chat tab
        selectedTab = 0

        // Persist and publish the selected conversation immediately so listeners (MainTabView) can react
        saveLastConversationId(conversationId)
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

    /// Save the last accessed conversation ID
    func saveLastConversationId(_ conversationId: String) {
        lastConversationId = conversationId
        // Persist to guest key if guest, otherwise persist as normal
        if userDefaults.bool(forKey: "is_guest") {
            userDefaults.set(conversationId, forKey: guestConversationIdKey)
        } else {
            userDefaults.set(conversationId, forKey: lastConversationIdKey)
        }
    }

    /// Clear the persisted last conversation ID
    func clearLastConversationId() {
        lastConversationId = nil
        if userDefaults.bool(forKey: "is_guest") {
            userDefaults.removeObject(forKey: guestConversationIdKey)
        } else {
            userDefaults.removeObject(forKey: lastConversationIdKey)
        }
    }

    /// Clear saved state (useful for testing or logout)
    func clearSavedState() {
        userDefaults.removeObject(forKey: lastSelectedTabKey)
        userDefaults.removeObject(forKey: lastConversationIdKey)
        userDefaults.removeObject(forKey: guestConversationIdKey)
        selectedTab = 0
        lastConversationId = nil
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
    func handleDeepLink(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        // Handle shamelagpt:// scheme
        guard components.scheme == "shamelagpt" else {
            return false
        }

        switch components.host {
        case "chat":
            // Handle shamelagpt://chat or shamelagpt://chat?id=<conversationId>
            if let queryItems = components.queryItems,
               let conversationId = queryItems.first(where: { $0.name == "id" })?.value {
                openConversation(conversationId)
            } else {
                startNewConversation()
            }
            return true

        case "history":
            // Handle shamelagpt://history
            navigate(to: .history)
            return true

        case "settings":
            // Handle shamelagpt://settings
            navigate(to: .settings)
            return true

        default:
            return false
        }
    }
}
