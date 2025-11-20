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

    /// UserDefaults instance
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Check if user has seen welcome screen
        let hasSeenWelcome = userDefaults.bool(forKey: hasSeenWelcomeKey)
        self.shouldShowWelcome = !hasSeenWelcome

        // Restore last selected tab
        let savedTab = userDefaults.integer(forKey: lastSelectedTabKey)
        self.selectedTab = savedTab

        // Restore last conversation ID
        self.lastConversationId = userDefaults.string(forKey: lastConversationIdKey)
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

    /// Dismiss the welcome screen and mark it as seen
    func dismissWelcome() {
        shouldShowWelcome = false
        userDefaults.set(true, forKey: hasSeenWelcomeKey)
    }

    /// Navigate to a new conversation
    func startNewConversation() {
        // Switch to chat tab and clear navigation path
        selectedTab = 0
        popToRoot()

        // Generate new conversation ID
        let newConversationId = UUID().uuidString
        saveLastConversationId(newConversationId)

        // Navigate to new chat
        navigate(to: .chat(conversationId: newConversationId))
    }

    /// Navigate to a specific conversation
    /// - Parameter conversationId: The ID of the conversation to open
    func openConversation(_ conversationId: String) {
        // Switch to chat tab
        selectedTab = 0

        // Navigate to specific conversation
        navigate(to: .chat(conversationId: conversationId))
    }

    // MARK: - State Persistence

    /// Save the currently selected tab
    func saveSelectedTab(_ tab: Int) {
        selectedTab = tab
        userDefaults.set(tab, forKey: lastSelectedTabKey)
    }

    /// Save the last accessed conversation ID
    private func saveLastConversationId(_ conversationId: String) {
        lastConversationId = conversationId
        userDefaults.set(conversationId, forKey: lastConversationIdKey)
    }

    /// Clear saved state (useful for testing or logout)
    func clearSavedState() {
        userDefaults.removeObject(forKey: lastSelectedTabKey)
        userDefaults.removeObject(forKey: lastConversationIdKey)
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
