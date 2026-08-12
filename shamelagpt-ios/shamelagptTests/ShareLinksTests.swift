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

    override func setUpWithError() throws {
        mockGetConversationsUseCase = MockGetConversationsUseCase()
        mockDeleteConversationUseCase = MockDeleteConversationUseCase()
        mockChatRepository = MockChatRepository()

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
    }

    // MARK: - Helpers

    private func makeConversation(id: String = "conv-1") -> Conversation {
        Conversation(id: id, title: "Shareable", messages: [Message.preview])
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
}
