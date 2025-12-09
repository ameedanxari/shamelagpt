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
    @State private var chatViewKey: String = "new-chat"
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
                if newTab == 0 {
                    syncConversationFromCoordinator(reason: "selectedTab changed to Chat")
                }
            }
        }
        .alert(LocalizationKeys.newConversationWarningTitle.localizedKey, isPresented: $showNewChatWarning) {
            Button(LocalizationKeys.cancel.localizedKey, role: .cancel) {
                showNewChatWarning = false
            }
            Button(LocalizationKeys.newConversation.localizedKey, role: .destructive) {
                showNewChatWarning = false
                startNewChat()
            }
        } message: {
            Text(LocalizationKeys.newConversationWarningMessage.localizedKey)
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestNewChatFromHistory)) { _ in
            coordinator.resetTabSelectionToChat()
            handleNewConversationRequest()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openConversationFromHistory)) { notification in
            guard let conversationId = notification.object as? String else { return }
            AppLogger.app.logDebug("Notification openConversationFromHistory received for id \(conversationId)")
            coordinator.resetTabSelectionToChat()
            // Set immediately so ChatView refreshes without waiting for published changes
            currentConversationId = conversationId
            chatViewKey = conversationId
        }
        .onChange(of: coordinator.lastConversationId) { newId in
            guard let newId, newId != currentConversationId else { return }
            AppLogger.app.logInfo("MainTabView detected navigation to conversation: \(newId)")
            currentConversationId = newId
            chatViewKey = newId
            Task {
                await validateCurrentConversation()
            }
        }
    }

    // MARK: - Helper Methods


    /// Resets the chat tab to a fresh conversation (no pre-created conversation record)
    @MainActor
    private func startNewChat() {
        AppLogger.app.logInfo("Starting new chat view without pre-creating conversation")
        currentConversationId = nil
        chatViewKey = "new-chat-\(UUID().uuidString)"
        coordinator.clearLastConversationId()
    }

    /// Sync chat state from coordinator when switching tabs or resuming
    @MainActor
    private func syncConversationFromCoordinator(reason: String) {
        if currentConversationId == nil, let lastId = coordinator.lastConversationId {
            AppLogger.app.logDebug("Syncing chat state from coordinator (\(reason)) -> lastConversationId=\(lastId)")
            currentConversationId = lastId
            chatViewKey = lastId
        }
    }

    /// Callback for ChatViewModel to notify when a conversation is created/loaded
    @MainActor
    private func handleConversationChanged(_ newId: String?) {
        if currentConversationId != newId {
            currentConversationId = newId
        }
        if let newId {
            coordinator.saveLastConversationId(newId)
        } else {
            coordinator.clearLastConversationId()
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
                    startNewChat()
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

    /// Validates that the current conversation still exists; resets to new chat if missing
    private func validateCurrentConversation() async {
        AppLogger.app.logDebug("validateCurrentConversation called - current ID: \(currentConversationId ?? "nil")")

        guard let conversationId = currentConversationId else {
            AppLogger.app.logDebug("No current conversation ID, staying on new chat view")
            return
        }

        guard let chatRepo = container.resolve(ChatRepository.self) else {
            AppLogger.app.logError("Failed to resolve ChatRepository")
            return
        }

        do {
            if let conversation = try await chatRepo.fetchConversation(byId: conversationId) {
                AppLogger.app.logDebug("Current conversation is valid: \(conversationId), has \(conversation.messages.count) messages")
                AppLogger.app.logDebug("Conversation metadata - threadId:\(conversation.threadId ?? "nil") isLocalOnly:\(conversation.isLocalOnly) createdAt:\(conversation.createdAt) updatedAt:\(conversation.updatedAt) messageCount:\(conversation.messageCount)")
                return
            }

            AppLogger.app.logWarning("Current conversation no longer exists, resetting to new chat")
            await MainActor.run {
                startNewChat()
            }

        } catch {
            AppLogger.app.logError("Error validating conversation", error: error)
            await MainActor.run {
                startNewChat()
            }
        }
    }

    /// Chat tab with navigation view (iOS 15 compatible)
    private var chatTab: some View {
        NavigationView {
            ChatView(
                viewModel: container.makeChatViewModel(
                    conversationId: currentConversationId,
                    onConversationChange: handleConversationChanged
                )
            ) {
                onRequireAuth()
            }
            .id(chatViewKey) // force view/model refresh when explicitly switching conversations
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
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Re-check conversation exists when tab appears to handle deletes
            Task {
                await validateCurrentConversation()
            }
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
