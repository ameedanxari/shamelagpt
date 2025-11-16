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
    @ObservedObject var chatSessionState: ChatSessionState
    let container: DependencyContainer
    let isAuthenticated: Bool
    let isGuest: Bool
    let onLogout: () -> Void
    let onRequireAuth: () -> Void

    // MARK: - State

    @State private var showNewChatWarning = false
    @StateObject private var languageManager = LanguageManager.shared

    // MARK: - Body

    var body: some View {
        // Create a Binding to the coordinator's selectedTab so SwiftUI can read/write it
        let selectedTabBinding = Binding<Int>(
            get: { coordinator.selectedTab },
            set: { coordinator.selectedTab = $0 }
        )

        TabView(selection: selectedTabBinding) {
            // Chat Tab
            chatTab
                .tabItem {
                    Label(LocalizationKeys.chat.localizedKey, systemImage: "message.fill")
                }
                .tag(0)
                .accessibilityIdentifier(AccessibilityID.Tab.chat)
                .accessibilityLabel(Text(LocalizationKeys.chat.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.chatTabAccessibilityHint.localizedKey))

            // History Tab
            historyTab
                .tabItem {
                    Label(LocalizationKeys.history.localizedKey, systemImage: "clock.fill")
                }
                .tag(1)
                .accessibilityIdentifier(AccessibilityID.Tab.history)
                .accessibilityLabel(Text(LocalizationKeys.history.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.historyTabAccessibilityHint.localizedKey))

            // Settings Tab
            settingsTab
                .tabItem {
                    Label(LocalizationKeys.settings.localizedKey, systemImage: "gearshape.fill")
                }
                .tag(2)
                .accessibilityIdentifier(AccessibilityID.Tab.settings)
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
                startNewChat()
            }
        } message: {
            Text(newConversationWarningMessageKey.localizedKey)
        }
        .onReceive(NotificationCenter.default.publisher(for: .requestNewChatFromHistory)) { _ in
            coordinator.resetTabSelectionToChat()
            handleNewConversationRequest()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openConversationFromHistory)) { notification in
            guard let conversationId = notification.object as? String else { return }
            AppLogger.app.logDebug("Notification openConversationFromHistory received for id \(conversationId)")
            coordinator.resetTabSelectionToChat()
            chatSessionState.set(.existing(id: conversationId))
        }
        .onChange(of: chatSessionState.state) { newState in
            if case let .existing(id) = newState {
                AppLogger.app.logInfo("MainTabView detected navigation to conversation: \(id)")
                Task {
                    await validateCurrentConversation()
                }
            }
        }
    }

    private var newConversationWarningMessageKey: String {
        isAuthenticated
            ? LocalizationKeys.newConversationWarningMessageLoggedIn
            : LocalizationKeys.newConversationWarningMessageLoggedOut
    }

    // MARK: - Helper Methods

    /// Resets the chat tab to a fresh conversation (no pre-created conversation record)
    @MainActor
    private func startNewChat() {
        AppLogger.app.logInfo("Starting new chat view without pre-creating conversation")
        chatSessionState.resetToNew()
    }

    /// Callback for ChatViewModel to notify when a conversation is created/loaded
    @MainActor
    private func handleConversationChanged(_ newId: String?) {
        if let newId = newId {
            chatSessionState.set(.existing(id: newId), preserveViewKey: true)
        } else {
            chatSessionState.resetToNew()
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

        guard let currentId = chatSessionState.conversationId,
              let conversation = try? await chatRepo.fetchConversation(byId: currentId) else {
            return false
        }

        return !conversation.messages.isEmpty
    }

    /// Validates that the current conversation still exists; resets to new chat if missing
    private func validateCurrentConversation() async {
        let currentId = chatSessionState.conversationId
        AppLogger.app.logDebug("validateCurrentConversation called - current ID: \(currentId ?? "nil")")

        guard let conversationId = currentId else {
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
                    conversationId: chatSessionState.conversationId,
                    onConversationChange: handleConversationChanged
                )
            ) {
                onRequireAuth()
            }
            .id(chatSessionState.viewKey) // force view/model refresh when explicitly switching conversations
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
        .id("settings-nav-\(languageManager.currentLanguage.rawValue)")
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let sessionManager = SessionManager()
        let chatSessionState = ChatSessionState(sessionManager: sessionManager)
        MainTabView(
            coordinator: AppCoordinator(chatSessionState: chatSessionState),
            chatSessionState: chatSessionState,
            container: DependencyContainer.shared,
            isAuthenticated: true,
            isGuest: false,
            onLogout: {},
            onRequireAuth: {}
        )
    }
}
