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
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var navigateToChat: String?
    @State private var showingDeleteAllAlert = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            contentView
        }
        .navigationTitle(LocalizationKeys.history.localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !viewModel.conversations.isEmpty {
                    Button(LocalizationKeys.clearAll.localized) {
                        showingDeleteAllAlert = true
                    }
                    .foregroundColor(.red)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: createNewConversation) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: AppTheme.Layout.iconSize))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .refreshable {
            viewModel.loadConversations()
        }
        .alert(LocalizationKeys.deleteConversation.localized, isPresented: $viewModel.showDeleteConfirmation) {
            Button(LocalizationKeys.cancel.localized, role: .cancel) {
                viewModel.cancelDelete()
            }
            Button(LocalizationKeys.delete.localized, role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text(LocalizationKeys.deleteConversationMessage.localized)
        }
        .alert(LocalizationKeys.deleteAllConversations.localized, isPresented: $showingDeleteAllAlert) {
            Button(LocalizationKeys.cancel.localized, role: .cancel) {}
            Button(LocalizationKeys.clearAll.localized, role: .destructive) {
                viewModel.deleteAllConversations()
            }
        } message: {
            Text(LocalizationKeys.deleteAllConversationsMessage.localized)
        }
        .alert(LocalizationKeys.error.localized, isPresented: .constant(viewModel.error != nil)) {
            Button(LocalizationKeys.ok.localized) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .task {
            viewModel.loadConversations()
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.conversations.isEmpty {
            loadingView
        } else if viewModel.conversations.isEmpty {
            emptyStateView
        } else {
            conversationsList
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(LocalizationKeys.loadingConversations.localized)
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
                Text(LocalizationKeys.noConversations.localized)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Text(LocalizationKeys.startNewChatToBegin.localized)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }

            Button(action: createNewConversation) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text(LocalizationKeys.newConversation.localized)
                }
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Layout.cornerRadius)
            }
            .padding(.top, AppTheme.Spacing.md)
        }
        .padding(AppTheme.Spacing.xl)
    }

    private var conversationsList: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink(destination: ChatView(
                    viewModel: DependencyContainer.shared.makeChatViewModel(
                        conversationId: conversation.id
                    )
                )) {
                    ConversationCardView(
                        title: viewModel.displayTitle(for: conversation),
                        preview: viewModel.messagePreview(for: conversation),
                        timestamp: viewModel.relativeTime(for: conversation),
                        conversationType: conversation.conversationType
                    )
                }
                .listRowBackground(AppTheme.Colors.background)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.requestDelete(conversation)
                    } label: {
                        Label(LocalizationKeys.delete.localized, systemImage: "trash")
                    }

                    Button {
                        shareConversation(conversation)
                    } label: {
                        Label(LocalizationKeys.share.localized, systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func createNewConversation() {
        Task {
            do {
                let conversationId = try await viewModel.createNewConversation()
                navigateToChat = conversationId
            } catch {
                // Error is already set in viewModel
            }
        }
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

#Preview("Empty State") {
    HistoryView(
        viewModel: HistoryViewModel(
            getConversationsUseCase: GetConversationsUseCase(
                chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
            ),
            deleteConversationUseCase: DeleteConversationUseCase(
                chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
            ),
            chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
        )
    )
}

#Preview("With Conversations") {
    HistoryView(
        viewModel: HistoryViewModel(
            getConversationsUseCase: GetConversationsUseCase(
                chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
            ),
            deleteConversationUseCase: DeleteConversationUseCase(
                chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
            ),
            chatRepository: DependencyContainer.shared.resolve(ChatRepository.self)!
        )
    )
}
