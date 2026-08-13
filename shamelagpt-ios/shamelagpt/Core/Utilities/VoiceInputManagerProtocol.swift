//
//  VoiceInputManagerProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import Speech
import Combine

/// Protocol for voice input management
@MainActor
protocol VoiceInputManagerProtocol: AnyObject, ObservableObject {
    var transcribedText: String { get }
    var isRecording: Bool { get }
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus { get }
    var error: VoiceInputError? { get }

    /// Audio captured during the last recording, ready to upload. `nil` when nothing
    /// usable was captured — callers must treat that as "no upload", not as a failure.
    /// The caller owns the file and must call `discardRecording()` when finished with it.
    var recordedFileURL: URL? { get }

    var transcribedTextPublisher: Published<String>.Publisher { get }
    var isRecordingPublisher: Published<Bool>.Publisher { get }
    var authorizationStatusPublisher: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { get }
    var errorPublisher: Published<VoiceInputError?>.Publisher { get }
    
    func requestPermission() async -> Bool
    func startRecording(locale: Locale) async throws
    func stopRecording()
    func clearTranscription()
    func clearError()
    /// Deletes the recorded temp file and clears `recordedFileURL`. Safe to call repeatedly.
    func discardRecording()
}

/// Extension to make VoiceInputManager conform to the protocol
extension VoiceInputManager: VoiceInputManagerProtocol {
    var transcribedTextPublisher: Published<String>.Publisher { $transcribedText }
    var isRecordingPublisher: Published<Bool>.Publisher { $isRecording }
    var authorizationStatusPublisher: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { $authorizationStatus }
    var errorPublisher: Published<VoiceInputError?>.Publisher { $error }
}
