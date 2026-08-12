//
//  ShareLinksTests.swift
//  shamelagptTests
//
//  Tests for server-side conversation sharing and share-link normalization
//

import XCTest
import Combine
@testable import ShamelaGPT

@MainActor
final class ShareLinksTests: XCTestCase {

    var viewModel: HistoryViewModel!
    var mockGetConversationsUseCase: MockGetConversationsUseCase!
    var mockDeleteConversationUseCase: MockDeleteConversationUseCase!
    var mockChatRepository: MockChatRepository!
    var mockSendMessageUseCase: MockSendMessageUseCase!
    var mockAuthRepository: MockAuthRepository!
    var mockVoiceInputManager: MockVoiceInputManager!
    var mockOCRManager: MockOCRManager!

    override func setUpWithError() throws {
        mockGetConversationsUseCase = MockGetConversationsUseCase()
        mockDeleteConversationUseCase = MockDeleteConversationUseCase()
        mockChatRepository = MockChatRepository()
        mockSendMessageUseCase = MockSendMessageUseCase()
        mockAuthRepository = MockAuthRepository()
        mockAuthRepository.mockIsLoggedIn = true
        mockVoiceInputManager = MockVoiceInputManager()
        mockOCRManager = MockOCRManager()

        viewModel = HistoryViewModel(
            getConversationsUseCase: mockGetConversationsUseCase,
            deleteConversationUseCase: mockDeleteConversationUseCase,
            chatRepository: mockChatRepository
        )
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockGetConversationsUseCase = nil
        mockDeleteConversationUseCase = nil
        mockChatRepository = nil
        mockSendMessageUseCase = nil
        mockAuthRepository = nil
        mockVoiceInputManager = nil
        mockOCRManager = nil
    }

    // MARK: - Helpers

    private func makeConversation(id: String = "conv-1") -> Conversation {
        Conversation(id: id, title: "Shareable", messages: [Message.preview])
    }

    /// Builds an authenticated chat view model bound to a persisted conversation,
    /// which is the only configuration in which the share control is offered.
    private func makeChatViewModel(
        conversationId: String? = "chat-conv-1",
        isGuest: Bool = false
    ) -> ChatViewModel {
        ChatViewModel(
            conversationId: conversationId,
            sendMessageUseCase: mockSendMessageUseCase,
            chatRepository: mockChatRepository,
            apiClient: nil,
            authRepository: mockAuthRepository,
            isGuest: isGuest,
            guestSessionId: nil,
            voiceInputManager: mockVoiceInputManager,
            ocrManager: mockOCRManager
        )
    }

    // MARK: - enableSharing

    func testEnableSharingCallsRepositoryWithIsSharedTrue() async throws {
        // Given
        let conversation = makeConversation(id: "conv-abc")
        mockChatRepository.shareURLToReturn = "https://shamelagpt.com/shared?chatid=conv-abc"

        // When
        _ = try await viewModel.enableSharing(for: conversation)

        // Then
        XCTAssertTrue(mockChatRepository.setConversationSharedCalled)
        XCTAssertEqual(mockChatRepository.setConversationSharedCallCount, 1)
        XCTAssertEqual(mockChatRepository.lastSetConversationSharedId, "conv-abc")
        XCTAssertEqual(mockChatRepository.lastSetConversationSharedValue, true)
    }

    func testEnableSharingReturnsServerProvidedURL() async throws {
        // Given - the server already emits the working query form
        let conversation = makeConversation(id: "conv-abc")
        mockChatRepository.shareURLToReturn = "https://shamelagpt.com/shared?chatid=server-supplied-id"

        // When
        let url = try await viewModel.enableSharing(for: conversation)

        // Then - taken verbatim, not rebuilt from the local id
        XCTAssertEqual(url, "https://shamelagpt.com/shared?chatid=server-supplied-id")
    }

    func testEnableSharingFallsBackToChatIdFormWhenServerReturnsNil() async throws {
        // Given
        let conversation = makeConversation(id: "conv-xyz")
        mockChatRepository.shareURLToReturn = nil

        // When
        let url = try await viewModel.enableSharing(for: conversation)

        // Then
        XCTAssertEqual(url, "https://shamelagpt.com/shared?chatid=conv-xyz")
    }

    func testEnableSharingNormalizesLegacyPathSegmentURLFromServer() async throws {
        // Given - a backend that has not shipped the query-form fix yet
        let conversation = makeConversation(id: "conv-legacy")
        mockChatRepository.shareURLToReturn = "https://shamelagpt.com/shared/conv-legacy"

        // When
        let url = try await viewModel.enableSharing(for: conversation)

        // Then - the client repairs the link rather than handing out a dead one
        XCTAssertEqual(url, "https://shamelagpt.com/shared?chatid=conv-legacy")
    }

    func testEnableSharingPropagatesRepositoryError() async {
        // Given
        let conversation = makeConversation()
        let expected = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Share failed"])
        mockChatRepository.setConversationSharedError = expected

        // When / Then
        do {
            _ = try await viewModel.enableSharing(for: conversation)
            XCTFail("enableSharing should rethrow the repository error")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "test")
            XCTAssertEqual(nsError.code, 42)
        }
        XCTAssertTrue(mockChatRepository.setConversationSharedCalled)
    }

    // MARK: - ShareLink.normalize

    func testNormalizeReturnsCanonicalLinkWhenRawIsNil() {
        let result = ShareLink.normalize(nil, conversationId: "abc-123")
        XCTAssertEqual(result, "https://shamelagpt.com/shared?chatid=abc-123")
    }

    func testNormalizeReturnsCanonicalLinkWhenRawIsEmpty() {
        let result = ShareLink.normalize("   ", conversationId: "abc-123")
        XCTAssertEqual(result, "https://shamelagpt.com/shared?chatid=abc-123")
    }

    func testNormalizeLeavesQueryFormUntouched() {
        let raw = "https://shamelagpt.com/shared?chatid=abc-123"
        XCTAssertEqual(ShareLink.normalize(raw, conversationId: "abc-123"), raw)
    }

    func testNormalizeConvertsLegacyPathSegmentForm() {
        // The exact shape the old backend emits.
        let uuid = "f1e2d3c4-5678-90ab-cdef-1234567890ab"
        let raw = "https://shamelagpt.com/shared/\(uuid)"

        let result = ShareLink.normalize(raw, conversationId: uuid)

        XCTAssertEqual(result, "https://shamelagpt.com/shared?chatid=\(uuid)")
    }

    func testNormalizePreservesNonProductionOrigin() {
        let uuid = "f1e2d3c4-5678-90ab-cdef-1234567890ab"
        let raw = "https://staging.shamelagpt.com/shared/\(uuid)"

        let result = ShareLink.normalize(raw, conversationId: uuid)

        XCTAssertEqual(result, "https://staging.shamelagpt.com/shared?chatid=\(uuid)")
    }

    func testNormalizePreservesOriginWithExplicitPort() {
        let raw = "http://localhost:3000/shared/abc-123"

        let result = ShareLink.normalize(raw, conversationId: "abc-123")

        XCTAssertEqual(result, "http://localhost:3000/shared?chatid=abc-123")
    }

    func testNormalizeFallsBackWhenRawIsUnparseable() {
        // No scheme/host to rebuild an origin from.
        let result = ShareLink.normalize("not a url at all", conversationId: "abc-123")
        XCTAssertEqual(result, "https://shamelagpt.com/shared?chatid=abc-123")
    }

    func testNormalizeFallsBackWhenPathIsUnrelated() {
        let result = ShareLink.normalize("https://shamelagpt.com/pricing", conversationId: "abc-123")
        XCTAssertEqual(result, "https://shamelagpt.com/shared?chatid=abc-123")
    }

    // MARK: - ChatViewModel visibility

    func testChatCanShareWhenAuthenticatedWithPersistedConversation() {
        XCTAssertTrue(makeChatViewModel().canShareConversation)
    }

    func testChatCannotShareBrandNewConversationWithoutId() {
        XCTAssertFalse(makeChatViewModel(conversationId: nil).canShareConversation)
        XCTAssertFalse(makeChatViewModel(conversationId: "   ").canShareConversation)
    }

    func testChatCannotShareAsGuest() {
        XCTAssertFalse(makeChatViewModel(isGuest: true).canShareConversation)
    }

    func testChatCannotShareWhenSignedOut() {
        mockAuthRepository.mockIsLoggedIn = false
        XCTAssertFalse(makeChatViewModel().canShareConversation)
    }

    // MARK: - ChatViewModel toggling

    func testChatSetSharingOnCallsRepositoryAndExposesNormalizedURL() async {
        // Given - an older backend that still returns the legacy path form
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        mockChatRepository.shareURLToReturn = "https://shamelagpt.com/shared/chat-conv-1"

        // When
        await chatViewModel.setSharing(true)

        // Then
        XCTAssertTrue(mockChatRepository.setConversationSharedCalled)
        XCTAssertEqual(mockChatRepository.lastSetConversationSharedId, "chat-conv-1")
        XCTAssertEqual(mockChatRepository.lastSetConversationSharedValue, true)
        XCTAssertTrue(chatViewModel.isShared)
        XCTAssertEqual(chatViewModel.shareURL, "https://shamelagpt.com/shared?chatid=chat-conv-1")
        XCTAssertFalse(chatViewModel.isSharePopoverLoading)
    }

    func testChatSetSharingOffCallsRepositoryAndClearsURL() async {
        // Given - already shared
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        await chatViewModel.setSharing(true)
        XCTAssertNotNil(chatViewModel.shareURL)

        // When
        await chatViewModel.setSharing(false)

        // Then
        XCTAssertEqual(mockChatRepository.setConversationSharedCallCount, 2)
        XCTAssertEqual(mockChatRepository.lastSetConversationSharedValue, false)
        XCTAssertFalse(chatViewModel.isShared)
        XCTAssertNil(chatViewModel.shareURL)
    }

    func testChatSetSharingRevertsToggleWhenRepositoryFails() async {
        // Given
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        mockChatRepository.setConversationSharedError = NSError(
            domain: "test",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Share failed"]
        )

        // When
        await chatViewModel.setSharing(true)

        // Then - never leave the switch implying a private chat is public
        XCTAssertTrue(mockChatRepository.setConversationSharedCalled)
        XCTAssertFalse(chatViewModel.isShared)
        XCTAssertNil(chatViewModel.shareURL)
        XCTAssertFalse(chatViewModel.isSharePopoverLoading)
        XCTAssertNotNil(chatViewModel.errorMessage)
    }

    func testChatSetSharingOffRevertsToOnWhenRepositoryFails() async {
        // Given - shared, then the un-share PUT is rejected
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        await chatViewModel.setSharing(true)
        let sharedURL = chatViewModel.shareURL
        mockChatRepository.setConversationSharedError = NSError(domain: "test", code: 500, userInfo: nil)

        // When
        await chatViewModel.setSharing(false)

        // Then
        XCTAssertTrue(chatViewModel.isShared)
        XCTAssertEqual(chatViewModel.shareURL, sharedURL)
    }

    // MARK: - ChatViewModel status seeding

    func testChatLoadShareStatusSeedsIsSharedFromServer() async {
        // Given - the conversation was already published elsewhere
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        mockChatRepository.mockShareStatus = ShareStatusResponse(
            conversationId: "chat-conv-1",
            isShared: true,
            shareUrl: "https://shamelagpt.com/shared/chat-conv-1"
        )

        // When
        await chatViewModel.loadShareStatus()

        // Then
        XCTAssertEqual(mockChatRepository.conversationShareStatusCallCount, 1)
        XCTAssertEqual(mockChatRepository.lastConversationShareStatusId, "chat-conv-1")
        XCTAssertTrue(chatViewModel.isShared)
        XCTAssertEqual(chatViewModel.shareURL, "https://shamelagpt.com/shared?chatid=chat-conv-1")
        XCTAssertFalse(chatViewModel.isSharePopoverLoading)
    }

    func testChatLoadShareStatusSeedsUnsharedAndLeavesNoLink() async {
        // Given
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        mockChatRepository.mockShareStatus = ShareStatusResponse(
            conversationId: "chat-conv-1",
            isShared: false,
            shareUrl: nil
        )

        // When
        await chatViewModel.loadShareStatus()

        // Then
        XCTAssertFalse(chatViewModel.isShared)
        XCTAssertNil(chatViewModel.shareURL)
    }

    func testChatLoadShareStatusSkippedForGuest() async {
        // Given
        let chatViewModel = makeChatViewModel(isGuest: true)

        // When
        await chatViewModel.loadShareStatus()

        // Then - the endpoint is auth-protected; never call it as a guest
        XCTAssertEqual(mockChatRepository.conversationShareStatusCallCount, 0)
        XCTAssertFalse(chatViewModel.isShared)
    }

    func testChatLoadShareStatusSurfacesErrorAndLeavesToggleOff() async {
        // Given
        let chatViewModel = makeChatViewModel(conversationId: "chat-conv-1")
        mockChatRepository.conversationShareStatusError = NSError(domain: "test", code: 503, userInfo: nil)

        // When
        await chatViewModel.loadShareStatus()

        // Then
        XCTAssertFalse(chatViewModel.isShared)
        XCTAssertNil(chatViewModel.shareURL)
        XCTAssertNotNil(chatViewModel.errorMessage)
    }
}
