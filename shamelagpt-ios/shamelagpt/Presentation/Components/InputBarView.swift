//
//  InputBarView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A view that provides an input bar for sending messages
struct InputBarView: View {

    // MARK: - Properties

    @Binding var text: String
    let isEnabled: Bool
    let isRecording: Bool
    let isProcessingOCR: Bool
    let onSend: () -> Void
    let onMicrophoneTap: () -> Void
    let onCameraTap: () -> Void

    // MARK: - State

    @State private var textEditorHeight: CGFloat = 40
    @FocusState private var isFocused: Bool
    @State private var pulseScale: CGFloat = 1.0

    // MARK: - Constants

    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 120
    private var placeholder: LocalizedStringKey {
        LocalizationKeys.askQuestionPlaceholder.localizedKey
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Recording indicator
            if isRecording {
                recordingIndicator
            }

            // OCR processing indicator
            if isProcessingOCR {
                ocrProcessingIndicator
            }

            HStack(alignment: .bottom, spacing: AppTheme.Spacing.xs) {
                // Camera button
                cameraButton

                // Microphone button
                microphoneButton

                // Text input
                textInputArea

                // Send button
                sendButton
            }
            .padding(AppTheme.Spacing.sm)
            .background(DesignSystem.Colors.surface(colorScheme))
        }
    }

    // MARK: - Subviews

    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if text.isEmpty {
                            Text(placeholder)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .padding(.horizontal, AppTheme.Spacing.xxs)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .allowsHitTesting(false)
            }

            // Text editor without the default opaque background (prevents overlay from hiding placeholder)
            Group {
                if #available(iOS 16.0, *) {
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                } else {
                    TextEditor(text: $text)
                }
            }
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.primaryText)
            .frame(minHeight: minHeight, maxHeight: min(textEditorHeight, maxHeight))
            .background(Color.clear)
            .focused($isFocused)
            .accessibilityIdentifier(AccessibilityID.Chat.messageInputField)
            .accessibilityLabel(Text(LocalizationKeys.askQuestionPlaceholder.localizedKey))
            .onChange(of: text) { _ in
                updateHeight()
            }
            .onChange(of: isFocused) { focused in
                AppLogger.ui.logInfo("Chat input focus changed -> \(focused) (textLength=\(text.count), height=\(textEditorHeight))")
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(DesignSystem.Colors.inputBackground(colorScheme))
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                .stroke(DesignSystem.Colors.border(colorScheme), lineWidth: 1)
        )
    }

    private var cameraButton: some View {
        let isCameraEnabled = !isRecording && !isProcessingOCR

        return Button(action: onCameraTap) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22))
                .foregroundColor(isCameraEnabled ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                .frame(width: 40, height: 40)
        }
        .disabled(!isCameraEnabled)
        .scaleEffect(isCameraEnabled ? 1.0 : 0.9)
        .animation(AppTheme.Animation.quick, value: isCameraEnabled)
        .accessibilityLabel(Text(LocalizationKeys.cameraAccessibilityLabel.localizedKey))
        .accessibilityIdentifier(AccessibilityID.Chat.cameraButton)
        .accessibilityHint(Text(LocalizationKeys.cameraAccessibilityHint.localizedKey))
        .accessibilityAddTraits(.isButton)
    }

    private var microphoneButton: some View {
        Button(action: onMicrophoneTap) {
            ZStack {
                if isRecording {
                    // Pulsing circle background when recording
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulseScale)

                    // Stop icon (square) when recording
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                } else {
                    // Microphone icon when not recording
                    Image(systemName: "mic")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.Colors.primary)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .disabled(isProcessingOCR)  // Only disable during OCR, allow when empty or recording
        .scaleEffect(!isProcessingOCR ? 1.0 : 0.9)
        .animation(AppTheme.Animation.quick, value: isProcessingOCR)
        .accessibilityLabel(Text(isRecording ? LocalizationKeys.microphoneStopAccessibilityLabel.localizedKey : LocalizationKeys.microphoneStartAccessibilityLabel.localizedKey))
        .accessibilityIdentifier(AccessibilityID.Chat.micButton)
        .accessibilityHint(Text(isRecording ? LocalizationKeys.microphoneStopAccessibilityHint.localizedKey : LocalizationKeys.microphoneStartAccessibilityHint.localizedKey))
        .accessibilityValue(Text(isRecording ? LocalizationKeys.microphoneRecordingValue.localizedKey : LocalizationKeys.microphoneNotRecordingValue.localizedKey))
        .onAppear {
            if isRecording {
                startPulseAnimation()
            }
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                pulseScale = 1.0
            }
        }
    }

    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.tertiaryText)
                .scaleEffect(isEnabled ? 1.0 : 0.9)
        }
        .disabled(!isEnabled)
        .animation(AppTheme.Animation.quick, value: isEnabled)
        .accessibilityLabel(Text(LocalizationKeys.sendMessage.localizedKey))
        .accessibilityIdentifier(AccessibilityID.Chat.sendButton)
        .accessibilityHint(Text(LocalizationKeys.sendMessageAccessibilityHint.localizedKey))
        .accessibilityAddTraits(.isButton)
    }

    private var recordingIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseScale)

            Text(LocalizationKeys.recording.localizedKey)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(DesignSystem.Colors.surface(colorScheme))
    }

    private var ocrProcessingIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ProgressView()
                .scaleEffect(0.8)

            Text(LocalizationKeys.extractingText.localizedKey)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(DesignSystem.Colors.surface(colorScheme))
    }

    // MARK: - Actions

    private func handleSend() {
        guard isEnabled else { return }

        // Dismiss keyboard
        isFocused = false

        // Trigger send action
        onSend()

        // Reset height after sending
        textEditorHeight = minHeight
    }

    // MARK: - Helpers

    private func updateHeight() {
        // Calculate the height needed for the text
        let width = UIScreen.main.bounds.width - (AppTheme.Spacing.sm * 2) - (AppTheme.Spacing.xs * 6) - 120 // Subtract padding and button widths
        let font = UIFont.systemFont(ofSize: 16)

        let textView = UITextView()
        textView.font = font
        textView.text = text.isEmpty ? "A" : text // Use placeholder to maintain min height

        let size = textView.sizeThatFits(CGSize(width: width, height: .infinity))
        textEditorHeight = max(minHeight, min(size.height, maxHeight))
    }

    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.5
        }
    }
}

struct InputBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(text: "", isEnabled: true, isRecording: false, isProcessingOCR: false)
                .previewDisplayName("Empty State")

            preview(text: "What are the pillars of Islam?", isEnabled: true, isRecording: false, isProcessingOCR: false)
                .previewDisplayName("With Text")

            preview(text: "", isEnabled: true, isRecording: true, isProcessingOCR: false)
                .previewDisplayName("Recording")

            preview(text: "", isEnabled: true, isRecording: false, isProcessingOCR: true)
                .previewDisplayName("Processing OCR")

            preview(text: "Loading...", isEnabled: false, isRecording: false, isProcessingOCR: false)
                .previewDisplayName("Disabled")

            preview(
                text: "This is a longer message that spans multiple lines. It demonstrates how the text editor expands to accommodate more content while respecting the maximum height constraint.",
                isEnabled: true,
                isRecording: false,
                isProcessingOCR: false
            )
            .previewDisplayName("Multi-line")
        }
    }

    private static func preview(
        text: String,
        isEnabled: Bool,
        isRecording: Bool,
        isProcessingOCR: Bool
    ) -> some View {
        VStack {
            Spacer()
            InputBarView(
                text: .constant(text),
                isEnabled: isEnabled,
                isRecording: isRecording,
                isProcessingOCR: isProcessingOCR,
                onSend: {},
                onMicrophoneTap: {},
                onCameraTap: {}
            )
        }
    }
}
