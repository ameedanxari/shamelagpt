import Foundation

/// UI test-side canonical selector registry.
enum UITestID {
    enum Debug {
        static let languageProbePrefix = "uiTestLanguageProbe_"

        static func languageProbe(_ code: String) -> String {
            "\(languageProbePrefix)\(code)"
        }
    }

    enum Tab {
        static let chat = "ChatTab"
        static let history = "HistoryTab"
        static let settings = "SettingsTab"
    }

    enum Auth {
        static let emailTextField = "emailTextField"
        static let passwordTextField = "passwordTextField"
        static let displayNameTextField = "displayNameTextField"
        static let errorLabel = "errorLabel"
        static let signInButton = "signInButton"
        static let signUpButton = "signUpButton"
        static let continueAsGuestButton = "continueAsGuestButton"
        static let toggleModeButton = "toggleModeButton"
    }

    enum Chat {
        static let messageInputField = "messageInputField"
        static let cameraButton = "cameraButton"
        static let micButton = "micButton"
        static let sendButton = "sendButton"
        static let typingIndicator = "TypingIndicator"
        static let thinkingBubble = "ThinkingBubble"
        static let messageBubble = "MessageBubble"
        static let sourcesHeader = "SourcesHeader"
        static let sourceLinkPrefix = "SourceLink-"
        static let errorBanner = "ErrorBanner"
        static let errorBannerRetryButton = "ErrorBannerRetryButton"
        static let errorBannerCancelButton = "ErrorBannerCancelButton"
    }

    enum History {
        static let clearAllButton = "historyClearAllButton"
        static let newChatButton = "historyNewChatButton"
        static let newConversationButton = "historyNewConversationButton"
        static let deleteConversationButton = "historyDeleteConversationButton"
        static let shareConversationButton = "historyShareConversationButton"
        static let activityListView = "ActivityListView"
        static func conversationCard(_ id: String) -> String { "conversationCard_\(id)" }
    }

    enum Settings {
        static let languageRow = "LanguageRow"
        static let aboutRow = "AboutRow"
        static let privacyRow = "PrivacyRow"
        static let termsRow = "TermsRow"
        static func languageOption(_ code: String) -> String { "LanguageOption_\(code)" }
        static func languageCheckmark(_ code: String) -> String { "LanguageSelectedCheckmark_\(code)" }
    }

    enum Welcome {
        static let logo = "welcomeLogo"
        static let getStartedButton = "GetStartedButton"
        static let skipToChatButton = "SkipToChatButton"
    }
}
