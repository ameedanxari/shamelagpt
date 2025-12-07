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
    let isAuthenticated: Bool
    let isGuest: Bool
    let onLogout: () -> Void
    let onRequireAuth: () -> Void
    // MARK: - State

    @State private var currentConversationId: String?
    @State private var isInitialized = false
    @State private var needsValidation = false
    @State private var showNewChatWarning = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Chat Tab
            chatTab
                .tabItem {
                    Label(LocalizationKeys.chat.localizedKey, systemImage: "message.fill")
                }
                .tag(0)
                .accessibilityLabel(Text(LocalizationKeys.chat.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.chatTabAccessibilityHint.localizedKey))

            // History Tab
            historyTab
                .tabItem {
                    Label(LocalizationKeys.history.localizedKey, systemImage: "clock.fill")
                }
                .tag(1)
                .accessibilityLabel(Text(LocalizationKeys.history.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.historyTabAccessibilityHint.localizedKey))

            // Settings Tab
            settingsTab
                .tabItem {
                    Label(LocalizationKeys.settings.localizedKey, systemImage: "gearshape.fill")
                }
                .tag(2)
                .accessibilityLabel(Text(LocalizationKeys.settings.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.settingsTabAccessibilityHint.localizedKey))
        }
        .accentColor(AppTheme.Colors.primary)
        .onChange(of: coordinator.selectedTab) { newTab in
            withAnimation(AppTheme.Animation.standard) {
                coordinator.saveSelectedTab(newTab)
            }
        }
        .alert(LocalizationKeys.newConversationWarningTitle.localizedKey, isPresented: $showNewChatWarning) {
            Button(LocalizationKeys.cancel.localizedKey, role: .cancel) {
                showNewChatWarning = false
            }
            Button(LocalizationKeys.newConversation.localizedKey, role: .destructive) {
                showNewChatWarning = false
                Task {
                    await createOrReuseConversation()
                }
            }
        } message: {
            Text(LocalizationKeys.newConversationWarningMessage.localizedKey)
        }
        .task {
            // Ensure we have a valid conversation on first launch
            await ensureConversationExists()
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestNewChatFromHistory)) { _ in
            coordinator.resetTabSelectionToChat()
            handleNewConversationRequest()
        }
        .onChange(of: coordinator.lastConversationId) { newId in
            guard let newId, newId != currentConversationId else { return }
            AppLogger.app.logInfo("MainTabView detected navigation to conversation: \(newId)")
            currentConversationId = newId
            Task {
                await validateCurrentConversation()
            }
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

            // Guest mode: try to restore last guest conversation or reuse/create a local-only one
            if isGuest {
                AppLogger.app.logInfo("Guest mode: restoring or creating local-only conversation")

                // Try restore last conversation id first
                if let lastId = coordinator.lastConversationId,
                   let restored = try await chatRepo.fetchConversation(byId: lastId) {
                    AppLogger.app.logInfo("Restored guest conversation by id: \(lastId)")
                    currentConversationId = lastId
                    coordinator.saveLastConversationId(lastId)
                    return
                }

                // Prefer reusing the newest empty local-only conversation to avoid creating duplicates
                if let emptyLocal = try await chatRepo.fetchMostRecentEmptyConversation(includeLocalOnly: true) {
                    AppLogger.app.logInfo("Reusing existing empty local-only conversation: \(emptyLocal.id)")
                    currentConversationId = emptyLocal.id
                    coordinator.saveLastConversationId(emptyLocal.id)
                    return
                }

                // Reuse any existing local-only conversation (empty or not)
                if let localOnly = try await chatRepo.fetchAllConversations().first(where: { $0.isLocalOnly }) {
                    AppLogger.app.logInfo("Reusing existing local-only conversation: \(localOnly.id)")
                    currentConversationId = localOnly.id
                    coordinator.saveLastConversationId(localOnly.id)
                    return
                }

                // No local conversation found - create one persisted as local-only
                AppLogger.app.logInfo("No guest conversation found, creating new local-only conversation")
                let newConversation = try await chatRepo.createConversation(title: "New Conversation", isLocalOnly: true)
                currentConversationId = newConversation.id
                coordinator.saveLastConversationId(newConversation.id)
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

            // If guest, create a local-only persisted conversation
            if isGuest {
                // Reuse any existing local-only conversation instead of creating another one
                if let existingLocal = try await chatRepo.fetchAllConversations().first(where: { $0.isLocalOnly }) {
                    AppLogger.app.logInfo("Guest mode - reusing existing local-only conversation instead of creating new: \(existingLocal.id)")
                    currentConversationId = existingLocal.id
                    coordinator.saveLastConversationId(existingLocal.id)
                    return
                }

                let newConversation = try await chatRepo.createConversation(title: "New Conversation", isLocalOnly: true)
                currentConversationId = newConversation.id
                coordinator.saveLastConversationId(newConversation.id)
                AppLogger.app.logInfo("Guest mode - created local-only conversation: \(newConversation.id)")
                return
            }

            let newConversation = try await chatRepo.createConversation(title: "New Conversation")
            currentConversationId = newConversation.id
            coordinator.saveLastConversationId(newConversation.id)
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

            // Guest path: create or reuse a local-only conversation and return
            if isGuest {
                AppLogger.app.logInfo("Guest mode: creating or reusing local-only conversation on user request")

                // Reuse current if empty
                if let currentId = currentConversationId,
                   let current = try await chatRepo.fetchConversation(byId: currentId),
                   current.messages.isEmpty {
                    AppLogger.app.logInfo("Current guest conversation is already empty, no action needed")
                    return
                }

                if let emptyConversation = try await chatRepo.fetchMostRecentEmptyConversation(includeLocalOnly: true) {
                    AppLogger.app.logInfo("Reusing existing local-only empty conversation: \(emptyConversation.id)")
                    currentConversationId = emptyConversation.id
                    coordinator.lastConversationId = emptyConversation.id
                    return
                }

                let newConversation = try await chatRepo.createConversation(title: "New Conversation", isLocalOnly: true)
                currentConversationId = newConversation.id
                coordinator.lastConversationId = newConversation.id
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

    /// Handles user request for a new conversation with a warning if it would hide the current chat
    private func handleNewConversationRequest() {
        Task {
            let needsWarning = await shouldWarnBeforeStartingNewChat()
            await MainActor.run {
                if needsWarning {
                    showNewChatWarning = true
                } else {
                    Task {
                        await createOrReuseConversation()
                    }
                }
            }
        }
    }

    /// Determines if starting a new chat should show a confirmation (e.g., active chat with messages)
    private func shouldWarnBeforeStartingNewChat() async -> Bool {
        guard let chatRepo = container.resolve(ChatRepository.self) else {
            return false
        }

        guard let currentId = currentConversationId,
              let conversation = try? await chatRepo.fetchConversation(byId: currentId) else {
            return false
        }

        return !conversation.messages.isEmpty
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
                ) {
                    onRequireAuth()
                }
                .id(conversationId) // force view/model refresh when switching conversations
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                handleNewConversationRequest()
                            }) {
                                Label(LocalizationKeys.newConversation.localizedKey, systemImage: "square.and.pencil")
                            }

                            Button(action: {
                                coordinator.navigate(to: .history)
                            }) {
                                Label(LocalizationKeys.viewHistory.localizedKey, systemImage: "clock")
                            }

                            Button(action: {
                                coordinator.navigate(to: .settings)
                            }) {
                                Label(LocalizationKeys.settings.localizedKey, systemImage: "gearshape")
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
                AppLogger.app.logDebug("Conversation metadata - threadId:\(conversation.threadId ?? "nil") isLocalOnly:\(conversation.isLocalOnly) createdAt:\(conversation.createdAt) updatedAt:\(conversation.updatedAt) messageCount:\(conversation.messageCount)")
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
                coordinator: coordinator,
                isAuthenticated: isAuthenticated,
                onSignIn: onRequireAuth
            )
        }
        .navigationViewStyle(.stack)
    }

    /// Settings tab with navigation view (iOS 15 compatible)
    private var settingsTab: some View {
        NavigationView {
            SettingsView(
                isAuthenticated: isAuthenticated,
                onLogout: onLogout,
                onSignIn: onRequireAuth
            )
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(
            coordinator: AppCoordinator(),
            container: DependencyContainer.shared,
            isAuthenticated: true,
            isGuest: false,
            onLogout: {},
            onRequireAuth: {}
        )
    }
}
