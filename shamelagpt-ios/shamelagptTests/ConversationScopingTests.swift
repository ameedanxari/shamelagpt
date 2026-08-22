//
//  ConversationScopingTests.swift
//  shamelagptTests
//
//  Locally cached conversations are filed under an owner and every fetch is scoped to
//  the current one. Clearing the cache on logout only covers the path where logout
//  actually runs; these tests cover the paths where it does not — a session that expires
//  or is revoked server-side, a wipe that throws, and switching accounts — plus the rows
//  that predate scoping and belong to nobody.
//

import XCTest
import CoreData
@testable import ShamelaGPT

final class ConversationScopingTests: XCTestCase {

    private var coreDataStack: TestCoreDataStack!
    private var conversationDAO: ConversationDAO!
    private var messageDAO: MessageDAO!
    private var defaults: UserDefaults!
    private var sessionManager: SessionManager!

    private let userA = "firebase-uid-a"
    private let userB = "firebase-uid-b"

    override func setUpWithError() throws {
        coreDataStack = TestCoreDataStack()
        conversationDAO = ConversationDAO()
        messageDAO = MessageDAO()
        defaults = UserDefaults(suiteName: "ConversationScopingTests")!
        defaults.removePersistentDomain(forName: "ConversationScopingTests")
        // useKeychain: false keeps tokens in the same throwaway suite as everything else,
        // so a test run cannot leave anything behind in the real keychain.
        sessionManager = SessionManager(defaults: defaults, useKeychain: false)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: "ConversationScopingTests")
        sessionManager = nil
        defaults = nil
        messageDAO = nil
        conversationDAO = nil
        coreDataStack = nil
    }

    // MARK: - Scoping

    func testOneUsersConversationsAreInvisibleToAnother() async throws {
        // Given - user A has history on this device
        let repository = makeRepository()
        sessionManager.setCurrentUserId(userA)
        let conversation = try await repository.createConversation(title: "Ruling on travel prayer")
        _ = try await repository.addMessage(
            toConversation: conversation.id,
            content: "Something personal",
            isUserMessage: true,
            sources: []
        )
        let beforeSwitch = try await repository.fetchAllConversations()
        XCTAssertEqual(beforeSwitch.count, 1)

        // When - user B is the one signed in
        sessionManager.setCurrentUserId(userB)

        // Then - none of it is reachable, by any route
        let visible = try await repository.fetchAllConversations()
        XCTAssertTrue(visible.isEmpty, "User A's conversations must not be listed for user B")
        let byId = try await repository.fetchConversation(byId: conversation.id)
        XCTAssertNil(byId, "Holding the id must not be enough to read another account's conversation")
        let messages = try await repository.fetchMessages(forConversation: conversation.id)
        XCTAssertTrue(messages.isEmpty, "Message bodies must be scoped along with their conversation")

        // And user A still has it when they come back
        sessionManager.setCurrentUserId(userA)
        let backForA = try await repository.fetchAllConversations()
        XCTAssertEqual(backForA.count, 1)
    }

    func testThreadIdLookupIsScopedToTheOwner() async throws {
        // The chat flow resolves conversations by thread id as well as by id, so scoping
        // one and not the other would leave the door open.
        let repository = makeRepository()
        sessionManager.setCurrentUserId(userA)
        let conversation = try await repository.createConversation(title: "Zakat on savings")
        try await repository.updateConversationThreadId(id: conversation.id, threadId: "thread-a")

        sessionManager.setCurrentUserId(userB)
        let found = try await repository.fetchConversation(byThreadId: "thread-a")
        XCTAssertNil(found)
    }

    func testAnEmptyConversationIsNotReusedAcrossAccounts() async throws {
        // Opening the chat tab reuses the most recent empty conversation rather than
        // creating another. Unscoped, user B would be handed user A's row and start
        // writing into it.
        let repository = makeRepository()
        sessionManager.setCurrentUserId(userA)
        _ = try await repository.createConversation(title: "New Chat")

        sessionManager.setCurrentUserId(userB)
        let reused = try await repository.fetchMostRecentEmptyConversation()
        XCTAssertNil(reused)
    }

    func testDeletingAllConversationsOnlyTouchesTheSignedInAccount() async throws {
        // Given - both accounts have cached history
        let repository = makeRepository(apiClient: MockAPIClient())
        sessionManager.setCurrentUserId(userA)
        _ = try await repository.createConversation(title: "A's chat")
        sessionManager.setCurrentUserId(userB)
        _ = try await repository.createConversation(title: "B's chat")

        // When - B clears their history
        try await repository.deleteAllConversations()

        // Then - A's cache is untouched. "Delete all my conversations" is a statement
        // about one account; the device-wide sweep belongs to the logout wipe.
        let remainingForB = try await repository.fetchAllConversations()
        XCTAssertTrue(remainingForB.isEmpty)
        sessionManager.setCurrentUserId(userA)
        let remainingForA = try await repository.fetchAllConversations()
        XCTAssertEqual(remainingForA.map(\.title), ["A's chat"])
    }

    // MARK: - Rows that predate scoping

    func testLegacyRowsWithNoOwnerAreShownToNobody() async throws {
        // Given - a conversation written by a build that had no owner column
        try insertLegacyConversation(id: "legacy-1", title: "Written before scoping")

        // Then - it is not offered to any signed-in account...
        let repository = makeRepository()
        sessionManager.setCurrentUserId(userA)
        let forA = try await repository.fetchAllConversations()
        XCTAssertTrue(forA.isEmpty)
        sessionManager.setCurrentUserId(userB)
        let forB = try await repository.fetchAllConversations()
        XCTAssertTrue(forB.isEmpty)

        // ...nor to a guest, whose identity is the device-local guest session id
        sessionManager.clearSession()
        sessionManager.setGuest(true)
        let forGuest = try await repository.fetchAllConversations()
        XCTAssertTrue(forGuest.isEmpty)

        // It is hidden rather than deleted: it could belong to anyone, which rules out
        // showing it, but the app has no evidence it is junk either, and a local-only
        // conversation has no server copy to restore. The logout wipe collects it.
        XCTAssertEqual(
            try conversationDAO.fetchAllIgnoringOwner(from: coreDataStack.viewContext).count,
            1,
            "A legacy row is withheld, not destroyed"
        )
    }

    func testSyncAdoptsALegacyRowTheServerStillListsForTheAccount() async throws {
        // Given - a legacy row whose id the server still reports for user A. This is the
        // ordinary upgrade path: the cache predates scoping, but the server can vouch for
        // who owns each id.
        try insertLegacyConversation(id: "server-1", title: "Stale local title")

        let apiClient = MockAPIClient()
        apiClient.mockListConversationsResponse = [
            ConversationResponse(
                id: "server-1",
                threadId: "thread-1",
                title: "Ruling on travel prayer",
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-02T00:00:00Z"
            )
        ]
        let repository = makeRepository(apiClient: apiClient)
        sessionManager.setCurrentUserId(userA)

        // When
        try await repository.syncRemoteConversations(forceRefresh: true)

        // Then - the row is claimed rather than duplicated, so nothing is lost and nothing
        // is doubled up
        let all = try conversationDAO.fetchAllIgnoringOwner(from: coreDataStack.viewContext)
        XCTAssertEqual(all.count, 1, "The upsert must claim the legacy row, not insert a second one")
        XCTAssertEqual(all.first?.ownerId, userA)

        let visible = try await repository.fetchAllConversations()
        XCTAssertEqual(visible.map(\.title), ["Ruling on travel prayer"])

        // And it is still invisible to anyone else
        sessionManager.setCurrentUserId(userB)
        let forB = try await repository.fetchAllConversations()
        XCTAssertTrue(forB.isEmpty)
    }

    // MARK: - The paths logout never runs on

    func testAnExpiredSessionsCacheIsInvisibleToTheNextAccount() async throws {
        // Given - user A is signed in with history cached
        let repository = makeRepository()
        sessionManager.saveSession(token: "token-a", refreshToken: "refresh-a", expiresInSeconds: 3600)
        sessionManager.setCurrentUserId(userA)
        _ = try await repository.createConversation(title: "A's private question")

        // When - the session dies server-side. Nothing calls logout(), so the cache is
        // still on disk; only the token stops working.
        sessionManager.clearSession()
        XCTAssertFalse(sessionManager.isLoggedIn())
        XCTAssertNil(sessionManager.currentUserId(), "Ending a session must forget who it belonged to")

        // ...and user B signs in on the same device
        let authRepository = AuthRepositoryImpl(
            apiClient: StubAuthAPIClient(firebaseUid: userB),
            sessionManager: sessionManager
        )
        _ = try await authRepository.login(request: LoginRequest(email: "b@example.com", password: "pw"))

        // Then - the orphaned cache is simply never shown
        XCTAssertEqual(sessionManager.currentUserId(), userB)
        let visibleToB = try await repository.fetchAllConversations()
        XCTAssertTrue(visibleToB.isEmpty)
    }

    func testAWipeThatThrowsStillLeavesNothingReadableToTheNextAccount() async throws {
        // Given - user A is signed in with history cached
        let repository = makeRepository()
        sessionManager.saveSession(token: "token-a", refreshToken: "refresh-a", expiresInSeconds: 3600)
        sessionManager.setCurrentUserId(userA)
        _ = try await repository.createConversation(title: "A's private question")

        // When - logout runs but the wipe fails. The error is logged and swallowed, so the
        // session ends and the data stays.
        let failingRepository = MockChatRepository()
        failingRepository.shouldThrowError = true
        let authRepository = AuthRepositoryImpl(
            apiClient: StubAuthAPIClient(firebaseUid: userB),
            sessionManager: sessionManager,
            chatRepository: failingRepository
        )
        await authRepository.logout()

        XCTAssertEqual(failingRepository.clearLocalDataCallCount, 1)
        XCTAssertEqual(
            try conversationDAO.fetchAllIgnoringOwner(from: coreDataStack.viewContext).count,
            1,
            "Precondition: the wipe failed, so the row is still on disk"
        )

        // Then - user B signs in and cannot read it anyway
        _ = try await authRepository.login(request: LoginRequest(email: "b@example.com", password: "pw"))
        let visibleToB = try await repository.fetchAllConversations()
        XCTAssertTrue(visibleToB.isEmpty)
    }

    func testSwitchingAccountsKeepsBothCachesSeparate() async throws {
        // Account switching used to round-trip through a full delete and re-download.
        // Scoped caches mean neither account's rows have to be destroyed to hide them from
        // the other, so switching back does not re-fetch what is already there.
        let repository = makeRepository()
        sessionManager.setCurrentUserId(userA)
        _ = try await repository.createConversation(title: "A's chat")
        sessionManager.setCurrentUserId(userB)
        _ = try await repository.createConversation(title: "B's chat")

        let forB = try await repository.fetchAllConversations()
        XCTAssertEqual(forB.map(\.title), ["B's chat"])
        sessionManager.setCurrentUserId(userA)
        let forA = try await repository.fetchAllConversations()
        XCTAssertEqual(forA.map(\.title), ["A's chat"])
    }

    // MARK: - Identity

    func testSessionOwnerFallsBackToTheGuestSessionId() {
        // A guest is a real user of the app with real conversations, so they need an
        // identity too — the existing device-local guest session id, rather than a second
        // notion of who is using the app.
        XCTAssertNil(sessionManager.conversationOwnerId(), "No account and no guest means nobody")

        sessionManager.setGuest(true)
        let guestOwner = sessionManager.conversationOwnerId()
        XCTAssertNotNil(guestOwner)
        XCTAssertEqual(guestOwner, sessionManager.guestSessionId())

        // A signed-in account outranks the guest id, which survives in UserDefaults
        sessionManager.setCurrentUserId(userA)
        XCTAssertEqual(sessionManager.conversationOwnerId(), userA)
    }

    func testClearingTheSessionForgetsWhoItBelongedTo() {
        sessionManager.saveSession(token: "token", refreshToken: "refresh", expiresInSeconds: 3600)
        sessionManager.setCurrentUserId(userA)

        sessionManager.clearSession()

        // Leaving the id behind would let anything running after the session ended keep
        // resolving an owner, and reading that owner's cache.
        XCTAssertNil(sessionManager.currentUserId())
        XCTAssertNil(sessionManager.conversationOwnerId())
    }

    func testAuthResponseReadsIdentityFromFirebaseUidOnly() {
        let response = AuthResponse(
            token: "t",
            refreshToken: "r",
            expiresIn: "3600",
            user: ["id": AnyCodable("database-row-id"), "firebaseUid": AnyCodable(userA)]
        )
        XCTAssertEqual(response.firebaseUserId, userA)

        // The database `id` is deliberately not a fallback: `GET /api/auth/me` answers with
        // firebaseUid, so accepting `id` here would file one account under two owners
        // depending on which call resolved it first.
        let withoutUid = AuthResponse(
            token: "t",
            refreshToken: "r",
            expiresIn: "3600",
            user: ["id": AnyCodable("database-row-id")]
        )
        XCTAssertNil(withoutUid.firebaseUserId)
    }

    /// `.convertFromSnakeCase` rewrites coding keys, generated from a type's properties.
    /// A dictionary decoded as `[String: _]` has no properties to match against, so its
    /// keys are left exactly as the server sent them — verified against the live payload.
    /// Reading the camelCased spelling alone silently yielded nil for every sign-in.
    func testAuthResponseDecodesTheSnakeCasedPayloadKey() throws {
        let json = Data(#"{"token":"t","refresh_token":"r","expires_in":"3600","user":{"firebase_uid":"firebase-uid-a"}}"#.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(AuthResponse.self, from: json)

        XCTAssertEqual(response.firebaseUserId, userA)
    }

    /// Defensive: also accept the camelCased spelling, in case the payload is ever decoded
    /// by a path that does convert or the backend switches.
    func testAuthResponseAlsoAcceptsTheCamelCasedPayloadKey() throws {
        let json = Data(#"{"token":"t","refresh_token":"r","expires_in":"3600","user":{"firebaseUid":"firebase-uid-a"}}"#.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(AuthResponse.self, from: json)

        XCTAssertEqual(response.firebaseUserId, userA)
    }

    func testSigningInRecordsTheAccountBeforeTheCacheIsWarmed() async throws {
        let authRepository = AuthRepositoryImpl(
            apiClient: StubAuthAPIClient(firebaseUid: userA),
            sessionManager: sessionManager
        )

        _ = try await authRepository.login(request: LoginRequest(email: "a@example.com", password: "pw"))

        XCTAssertEqual(sessionManager.currentUserId(), userA)
    }

    func testAskingWhoTheCurrentUserIsRecordsTheAnswer() async throws {
        // The backfill for sessions that predate scoping: a valid token, no recorded owner,
        // and no auth response coming because nothing needs refreshing.
        let apiClient = MockAPIClient()
        let authRepository = AuthRepositoryImpl(apiClient: apiClient, sessionManager: sessionManager)
        XCTAssertNil(sessionManager.currentUserId())

        let user = try await authRepository.getCurrentUser()

        XCTAssertEqual(sessionManager.currentUserId(), user.firebaseUid)
    }

    // MARK: - Sync freshness

    func testFreshnessMarkersDoNotCarryAcrossOwners() async throws {
        // The TTL is the only thing gating the network call. A marker left by user A is
        // recent and about the wrong person, so treating it as fresh would hold user B's
        // History empty for the rest of the window with their data sitting on the server.
        let freshnessStore = ConversationSyncFreshnessStore(userDefaults: defaults)
        let apiClient = MockAPIClient()
        let repository = makeRepository(apiClient: apiClient, freshnessStore: freshnessStore)

        sessionManager.setCurrentUserId(userA)
        try await repository.syncRemoteConversations(forceRefresh: true)
        XCTAssertEqual(apiClient.listConversationsCallCount, 1)

        // A second load for the same user is still served from cache
        try await repository.syncRemoteConversations(forceRefresh: false)
        XCTAssertEqual(apiClient.listConversationsCallCount, 1)

        // A different user goes back to the network immediately
        sessionManager.setCurrentUserId(userB)
        try await repository.syncRemoteConversations(forceRefresh: false)
        XCTAssertEqual(apiClient.listConversationsCallCount, 2)
    }

    // MARK: - Helpers

    private func makeRepository(
        apiClient: APIClientProtocol? = nil,
        freshnessStore: ConversationSyncFreshnessStore = ConversationSyncFreshnessStore(
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
    ) -> ChatRepositoryImpl {
        ChatRepositoryImpl(
            coreDataStack: coreDataStack,
            conversationDAO: conversationDAO,
            messageDAO: messageDAO,
            apiClient: apiClient,
            networkMonitor: apiClient == nil ? nil : MockNetworkMonitor(),
            freshnessStore: freshnessStore,
            currentOwnerId: { [sessionManager] in sessionManager?.conversationOwnerId() }
        )
    }

    /// Writes a conversation the way a build without the owner column would have: same
    /// shape, `ownerId` left nil.
    private func insertLegacyConversation(id: String, title: String) throws {
        let context = coreDataStack.viewContext
        conversationDAO.create(
            id: id,
            threadId: nil,
            title: title,
            ownerId: nil,
            in: context
        )
        try coreDataStack.save(context: context)
    }
}

// MARK: - Stub API client

/// Answers the auth endpoints with a chosen account and nothing else. `MockAPIClient`
/// returns a fixed user payload, and these tests need to say which account signs in.
private final class StubAuthAPIClient: MockAPIClient {
    private let firebaseUid: String

    init(firebaseUid: String) {
        self.firebaseUid = firebaseUid
        super.init()
    }

    private func authResponse() -> AuthResponse {
        AuthResponse(
            token: "token-\(firebaseUid)",
            refreshToken: "refresh-\(firebaseUid)",
            expiresIn: "3600",
            user: ["firebaseUid": AnyCodable(firebaseUid), "email": AnyCodable("\(firebaseUid)@example.com")]
        )
    }

    override func login(_ request: LoginRequest) async throws -> AuthResponse {
        authResponse()
    }

    override func signup(_ request: SignupRequest) async throws -> AuthResponse {
        authResponse()
    }
}
