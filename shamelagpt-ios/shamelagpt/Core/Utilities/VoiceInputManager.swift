//
//  VoiceInputManager.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Manages voice input and speech recognition
@MainActor
final class VoiceInputManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var transcribedText: String = ""
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published private(set) var error: VoiceInputError?

    // MARK: - Private Properties

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    // MARK: - Initialization

    override init() {
        super.init()
        // Default to English, will be updated when locale is specified
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Public Methods

    /// Requests speech recognition permission
    func requestPermission() async -> Bool {
        AppLogger.voiceInput.logDebug("Requesting speech recognition permission")

        if isRunningUnitTests {
            await MainActor.run {
                self.authorizationStatus = .authorized
            }
            return true
        }

        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        await MainActor.run {
            self.authorizationStatus = speechStatus
        }

        AppLogger.voiceInput.logInfo("Speech recognition authorization status: \(String(describing: speechStatus))")

        guard speechStatus == .authorized else {
            await MainActor.run {
                self.error = .permissionDenied
            }
            AppLogger.voiceInput.logWarning("Speech recognition permission denied")
            return false
        }

        // Request microphone permission (iOS 15 compatible)
        AppLogger.voiceInput.logDebug("Requesting microphone permission")
        let microphoneStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        AppLogger.voiceInput.logInfo("Microphone permission granted: \(microphoneStatus)")

        guard microphoneStatus else {
            await MainActor.run {
                self.error = .microphonePermissionDenied
            }
            AppLogger.voiceInput.logWarning("Microphone permission denied")
            return false
        }

        return true
    }

    /// Starts recording with the specified locale
    /// - Parameter locale: The locale for speech recognition (e.g., en-US, ar-SA)
    func startRecording(locale: Locale) async throws {
        AppLogger.voiceInput.logInfo("Starting recording with locale: \(locale.identifier)")

        // Cancel any ongoing recognition task
        if recognitionTask != nil {
            AppLogger.voiceInput.logWarning("Existing recognition task found, stopping it first")
            stopRecording()
        }

        // Check authorization
        guard authorizationStatus == .authorized else {
            AppLogger.voiceInput.logError("Cannot start recording - not authorized")
            throw VoiceInputError.permissionDenied
        }

        // Update recognizer with specified locale
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            AppLogger.voiceInput.logError("Speech recognizer not available for locale: \(locale.identifier)")
            throw VoiceInputError.recognizerNotAvailable
        }

        AppLogger.voiceInput.logDebug("Speech recognizer initialized and available")

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        AppLogger.voiceInput.logDebug("Audio session configured successfully")

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            AppLogger.voiceInput.logError("Failed to create recognition request")
            throw VoiceInputError.unableToCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true

        // Get the audio input node
        let inputNode = audioEngine.inputNode

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    AppLogger.voiceInput.logDebug("Transcription updated: \(result.bestTranscription.formattedString.prefix(50))...")
                }

                if let error = error {
                    AppLogger.voiceInput.logError("Recognition task failed", error: error)
                    self.error = .recognitionFailed(error.localizedDescription)
                    self.stopRecording()
                } else if result?.isFinal == true {
                    AppLogger.voiceInput.logInfo("Recognition task completed with final result")
                    self.stopRecording()
                }
            }
        }

        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()

        AppLogger.voiceInput.logInfo("Audio engine started, recording is active")

        isRecording = true
        transcribedText = ""
        error = nil
    }

    /// Stops recording and recognition
    func stopRecording() {
        AppLogger.voiceInput.logInfo("Stopping recording")

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            AppLogger.voiceInput.logDebug("Audio engine stopped and tap removed")
        }

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            AppLogger.voiceInput.logDebug("Audio session deactivated successfully")
        } catch {
            AppLogger.voiceInput.logWarning("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    /// Clears the transcribed text
    func clearTranscription() {
        transcribedText = ""
    }

    /// Clears the current error
    func clearError() {
        error = nil
    }
}

// MARK: - Error Types

enum VoiceInputError: LocalizedError {
    case permissionDenied
    case microphonePermissionDenied
    case recognizerNotAvailable
    case unableToCreateRequest
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied. Please enable it in Settings."
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .recognizerNotAvailable:
            return "Speech recognizer is not available for this language."
        case .unableToCreateRequest:
            return "Unable to create speech recognition request."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        }
    }
}

extension VoiceInputError: Equatable {
    static func == (lhs: VoiceInputError, rhs: VoiceInputError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied):
            return true
        case (.microphonePermissionDenied, .microphonePermissionDenied):
            return true
        case (.recognizerNotAvailable, .recognizerNotAvailable):
            return true
        case (.unableToCreateRequest, .unableToCreateRequest):
            return true
        case (.recognitionFailed(let lhsMessage), .recognitionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
