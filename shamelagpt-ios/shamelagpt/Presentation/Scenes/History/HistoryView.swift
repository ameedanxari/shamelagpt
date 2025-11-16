//
//  HistoryView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// View displaying conversation history
struct HistoryView: View {

    // MARK: - Properties

    @StateObject var viewModel: HistoryViewModel
    @ObservedObject var coordinator: AppCoordinator
    let isAuthenticated: Bool
    let onSignIn: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var showingDeleteAllAlert = false

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()

            contentView
        }
        .navigationTitle(LocalizationKeys.history.localizedKey)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isAuthenticated && !viewModel.conversations.isEmpty {
                    Button(LocalizationKeys.clearAll.localizedKey) {
                        showingDeleteAllAlert = true
                    }
                    .foregroundColor(.red)
                    .accessibilityIdentifier(AccessibilityID.History.clearAllButton)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: createNewConversation) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: AppTheme.Layout.iconSize))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .accessibilityLabel(Text(LocalizationKeys.newChat.localizedKey))
                .accessibilityIdentifier(AccessibilityID.History.newChatButton)
            }
        }
        .refreshable {
            if isAuthenticated {
                await viewModel.refreshConversations(forceRefresh: true)
            }
        }
        .onAppear {
            viewModel.includeLocalOnly = isAuthenticated
        }
        .alert(LocalizationKeys.deleteConversation.localizedKey, isPresented: $viewModel.showDeleteConfirmation) {
            Button(LocalizationKeys.cancel.localizedKey, role: .cancel) {
                viewModel.cancelDelete()
            }
            Button(LocalizationKeys.delete.localizedKey, role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            if let conversation = viewModel.conversationToDelete {
                let title = viewModel.displayTitle(for: conversation)
                Text(LocalizationKeys.deleteConversationMessageWithTitle.localized(with: title))
            } else {
                Text(LocalizationKeys.deleteConversationMessage.localizedKey)
            }
        }
        .alert(LocalizationKeys.deleteAllConversations.localizedKey, isPresented: $showingDeleteAllAlert) {
            Button(LocalizationKeys.cancel.localizedKey, role: .cancel) {}
            Button(LocalizationKeys.clearAll.localizedKey, role: .destructive) {
                viewModel.deleteAllConversations()
            }
        } message: {
            Text(LocalizationKeys.deleteAllConversationsMessage.localizedKey)
        }
        .alert(LocalizationKeys.error.localizedKey, isPresented: .constant(viewModel.error != nil)) {
            Button(LocalizationKeys.ok.localizedKey) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .task {
            if isAuthenticated {
                viewModel.loadConversations()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if !isAuthenticated {
            guestLockedView
        } else if viewModel.isLoading && viewModel.conversations.isEmpty {
            loadingView
        } else if viewModel.conversations.isEmpty {
            emptyStateView
        } else {
            conversationsList
        }
    }

    // MARK: - Subviews

    private var guestLockedView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(AppTheme.Spacing.lg)
                    .background(DesignSystem.Colors.surface(colorScheme))
                    .clipShape(Circle())
                    .accessibilityIdentifier(AccessibilityID.History.lockedIcon)
                
                Text(LocalizationKeys.historyLockedTitle.localizedKey)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(AccessibilityID.History.lockedTitle)
                
                Text(LocalizationKeys.historyLockedMessage.localizedKey)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityIdentifier(AccessibilityID.History.lockedMessage)
            }
            
            Button(action: onSignIn) {
                HStack {
                    Image(systemName: "person.circle")
                    Text(LocalizationKeys.signInButton.localizedKey)
                }
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.primary)
                .cornerRadius(AppTheme.Layout.cornerRadius)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .accessibilityIdentifier(AccessibilityID.Auth.signInButton)
            
            Spacer()
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(LocalizationKeys.loadingConversations.localizedKey)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "clock.fill")
                .font(.system(size: AppTheme.Layout.largeIconSize))
                .foregroundColor(AppTheme.Colors.tertiaryText)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(LocalizationKeys.noConversations.localizedKey)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Text(LocalizationKeys.startNewChatToBegin.localizedKey)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            Button(action: createNewConversation) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text(LocalizationKeys.newConversation.localizedKey)
                }
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Layout.cornerRadius)
            }
            .padding(.top, AppTheme.Spacing.md)
            .accessibilityIdentifier(AccessibilityID.History.newConversationButton)
        }
        .padding(AppTheme.Spacing.xl)
    }

    private var conversationsList: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                Button(action: {
                    AppLogger.app.logInfo("History tap -> conversation id:\(conversation.id) messages:\(conversation.messages.count) threadId:\(conversation.threadId ?? "nil") localOnly:\(conversation.isLocalOnly)")
                    NotificationCenter.default.post(name: .openConversationFromHistory, object: conversation.id)
                    coordinator.openConversation(conversation.id)
                }) {
                    ConversationCardView(
                        title: viewModel.displayTitle(for: conversation),
                        preview: viewModel.messagePreview(for: conversation),
                        timestamp: viewModel.relativeTime(for: conversation),
                        conversationType: conversation.conversationType,
                        isLocalOnly: conversation.isLocalOnly
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier(AccessibilityID.History.conversationCard(conversation.id))
                .listRowBackground(DesignSystem.Colors.background(colorScheme))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.requestDelete(conversation)
                    } label: {
                        Label(LocalizationKeys.delete.localizedKey, systemImage: "trash")
                    }
                    .accessibilityIdentifier(AccessibilityID.History.deleteConversationButton)

                    Button {
                        shareConversation(conversation)
                    } label: {
                        Label(LocalizationKeys.share.localizedKey, systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                    .accessibilityIdentifier(AccessibilityID.History.shareConversationButton)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func createNewConversation() {
        // Always route to the chat tab with a fresh conversation state.
        NotificationCenter.default.post(name: .requestNewChatFromHistory, object: nil)
        coordinator.resetTabSelectionToChat()
    }

    private func shareConversation(_ conversation: Conversation) {
        let text = viewModel.exportConversation(conversation)

        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            activityController.popoverPresentationController?.sourceView = window
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Preview Provider

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let sessionState = ChatSessionState(sessionManager: SessionManager())
        
        Group {
            HistoryView(
                viewModel: HistoryViewModel(
                    getConversationsUseCase: GetConversationsUseCase(
                        chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                    ),
                    deleteConversationUseCase: DeleteConversationUseCase(
                        chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                    ),
                    chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                ),
                coordinator: AppCoordinator(chatSessionState: sessionState),
                isAuthenticated: false,
                onSignIn: {}
            )
            .previewDisplayName("Empty State (Guest)")

            HistoryView(
                viewModel: HistoryViewModel(
                    getConversationsUseCase: GetConversationsUseCase(
                        chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                    ),
                    deleteConversationUseCase: DeleteConversationUseCase(
                        chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                    ),
                    chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
                ),
                coordinator: AppCoordinator(chatSessionState: sessionState),
                isAuthenticated: true,
                onSignIn: {}
            )
            .previewDisplayName("With Conversations (Auth)")
        }
    }
}
