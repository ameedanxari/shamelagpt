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
    private var placeholder: String {
        LocalizationKeys.askQuestionPlaceholder.localized
    }

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
            .background(AppTheme.Colors.background)
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

            // Text editor
            TextEditor(text: $text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)
                .frame(minHeight: minHeight, maxHeight: min(textEditorHeight, maxHeight))
                .background(Color.clear)
                .focused($isFocused)
                .onChange(of: text) { _ in
                    updateHeight()
                }
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.Layout.cornerRadius)
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
        .accessibilityLabel(LocalizationKeys.cameraAccessibilityLabel.localized)
        .accessibilityHint(LocalizationKeys.cameraAccessibilityHint.localized)
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
        .accessibilityLabel(isRecording ? LocalizationKeys.microphoneStopAccessibilityLabel.localized : LocalizationKeys.microphoneStartAccessibilityLabel.localized)
        .accessibilityHint(isRecording ? LocalizationKeys.microphoneStopAccessibilityHint.localized : LocalizationKeys.microphoneStartAccessibilityHint.localized)
        .accessibilityValue(isRecording ? LocalizationKeys.microphoneRecordingValue.localized : LocalizationKeys.microphoneNotRecordingValue.localized)
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
        .accessibilityLabel(LocalizationKeys.sendMessage.localized)
        .accessibilityHint(LocalizationKeys.sendMessageAccessibilityHint.localized)
        .accessibilityAddTraits(.isButton)
    }

    private var recordingIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(pulseScale)

            Text(LocalizationKeys.recording.localized)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.secondaryBackground)
    }

    private var ocrProcessingIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ProgressView()
                .scaleEffect(0.8)

            Text(LocalizationKeys.extractingText.localized)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.secondaryBackground)
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

// MARK: - Preview Provider

#Preview("Empty State") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant(""),
            isEnabled: true,
            isRecording: false,
            isProcessingOCR: false,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant("What are the pillars of Islam?"),
            isEnabled: true,
            isRecording: false,
            isProcessingOCR: false,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}

#Preview("Recording") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant(""),
            isEnabled: true,
            isRecording: true,
            isProcessingOCR: false,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}

#Preview("Processing OCR") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant(""),
            isEnabled: true,
            isRecording: false,
            isProcessingOCR: true,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}

#Preview("Disabled") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant("Loading..."),
            isEnabled: false,
            isRecording: false,
            isProcessingOCR: false,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}

#Preview("Multi-line") {
    VStack {
        Spacer()
        InputBarView(
            text: .constant("This is a longer message that spans multiple lines. It demonstrates how the text editor expands to accommodate more content while respecting the maximum height constraint."),
            isEnabled: true,
            isRecording: false,
            isProcessingOCR: false,
            onSend: {},
            onMicrophoneTap: {},
            onCameraTap: {}
        )
    }
}
