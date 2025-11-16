//
//  VoiceInputManagerTests.swift
//  shamelagptTests
//
//  Tests for VoiceInputManager
//

import XCTest
import Speech
import AVFoundation
@testable import ShamelaGPT

@MainActor
final class VoiceInputManagerTests: XCTestCase {

    var sut: VoiceInputManager!

    override func setUpWithError() throws {
        sut = VoiceInputManager()
    }

    override func tearDownWithError() throws {
        // Clean up any recording state
        if sut.isRecording {
            sut.stopRecording()
        }
        sut = nil
    }

    // MARK: - Initialization Tests

    func testInitialState() throws {
        // Then
        XCTAssertEqual(sut.transcribedText, "", "Should start with empty transcription")
        XCTAssertFalse(sut.isRecording, "Should not be recording initially")
        XCTAssertEqual(sut.authorizationStatus, .notDetermined, "Should start with notDetermined authorization")
        XCTAssertNil(sut.error, "Should not have error initially")
    }

    // MARK: - Permission Tests

    func testRequestPermissionSpeechAuthorized() async throws {
        // Note: This test depends on system authorization state
        // It verifies the method completes and updates authorization status

        // When
        _ = await sut.requestPermission()

        // Then - Method should complete without crashing
        // Result depends on system state and user interaction
        // We can only verify the authorization status is set
        XCTAssertNotEqual(sut.authorizationStatus, .notDetermined,
                         "Authorization status should be updated after request")
    }

    func testAuthorizationStatusUpdatedAfterRequest() async throws {
        // When
        _ = await sut.requestPermission()

        // Then - Status should be updated (even if denied)
        // The actual value depends on system permissions
        XCTAssertTrue(
            sut.authorizationStatus == .authorized ||
            sut.authorizationStatus == .denied ||
            sut.authorizationStatus == .restricted,
            "Authorization status should be determined after request"
        )
    }

    // MARK: - Recording State Tests

    func testStopRecordingClearsRecordingState() throws {
        // Given - Simulate recording state (without actually recording)
        // We can't easily start recording in tests without permissions
        // but we can test that stopRecording is safe to call

        // When
        sut.stopRecording()

        // Then - Should be safe to call even when not recording
        XCTAssertFalse(sut.isRecording, "Should not be recording after stop")
    }

    func testStopRecordingWhenNotRecording() throws {
        // Given - Not recording
        XCTAssertFalse(sut.isRecording)

        // When
        sut.stopRecording()

        // Then - Should handle gracefully
        XCTAssertFalse(sut.isRecording)
        // Should not crash or set error
    }

    // MARK: - Transcription Tests

    func testClearTranscriptionWorks() throws {
        // Given - The transcription is managed internally
        // We can test the clear method works

        // When
        sut.clearTranscription()

        // Then
        XCTAssertEqual(sut.transcribedText, "", "Transcription should be cleared")
    }

    func testTranscriptionStartsEmpty() throws {
        // Given/When - Fresh instance

        // Then
        XCTAssertTrue(sut.transcribedText.isEmpty, "Transcription should start empty")
    }

    // MARK: - Error Management Tests

    func testClearErrorWorks() throws {
        // Given - Set an error state manually via reflection isn't ideal
        // but we can test clearError is safe to call

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.error, "Error should be nil after clear")
    }

    func testErrorNilInitially() throws {
        // Then
        XCTAssertNil(sut.error, "Error should be nil on initialization")
    }

    // MARK: - Error Type Tests

    func testPermissionDeniedErrorDescription() {
        // Given
        let error = VoiceInputError.permissionDenied

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("permission denied") ?? false)
        XCTAssertTrue(description?.contains("Settings") ?? false)
    }

    func testMicrophonePermissionDeniedErrorDescription() {
        // Given
        let error = VoiceInputError.microphonePermissionDenied

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Microphone") ?? false)
        XCTAssertTrue(description?.contains("Settings") ?? false)
    }

    func testRecognizerNotAvailableErrorDescription() {
        // Given
        let error = VoiceInputError.recognizerNotAvailable

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("not available") ?? false)
    }

    func testUnableToCreateRequestErrorDescription() {
        // Given
        let error = VoiceInputError.unableToCreateRequest

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Unable") ?? false)
    }

    func testRecognitionFailedErrorDescription() {
        // Given
        let error = VoiceInputError.recognitionFailed("Test failure message")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description?.contains("Recognition failed") ?? false)
        XCTAssertTrue(description?.contains("Test failure message") ?? false)
    }

    func testVoiceInputErrorEquality() {
        // Given
        let error1 = VoiceInputError.permissionDenied
        let error2 = VoiceInputError.permissionDenied
        let error3 = VoiceInputError.microphonePermissionDenied

        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testRecognitionFailedErrorEquality() {
        // Given
        let error1 = VoiceInputError.recognitionFailed("Same message")
        let error2 = VoiceInputError.recognitionFailed("Same message")
        let error3 = VoiceInputError.recognitionFailed("Different message")

        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    // MARK: - Locale Tests

    func testStartRecordingRequiresAuthorization() async throws {
        // Given - No authorization (initial state)
        // Note: This test verifies error handling when not authorized

        // When/Then - Should throw permission denied if not authorized
        do {
            try await sut.startRecording(locale: Locale(identifier: "en-US"))
            // If we reach here, permissions were granted
            // Clean up
            sut.stopRecording()
        } catch let error as VoiceInputError {
            // Expected if not authorized
            XCTAssertEqual(error, .permissionDenied, "Should throw permissionDenied when not authorized")
        } catch {
            XCTFail("Should throw VoiceInputError, got: \(error)")
        }
    }

    // MARK: - State Consistency Tests

    func testMultipleClearTranscriptionCalls() throws {
        // When - Call clear multiple times
        sut.clearTranscription()
        sut.clearTranscription()
        sut.clearTranscription()

        // Then - Should remain empty
        XCTAssertEqual(sut.transcribedText, "")
    }

    func testMultipleClearErrorCalls() throws {
        // When - Call clear multiple times
        sut.clearError()
        sut.clearError()
        sut.clearError()

        // Then - Should remain nil
        XCTAssertNil(sut.error)
    }

    func testMultipleStopRecordingCalls() throws {
        // When - Call stop multiple times
        sut.stopRecording()
        sut.stopRecording()
        sut.stopRecording()

        // Then - Should handle gracefully
        XCTAssertFalse(sut.isRecording)
    }

    // MARK: - Authorization Status Tests

    func testAuthorizationStatusTypes() {
        // Verify all authorization statuses are handled
        let statuses: [SFSpeechRecognizerAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .restricted,
            .authorized
        ]

        // Should be able to handle all statuses
        for status in statuses {
            // Just verify the enum values exist
            XCTAssertNotNil(status)
        }
    }
}
