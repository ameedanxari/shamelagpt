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
    @State private var activeTransientAlert: ActiveTransientAlert?

    private enum ActiveTransientAlert {
        case voice
        case ocr
    }

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
            .alert(isPresented: Binding(
                get: {
                    activeTransientAlert != nil
                },
                set: { isPresented in
                    if !isPresented {
                        switch activeTransientAlert {
                        case .voice:
                            viewModel.clearVoiceInputError()
                        case .ocr:
                            viewModel.clearOCRError()
                        case .none:
                            break
                        }
                        activeTransientAlert = nil
                    }
                }
            )) {
                if activeTransientAlert == .voice {
                    return Alert(
                        title: Text(LocalizationKeys.error.localizedKey),
                        message: viewModel.voiceInputError.map { Text($0.localizedDescription) },
                        dismissButton: .default(Text(LocalizationKeys.ok.localizedKey)) {
                            viewModel.clearVoiceInputError()
                            activeTransientAlert = nil
                        }
                    )
                }
                return Alert(
                    title: Text(LocalizationKeys.error.localizedKey),
                    message: viewModel.ocrError.map { Text($0.localizedDescription) },
                    dismissButton: .default(Text(LocalizationKeys.ok.localizedKey)) {
                        viewModel.clearOCRError()
                        activeTransientAlert = nil
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
                detectedLanguage: viewModel.ocrDetectedLanguage,
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
                AppLogger.app.logDebug("ERROR BANNER DEBUG - Showing error banner: \(msg), isUITesting: \(ProcessInfo.processInfo.environment["UI_TESTING"] == "1")")
            } else {
                AppLogger.app.logInfo("ErrorMessage cleared, ErrorBannerView will be hidden")
                AppLogger.app.logDebug("ERROR BANNER DEBUG - Hiding error banner, isUITesting: \(ProcessInfo.processInfo.environment["UI_TESTING"] == "1")")
            }
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
        .onChange(of: viewModel.voiceInputError) { voiceError in
            if voiceError != nil {
                activeTransientAlert = .voice
            } else if activeTransientAlert == .voice {
                activeTransientAlert = nil
            }
        }
        .onChange(of: viewModel.ocrError) { ocrError in
            if ocrError != nil, activeTransientAlert == nil {
                activeTransientAlert = .ocr
            } else if ocrError == nil, activeTransientAlert == .ocr {
                activeTransientAlert = nil
            }
        }
        .onChange(of: isHydrating) { hydrating in
            if !hydrating {
                // After hydration (e.g., opening from history), snap to the last user message without animation
                scrollToBottom(animated: false)
            }
        }
        .onAppear {
            // Catch pending extension payloads even if deep-link notification fired before this view subscribed.
            viewModel.handleImportedFactCheckIfAvailable()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importFactCheckPayload)) { _ in
            viewModel.handleImportedFactCheckIfAvailable()
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
                        onSend: { viewModel.sendMessage() },
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
        EmptyStateView { suggestion in
            viewModel.sendSuggestion(suggestion)
        }
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
                    if viewModel.isLoading && viewModel.isAwaitingFirstResponseChunk {
                        TypingIndicatorView()
                            .id("typing-indicator")
                    }

                    // Streaming thinking status bubble (guest SSE) shown under the typing indicator
                    if viewModel.isAwaitingFirstResponseChunk && !viewModel.thinkingMessages.isEmpty {
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
                handleMessagesChanged()
            }
            .onChange(of: viewModel.isLoading) { _ in
                scrollToBottom(animated: true)
            }
            .onChange(of: viewModel.thinkingMessages.count) { _ in
                scrollToBottom(animated: true)
            }
        }
    }

    private func updateTabBarVisibility(hidden: Bool) {
        guard let tabBar = findTabBar(in: UIApplication.shared) else {
            UITabBar.appearance().isHidden = hidden
            return
        }
        if tabBar.isHidden != hidden {
            tabBar.isHidden = hidden
        }
    }


    // MARK: - Helpers

    private func handleMessagesChanged() {
        // Show bottom bar when new message arrives
        if !isBottomBarVisible {
            withAnimation(AppTheme.Animation.standard) {
                isBottomBarVisible = true
            }
        }
        updateTabBarVisibility(hidden: false)
        
        // Defer scroll to ensure layout is updated before computing anchor
        DispatchQueue.main.async {
            scrollToBottom(animated: true)
        }
    }

    private func scrollToBottom(animated: Bool = true) {
        guard let proxy = scrollProxy else { return }

        // Determine the target to scroll to.
        // During active streaming or thinking, always target the absolute bottom
        // so the user sees the latest progress.
        let targetId: String
        let anchor: UnitPoint
        
        if viewModel.isAwaitingFirstResponseChunk && !viewModel.thinkingMessages.isEmpty {
            targetId = "thinking-bubble"
            anchor = .bottom
        } else if viewModel.isAwaitingFirstResponseChunk && viewModel.isLoading {
            targetId = "typing-indicator"
            anchor = .bottom
        } else {
            // After loading is done, we might want to see the last message.
            // Using .top anchor for the last message often feels better for long GPT responses
            // but for simple chat, .bottom is standard. We'll use .bottom as the consensus for "absolute bottom".
            targetId = viewModel.messages.last?.id ?? "bottom"
            anchor = .bottom
        }

        let performScroll = {
            proxy.scrollTo(targetId, anchor: anchor)
        }

        if animated {
            withAnimation(AppTheme.Animation.standard) {
                performScroll()
            }
        } else {
            performScroll()
        }
    }

    private func errorMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.userMessage
        }
        return error.localizedDescription
    }

    /// Walk the view controller tree to find the active UITabBarController.
    private func findTabBar(in application: UIApplication) -> UITabBar? {
        let foregroundScenes = application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        for scene in foregroundScenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController,
               let tabBar = root.findTabBarController()?.tabBar {
                return tabBar
            }
        }
        return nil
    }
}

private extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tab = self as? UITabBarController { return tab }
        for child in children {
            if let found = child.findTabBarController() {
                return found
            }
        }
        if let presented = presentedViewController {
            return presented.findTabBarController()
        }
        return nil
    }
}
#if DEBUG
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
#endif

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
                Text(LocalizationKeys.error.localizedKey)
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityIdentifier(AccessibilityID.Chat.errorBannerTitle)
                    .accessibilityLabel("Error")
                    .accessibilityAddTraits(.isStaticText)

                Text(message.localizedKey)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .accessibilityIdentifier(AccessibilityID.Chat.errorBannerMessage)
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
                    .accessibilityIdentifier(AccessibilityID.Chat.errorBannerRetryButton)
                    .accessibilityLabel("Retry")

                    Button(action: onDismiss) {
                        Text(LocalizationKeys.cancel.localizedKey)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .accessibilityIdentifier(AccessibilityID.Chat.errorBannerCancelButton)
                    .accessibilityLabel("Cancel")
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Chat.errorBanner)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(messages.joined(separator: " ")))
        .accessibilityIdentifier(AccessibilityID.Chat.thinkingBubble)
    }
}
