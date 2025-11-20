//
//  ShamelaGPTApp.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 04/11/2025.
//

import SwiftUI

@main
struct ShamelaGPTApp: App {
    // MARK: - Properties

    /// App coordinator for navigation management
    @StateObject private var coordinator = AppCoordinator()

    /// Dependency container
    private let container = DependencyContainer.shared

    // MARK: - Initialization

    init() {
        // Initialize dependency container
        _ = DependencyContainer.shared
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main tab view
                MainTabView(
                    coordinator: coordinator,
                    container: container
                )

                // Welcome overlay for first launch
                if coordinator.shouldShowWelcome {
                    WelcomeView(coordinator: coordinator)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.none) // Support both light and dark mode
            .onOpenURL { url in
                // Handle deep links
                _ = coordinator.handleDeepLink(url)
            }
            .onAppear {
                coordinator.start()
            }
        }
    }
}
