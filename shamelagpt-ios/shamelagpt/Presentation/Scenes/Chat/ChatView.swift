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
    @Environment(\.colorScheme) private var colorScheme
    var onRequireAuth: () -> Void = {}

    // MARK: - State

    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingErrorAlert = false
    @State private var isBottomBarVisible = true
    @State private var isHydrating = false

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
                    title: Text(LocalizationKeys.error.localizedKey),
                    message: viewModel.voiceInputError.map { Text($0.localizedDescription) },
                    dismissButton: .default(Text(LocalizationKeys.ok.localizedKey)) {
                        viewModel.clearVoiceInputError()
                    }
                )
            }
            .alert(isPresented: .constant(viewModel.ocrError != nil)) {
                Alert(
                    title: Text(LocalizationKeys.error.localizedKey),
                    message: viewModel.ocrError.map { Text($0.localizedDescription) },
                    dismissButton: .default(Text(LocalizationKeys.ok.localizedKey)) {
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
        .sheet(isPresented: $viewModel.showCameraPermissionDenied) {
            PermissionDeniedView(
                permissionType: LocalizationKeys.cameraAccessibilityLabel,
                settingsAction: viewModel.openSettings
            )
        }
        .sheet(isPresented: $viewModel.showPhotoPermissionDenied) {
            PermissionDeniedView(
                permissionType: LocalizationKeys.imagePickerChooseFromLibrary,
                settingsAction: viewModel.openSettings
            )
        }
        .sheet(isPresented: $viewModel.showOCRConfirmation) {
            OCRConfirmationSheet(
                text: $viewModel.ocrExtractedText,
                imageData: viewModel.ocrImageData,
                onConfirm: { text in
                    viewModel.confirmFactCheck(text: text)
                },
                onCancel: {
                    viewModel.dismissOCRConfirmation()
                }
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
            if viewModel.conversationId != nil {
                isHydrating = true
                await viewModel.loadMessages()
                isHydrating = false
            } else {
                isHydrating = false
            }
        }
        .onChange(of: viewModel.requiresAuth) { requiresAuth in
            if requiresAuth {
                onRequireAuth()
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
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

            // Centered loader overlay during hydration
            if isHydrating {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView(LocalizationKeys.loadingMessages.localizedKey)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignSystem.Colors.background(colorScheme).opacity(0.9))
                    )
                    .shadow(radius: 10)
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
            if viewModel.messages.isEmpty && !viewModel.isLoading && !isHydrating {
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

                    // Streaming thinking status bubble (guest SSE) shown under the typing indicator
                    if !viewModel.thinkingMessages.isEmpty {
                        ThinkingBubbleView(messages: viewModel.thinkingMessages)
                            .id("thinking-bubble")
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
                let newVisibility = !isBottomBarVisible
                withAnimation(AppTheme.Animation.standard) {
                    isBottomBarVisible = newVisibility
                }
                updateTabBarVisibility(hidden: !newVisibility)
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(animated: false)
                updateTabBarVisibility(hidden: false)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // Show bottom bar when new message arrives
                if !isBottomBarVisible {
                    withAnimation(AppTheme.Animation.standard) {
                        isBottomBarVisible = true
                    }
                }
                updateTabBarVisibility(hidden: false)
            }
        }
    }

    private func updateTabBarVisibility(hidden: Bool) {
        // Toggle tab bar visibility to match the input bar state
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.tabBarController?.tabBar.isHidden = hidden
        } else {
            UITabBar.appearance().isHidden = hidden
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

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatView(viewModel: ChatViewModel.preview)
                .previewDisplayName("Empty State")

            let viewModel = ChatViewModel.preview
            // Note: In actual preview, we would populate messages
            ChatView(viewModel: viewModel)
                .previewDisplayName("With Messages")
        }
    }
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
                    Text(LocalizationKeys.error.localizedKey)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("ErrorBannerTitle")
                .accessibilityLabel("Error")
                .accessibilityAddTraits(.isStaticText)

                    Group {
                        Text(message.localizedKey)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("ErrorBannerMessage")
                    .accessibilityLabel(Text(message.localizedKey))
                    .accessibilityAddTraits(.isStaticText)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: onRetry) {
                        Text(LocalizationKeys.retry.localizedKey)
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
                        Text(LocalizationKeys.cancel.localizedKey)
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

/// Lightweight bubble to show streaming "thinking" text beneath the typing indicator.
private struct ThinkingBubbleView: View {
    let messages: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(AppTheme.Colors.secondaryText)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                ForEach(Array(messages.enumerated()), id: \.offset) { _, text in
                    Text(text)
                        .font(AppTheme.Typography.caption.italic())
                        .foregroundColor(AppTheme.Colors.secondaryText.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(DesignSystem.Colors.surface(colorScheme))
            .cornerRadius(AppTheme.Layout.messageBubbleRadius)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}
