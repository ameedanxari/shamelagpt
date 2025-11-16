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
    
    var transcribedTextPublisher: Published<String>.Publisher { get }
    var isRecordingPublisher: Published<Bool>.Publisher { get }
    var authorizationStatusPublisher: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { get }
    var errorPublisher: Published<VoiceInputError?>.Publisher { get }
    
    func requestPermission() async -> Bool
    func startRecording(locale: Locale) async throws
    func stopRecording()
    func clearTranscription()
    func clearError()
}

/// Extension to make VoiceInputManager conform to the protocol
extension VoiceInputManager: VoiceInputManagerProtocol {
    var transcribedTextPublisher: Published<String>.Publisher { $transcribedText }
    var isRecordingPublisher: Published<Bool>.Publisher { $isRecording }
    var authorizationStatusPublisher: Published<SFSpeechRecognizerAuthorizationStatus>.Publisher { $authorizationStatus }
    var errorPublisher: Published<VoiceInputError?>.Publisher { $error }
}
