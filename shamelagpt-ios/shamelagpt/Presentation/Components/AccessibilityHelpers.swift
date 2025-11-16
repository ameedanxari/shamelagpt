//
//  AccessibilityHelpers.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

// MARK: - Accessibility Labels
enum AccessibilityLabels {
    static let sendButton = "Send message"
    static let microphoneButton = "Voice input"
    static let cameraButton = "Image text recognition"
    static let newChatButton = "New conversation"
    static let deleteButton = "Delete conversation"
    static let shareButton = "Share conversation"
    static let settingsButton = "Settings"
    static let backButton = "Back"
    static let closeButton = "Close"
}

// MARK: - Accessibility Hints
enum AccessibilityHints {
    static let sendButton = "Double tap to send your message"
    static let microphoneButton = "Double tap to start or stop voice recording"
    static let cameraButton = "Double tap to take a photo or select from library"
    static let conversation = "Double tap to open conversation"
    static let deleteConversation = "Double tap to delete this conversation"
    static let shareConversation = "Double tap to share this conversation"
    static let newChat = "Double tap to start a new conversation"
}

// MARK: - Accessibility Traits
extension View {
    func makeAccessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }

    func accessibilityHeading() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    func accessibilityButton() -> some View {
        self.accessibilityAddTraits(.isButton)
    }
}

// MARK: - Message Accessibility
extension View {
    func messageAccessibility(isUserMessage: Bool, content: String, timestamp: Date) -> some View {
        let sender = isUserMessage ? "You" : "ShamelaGPT"
        let timeString = timestamp.formatted()
        let label = "\(sender) said: \(content)"
        let hint = "Message sent at \(timeString)"

        return self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Dynamic Type Support
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

extension View {
    func supportDynamicType() -> some View {
        modifier(DynamicTypeModifier())
    }
}
