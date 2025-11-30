//
//  ChatView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// Main chat view displaying messages and input interface
struct ChatView: View {

    // MARK: - Properties

    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingErrorAlert = false
    @State private var isBottomBarVisible = true

    // MARK: - Body

    var body: some View {
        contentView
            // Main error alert disabled - using ErrorBannerView instead for better UX
            // .alert(isPresented: $showingErrorAlert) {
            //     Alert(
            //         title: Text(LocalizationKeys.error.localized),
            //         message: viewModel.error.map { Text(errorMessage(for: $0)) },
            //         primaryButton: .default(Text(LocalizationKeys.retry.localized)) {
            //             viewModel.clearError()
            //             viewModel.sendMessage()
            //         },
            //         secondaryButton: .cancel(Text(LocalizationKeys.cancel.localized)) {
            //             viewModel.clearError()
            //         }
            //     )
            // }
            .alert(isPresented: .constant(viewModel.voiceInputError != nil)) {
                Alert(
                    title: Text(LocalizationKeys.error.localized),
                    message: viewModel.voiceInputError.map { Text($0.localizedDescription) },
                    dismissButton: .default(Text(LocalizationKeys.ok.localized)) {
                        viewModel.clearVoiceInputError()
                    }
                )
            }
            .alert(isPresented: .constant(viewModel.ocrError != nil)) {
                Alert(
                    title: Text(LocalizationKeys.error.localized),
                    message: viewModel.ocrError.map { Text($0.localizedDescription) },
                    dismissButton: .default(Text(LocalizationKeys.ok.localized)) {
                        viewModel.clearOCRError()
                    }
                )
            }
        .sheet(isPresented: $viewModel.showImageSourceSheet) {
            ImageSourceSelectionSheet(
                onCameraSelected: {
                    viewModel.selectCamera()
                },
                onPhotoLibrarySelected: {
                    viewModel.selectPhotoLibrary()
                }
            )
        }
        .sheet(isPresented: $viewModel.showCameraPicker) {
            CameraPickerRepresentable(
                selectedImage: $viewModel.selectedImage,
                isPresented: $viewModel.showCameraPicker
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showPhotoLibraryPicker) {
            ImagePicker(
                selectedImage: $viewModel.selectedImage,
                sourceType: .photoLibrary
            )
        }
        // Disabled - using ErrorBannerView instead of Alert
        // .onChange(of: viewModel.error?.localizedDescription) { _ in
        //     showingErrorAlert = viewModel.error != nil
        // }
        .onChange(of: viewModel.errorMessage) { newMessage in
            if let msg = newMessage {
                AppLogger.app.logInfo("ErrorMessage changed, showing ErrorBannerView with message: \(msg)")
            } else {
                AppLogger.app.logInfo("ErrorMessage cleared, ErrorBannerView will be hidden")
            }
        }
        .onChange(of: viewModel.messages.count) { _ in
            scrollToBottom()
        }
        .task {
            await viewModel.loadMessages()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    hideKeyboard()
                }

            VStack(spacing: 0) {
                // Messages area
                messagesArea

                // Input bar with animation
                if isBottomBarVisible {
                    InputBarView(
                        text: $viewModel.inputText,
                        isEnabled: viewModel.canSendMessage,
                        isRecording: viewModel.isRecording,
                        isProcessingOCR: viewModel.isProcessingOCR,
                        onSend: viewModel.sendMessage,
                        onMicrophoneTap: viewModel.toggleVoiceInput,
                        onCameraTap: viewModel.handleCameraButtonTap
                    )
                    .transition(.move(edge: .bottom))
                }
            }

            // Error banner at top of ZStack for proper accessibility
            if let message = viewModel.errorMessage {
                VStack {
                    ErrorBannerView(
                        message: message,
                        onRetry: {
                            viewModel.clearError()
                            viewModel.sendMessage()
                        },
                        onDismiss: {
                            viewModel.clearError()
                        }
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .keyboardAdaptive()
    }

    // MARK: - Keyboard Helpers

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Subviews

    private var messagesArea: some View {
        Group {
            if viewModel.messages.isEmpty && !viewModel.isLoading {
                // Empty state
                emptyStateView
            } else {
                // Messages list
                messagesList
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView()
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xs) {
                    // Messages
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    // Typing indicator
                    if viewModel.isLoading {
                        TypingIndicatorView()
                            .id("typing-indicator")
                    }

                    // Bottom spacer for padding
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            .onTapGesture {
                // Toggle bottom bar visibility on tap
                withAnimation(AppTheme.Animation.standard) {
                    isBottomBarVisible.toggle()
                }
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(animated: false)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // Show bottom bar when new message arrives
                if !isBottomBarVisible {
                    withAnimation(AppTheme.Animation.standard) {
                        isBottomBarVisible = true
                    }
                }
            }
        }
    }


    // MARK: - Helpers

    private func scrollToBottom(animated: Bool = true) {
        guard let proxy = scrollProxy else { return }

        let targetId = viewModel.isLoading ? "typing-indicator" : "bottom"

        // Use .top anchor for better UX with long messages
        // This ensures the beginning of new messages is visible
        let anchor: UnitPoint = .top

        if animated {
            withAnimation(AppTheme.Animation.standard) {
                proxy.scrollTo(targetId, anchor: anchor)
            }
        } else {
            proxy.scrollTo(targetId, anchor: anchor)
        }
    }

    private func errorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userMessage
        }
        return error.localizedDescription
    }
}

// MARK: - Preview Provider

#Preview("Empty State") {
    ChatView(viewModel: ChatViewModel.preview)
}

#Preview("With Messages") {
    let viewModel = ChatViewModel.preview
    // Note: In actual preview, we would populate messages
    return ChatView(viewModel: viewModel)
}

// MARK: - Supporting Views

private struct ErrorBannerView: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Group {
                    Text(LocalizationKeys.error.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("ErrorBannerTitle")
                .accessibilityLabel("Error")
                .accessibilityAddTraits(.isStaticText)

                Group {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("ErrorBannerMessage")
                .accessibilityLabel(message)
                .accessibilityAddTraits(.isStaticText)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: onRetry) {
                        Text(LocalizationKeys.retry.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(AppTheme.Layout.cornerRadius)
                    }
                    .accessibilityIdentifier("ErrorBannerRetryButton")
                    .accessibilityLabel("Retry")

                    Button(action: onDismiss) {
                        Text(LocalizationKeys.cancel.localized)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .accessibilityIdentifier("ErrorBannerCancelButton")
                    .accessibilityLabel("Cancel")
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityIdentifier("ErrorBanner")
    }
}
