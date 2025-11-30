//
//  MainTabView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// Main tab view container with three tabs: Chat, History, and Settings
struct MainTabView: View {

    // MARK: - Properties

    @ObservedObject var coordinator: AppCoordinator
    let container: DependencyContainer

    // MARK: - State

    @State private var currentConversationId: String?
    @State private var isInitialized = false
    @State private var needsValidation = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Chat Tab
            chatTab
                .tabItem {
                    Label(LocalizationKeys.chat.localized, systemImage: "message.fill")
                }
                .tag(0)
                .accessibilityLabel(LocalizationKeys.chat.localized)
                .accessibilityHint(LocalizationKeys.chatTabAccessibilityHint.localized)

            // History Tab
            historyTab
                .tabItem {
                    Label(LocalizationKeys.history.localized, systemImage: "clock.fill")
                }
                .tag(1)
                .accessibilityLabel(LocalizationKeys.history.localized)
                .accessibilityHint(LocalizationKeys.historyTabAccessibilityHint.localized)

            // Settings Tab
            settingsTab
                .tabItem {
                    Label(LocalizationKeys.settings.localized, systemImage: "gearshape.fill")
                }
                .tag(2)
                .accessibilityLabel(LocalizationKeys.settings.localized)
                .accessibilityHint(LocalizationKeys.settingsTabAccessibilityHint.localized)
        }
        .accentColor(AppTheme.Colors.primary)
        .onChange(of: coordinator.selectedTab) { newTab in
            withAnimation(AppTheme.Animation.standard) {
                coordinator.saveSelectedTab(newTab)
            }
        }
        .task {
            // Ensure we have a valid conversation on first launch
            await ensureConversationExists()
        }
    }

    // MARK: - Helper Methods

    /// Ensures a conversation exists for the chat tab
    /// Reuses existing empty conversation or creates a new one
    private func ensureConversationExists() async {
        guard !isInitialized else { return }
        isInitialized = true

        AppLogger.app.logInfo("Ensuring conversation exists for chat tab")

        do {
            guard let chatRepo = container.resolve(ChatRepository.self) else {
                AppLogger.app.logError("Failed to resolve ChatRepository from DependencyContainer")
                currentConversationId = UUID().uuidString
                return
            }

            // First, try to find an existing empty conversation
            if let emptyConversation = try await chatRepo.fetchMostRecentEmptyConversation() {
                AppLogger.app.logInfo("Reusing existing empty conversation: \(emptyConversation.id)")
                currentConversationId = emptyConversation.id
                coordinator.lastConversationId = emptyConversation.id
                return
            }

            // No empty conversation found, create a new one
            AppLogger.app.logInfo("No empty conversation found, creating new one")
            await createNewConversation()

        } catch {
            AppLogger.app.logError("Error checking for empty conversation", error: error)
            // Fallback to creating a new conversation
            await createNewConversation()
        }
    }

    /// Creates a new conversation in CoreData
    private func createNewConversation() async {
        AppLogger.app.logInfo("Creating new conversation in CoreData")

        do {
            guard let chatRepo = container.resolve(ChatRepository.self) else {
                AppLogger.app.logError("Failed to resolve ChatRepository from DependencyContainer")
                currentConversationId = UUID().uuidString
                return
            }

            let newConversation = try await chatRepo.createConversation(title: "New Conversation")
            currentConversationId = newConversation.id
            coordinator.lastConversationId = newConversation.id
            AppLogger.app.logInfo("Created new conversation: \(newConversation.id)")
        } catch {
            AppLogger.app.logError("Failed to create conversation", error: error)
            // Fallback to a random ID (will fail when trying to send messages, but at least app won't crash)
            currentConversationId = UUID().uuidString
        }
    }

    /// Creates or reuses an empty conversation when user taps "New Conversation"
    private func createOrReuseConversation() async {
        AppLogger.app.logInfo("User requested new conversation")

        do {
            guard let chatRepo = container.resolve(ChatRepository.self) else {
                AppLogger.app.logError("Failed to resolve ChatRepository from DependencyContainer")
                return
            }

            // Check if current conversation is already empty
            if let currentId = currentConversationId,
               let current = try await chatRepo.fetchConversation(byId: currentId),
               current.messages.isEmpty {
                AppLogger.app.logInfo("Current conversation is already empty, no action needed")
                return
            }

            // Try to find an existing empty conversation
            if let emptyConversation = try await chatRepo.fetchMostRecentEmptyConversation() {
                AppLogger.app.logInfo("Reusing existing empty conversation: \(emptyConversation.id)")
                currentConversationId = emptyConversation.id
                coordinator.lastConversationId = emptyConversation.id
                return
            }

            // No empty conversation found, create a new one
            AppLogger.app.logInfo("No empty conversation found, creating new one")
            await createNewConversation()

        } catch {
            AppLogger.app.logError("Error in createOrReuseConversation", error: error)
            await createNewConversation()
        }
    }

    // MARK: - Tab Views

    /// Chat tab with navigation view (iOS 15 compatible)
    private var chatTab: some View {
        NavigationView {
            if let conversationId = currentConversationId {
                ChatView(
                    viewModel: container.makeChatViewModel(
                        conversationId: conversationId
                    )
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                Task {
                                    await createOrReuseConversation()
                                }
                            }) {
                                Label(LocalizationKeys.newConversation.localized, systemImage: "square.and.pencil")
                            }

                            Button(action: {
                                coordinator.navigate(to: .history)
                            }) {
                                Label(LocalizationKeys.viewHistory.localized, systemImage: "clock")
                            }

                            Button(action: {
                                coordinator.navigate(to: .settings)
                            }) {
                                Label(LocalizationKeys.settings.localized, systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: AppTheme.Layout.iconSize))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
            } else {
                // Loading state while conversation is being created
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .padding(.top)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Re-check conversation exists when tab appears
            // This handles the case where user deleted all conversations
            // NOTE: We always validate to ensure conversation exists
            Task {
                await validateCurrentConversation()
            }
        }
    }

    /// Validates that the current conversation still exists
    /// If not, creates a new one
    private func validateCurrentConversation() async {
        AppLogger.app.logDebug("validateCurrentConversation called - current ID: \(currentConversationId ?? "nil")")

        guard let conversationId = currentConversationId else {
            AppLogger.app.logDebug("No current conversation ID, calling ensureConversationExists")
            await ensureConversationExists()
            return
        }

        guard let chatRepo = container.resolve(ChatRepository.self) else {
            AppLogger.app.logError("Failed to resolve ChatRepository")
            return
        }

        do {
            // Check if conversation still exists
            if let conversation = try await chatRepo.fetchConversation(byId: conversationId) {
                AppLogger.app.logDebug("Current conversation is valid: \(conversationId), has \(conversation.messages.count) messages")
                return
            }

            // Conversation was deleted, create a new one
            AppLogger.app.logWarning("Current conversation no longer exists, creating new one")
            currentConversationId = nil
            await ensureConversationExists()

        } catch {
            AppLogger.app.logError("Error validating conversation", error: error)
            await ensureConversationExists()
        }
    }

    /// History tab with navigation view (iOS 15 compatible)
    private var historyTab: some View {
        NavigationView {
            HistoryView(
                viewModel: container.makeHistoryViewModel(),
                coordinator: coordinator
            )
        }
        .navigationViewStyle(.stack)
    }

    /// Settings tab with navigation view (iOS 15 compatible)
    private var settingsTab: some View {
        NavigationView {
            SettingsView()
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

#Preview {
    MainTabView(
        coordinator: AppCoordinator(),
        container: DependencyContainer.shared
    )
}
