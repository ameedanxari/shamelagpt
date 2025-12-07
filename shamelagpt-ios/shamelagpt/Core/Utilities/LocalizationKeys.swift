//
//  LocalizationKeys.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Type-safe localization keys for the app
enum LocalizationKeys {

    // MARK: - Navigation & Tabs

    static let chat = "chat"
    static let history = "history"
    static let settings = "settings"
    static let shamelaGPT = "shamelaGPT"
    static let back = "back"
    static let done = "done"
    static let cancel = "cancel"

    // MARK: - Chat Screen

    static let askQuestionPlaceholder = "chat.placeholder"
    static let sendMessage = "chat.send"
    static let voiceInput = "chat.voiceInput"
    static let imageTextRecognition = "chat.imageTextRecognition"
    static let recording = "chat.recording"
    static let extractingText = "chat.extractingText"
    static let thinking = "chat.thinking"
    static let loadingMessages = "chat.loadingMessages"
    static let startConversation = "chat.startConversation"
    static let noMessagesYet = "chat.noMessagesYet"
    static let newConversation = "chat.newConversation"
    static let newConversationWarningTitle = "chat.newConversationWarningTitle"
    static let newConversationWarningMessage = "chat.newConversationWarningMessage"
    static let viewHistory = "chat.viewHistory"

    // MARK: - History Screen

    static let clearAll = "history.clearAll"
    static let newChat = "history.newChat"
    static let noConversations = "history.noConversations"
    static let startNewChatToBegin = "history.startNewChatToBegin"
    static let deleteConversation = "history.deleteConversation"
    static let deleteConversationMessage = "history.deleteConversationMessage"
    static let deleteAllConversations = "history.deleteAllConversations"
    static let deleteAllConversationsMessage = "history.deleteAllConversationsMessage"
    static let loadingConversations = "history.loadingConversations"
    static let share = "history.share"
    static let delete = "common.delete"
    static let localOnlyBadge = "history.localOnly"

    // MARK: - Settings Screen

    static let general = "settings.general"
    static let support = "settings.support"
    static let about = "settings.about"
    static let language = "settings.language"
    static let supportShamelaGPT = "settings.supportShamelaGPT"
    static let aboutShamelaGPT = "settings.aboutShamelaGPT"
    static let privacyPolicy = "settings.privacyPolicy"
    static let privacyPolicySectionIntro = "privacy.intro"
    static let privacyPolicySectionInfo = "privacy.info"
    static let privacyPolicySectionUsage = "privacy.usage"
    static let privacyPolicySectionSecurity = "privacy.security"
    static let privacyPolicySectionRights = "privacy.rights"
    static let privacyPolicySectionContact = "privacy.contact"
    static let termsOfService = "settings.termsOfService"
    static let termsSectionAcceptance = "terms.acceptance"
    static let termsSectionDescription = "terms.description"
    static let termsSectionResponsibilities = "terms.responsibilities"
    static let termsSectionDisclaimer = "terms.disclaimer"
    static let termsSectionIP = "terms.ip"
    static let termsSectionLiability = "terms.liability"
    static let termsSectionChanges = "terms.changes"
    static let termsSectionContact = "terms.contact"
    static let languageFontRestartNote = "language.fontRestartNote"
    static let settingsVersion = "settings.version"
    static let aiPreferences = "settings.aiPreferences"
    static let aiPreferencesLockedTitle = "settings.aiPreferencesLockedTitle"
    static let aiPreferencesLockedMessage = "settings.aiPreferencesLockedMessage"
    static let signInButton = "settings.signInButton"
    static let signOut = "settings.signOut"
    static let refreshPreferences = "settings.refreshPreferences"
    static let customPromptTitle = "settings.customPrompt.title"
    static let customPromptPlaceholder = "settings.customPrompt.placeholder"
    static let customPromptEditTitle = "settings.customPrompt.editTitle"
    // Preference option titles and values
    static let prefLengthTitle = "settings.pref.length.title"
    static let prefLengthShort = "settings.pref.length.short"
    static let prefLengthMedium = "settings.pref.length.medium"
    static let prefLengthDetailed = "settings.pref.length.detailed"

    static let prefStyleTitle = "settings.pref.style.title"
    static let prefStyleConversational = "settings.pref.style.conversational"
    static let prefStyleAcademic = "settings.pref.style.academic"
    static let prefStyleTechnical = "settings.pref.style.technical"

    static let prefFocusTitle = "settings.pref.focus.title"
    static let prefFocusPractical = "settings.pref.focus.practical"
    static let prefFocusTheoretical = "settings.pref.focus.theoretical"
    static let prefFocusHistorical = "settings.pref.focus.historical"
    static let prefCurrent = "settings.pref.current"

    // History
    static let historyLockedTitle = "history.lockedTitle"
    static let historyLockedMessage = "history.lockedMessage"

    // MARK: - Welcome Screen

    static let welcomeTitle = "welcome.title"
    static let welcomeIntro = "welcome.intro"
    static let welcomeSignInTitle = "welcome.signInTitle"
    static let welcomeSignInMessage = "welcome.signInMessage"
    static let getStarted = "welcome.getStarted"
    static let skipToChat = "welcome.skipToChat"

    // MARK: - Empty States

    static let emptyStateDescription = "empty.description"
    static let emptyStateTryAsking = "empty.tryAsking"
    static let emptyStateSuggestion1 = "empty.suggestion1"
    static let emptyStateSuggestion2 = "empty.suggestion2"
    static let emptyStateSuggestion3 = "empty.suggestion3"

    // MARK: - Error Messages

    static let error = "error.title"
    static let noInternetConnection = "error.noInternetConnection"
    static let unableToConnect = "error.unableToConnect"
    static let permissionRequired = "error.permissionRequired"
    static let somethingWentWrong = "error.somethingWentWrong"
    static let failedToLoadData = "error.failedToLoadData"
    static let tryAgain = "error.tryAgain"
    static let openSettings = "error.openSettings"
    static let retry = "error.retry"
    static let ok = "common.ok"
    static let save = "common.save"

    // MARK: - Network Errors

    static let networkInvalidURL = "network.invalidURL"
    static let networkInvalidResponse = "network.invalidResponse"
    static let networkNoConnection = "network.noConnection"
    static let networkTimeout = "network.timeout"
    static let networkUnknownError = "network.unknownError"
    static let networkInvalidRequest = "network.invalidRequest"
    static let networkAuthRequired = "network.authRequired"
    static let networkAccessForbidden = "network.accessForbidden"
    static let networkResourceNotFound = "network.resourceNotFound"
    static let networkTooManyRequests = "network.tooManyRequests"
    static let networkServerError = "network.serverError"
    static let networkGenericError = "network.genericError"
    static let networkDecodingError = "network.decodingError"
    static let networkCheckConnection = "network.checkConnection"
    static let networkUnexpectedError = "network.unexpectedError"

    // MARK: - About Screen

    static let aboutContent = "about.content"
    static let aboutMissionTitle = "about.missionTitle"
    static let aboutMission = "about.mission"
    static let aboutDataSourceTitle = "about.dataSourceTitle"
    static let aboutDataSource = "about.dataSource"

    // MARK: - Accessibility

    static let logoAccessibilityLabel = "accessibility.logo"
    static let getStartedAccessibilityHint = "accessibility.getStartedHint"
    static let skipToChatAccessibilityHint = "accessibility.skipToChatHint"
    static let chatTabAccessibilityHint = "accessibility.chatTabHint"
    static let historyTabAccessibilityHint = "accessibility.historyTabHint"
    static let settingsTabAccessibilityHint = "accessibility.settingsTabHint"
    static let sendMessageAccessibilityHint = "accessibility.sendMessageHint"
    static let cameraAccessibilityLabel = "accessibility.camera"
    static let cameraAccessibilityHint = "accessibility.cameraHint"
    static let microphoneStartAccessibilityLabel = "accessibility.microphoneStart"
    static let microphoneStopAccessibilityLabel = "accessibility.microphoneStop"
    static let microphoneStartAccessibilityHint = "accessibility.microphoneStartHint"
    static let microphoneStopAccessibilityHint = "accessibility.microphoneStopHint"
    static let microphoneRecordingValue = "accessibility.microphoneRecordingValue"
    static let microphoneNotRecordingValue = "accessibility.microphoneNotRecordingValue"
    static let openSettingsAccessibilityHint = "accessibility.openSettingsHint"
    static let tryAgainAccessibilityHint = "accessibility.tryAgainHint"

    // MARK: - Image Picker

    static let imagePickerAddImage = "imagePicker.addImage"
    static let imagePickerTakePhoto = "imagePicker.takePhoto"
    static let imagePickerChooseFromLibrary = "imagePicker.chooseFromLibrary"

    // MARK: - Auth Screen

    static let authSignIn = "auth.signIn"
    static let authSignUp = "auth.signUp"
    static let authCreateAccount = "auth.createAccount"
    static let authEmail = "auth.email"
    static let authPassword = "auth.password"
    static let authDisplayName = "auth.displayName"
    static let authContinueAsGuest = "auth.continueAsGuest"
    static let authNeedAccount = "auth.needAccount"
    static let authHaveAccount = "auth.haveAccount"
    static let authSignInButton = "auth.signInButton"

    // MARK: - Permission Messages

    static func permissionMessage(_ type: String) -> String {
        return String(format: NSLocalizedString("permission.message", comment: ""), type)
    }
}

/// Extension to provide convenience method for localized strings
extension String {
    /// Returns a localized string for the given key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns a localized string with formatted arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
