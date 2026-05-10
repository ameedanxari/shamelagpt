//
//  Logger.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import os.log

/// Centralized logging system for the app
enum AppLogger {

    // MARK: - Log Categories

    /// Logger for networking operations
    static let network = Logger(subsystem: subsystem, category: "Network")

    /// Logger for UI events
    static let ui = Logger(subsystem: subsystem, category: "UI")

    /// Logger for voice input operations
    static let voiceInput = Logger(subsystem: subsystem, category: "VoiceInput")

    /// Logger for OCR operations
    static let ocr = Logger(subsystem: subsystem, category: "OCR")

    /// Logger for database operations
    static let database = Logger(subsystem: subsystem, category: "Database")

    /// Logger for chat operations
    static let chat = Logger(subsystem: subsystem, category: "Chat")

    /// Logger for general app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "App")

    /// Logger for authentication operations
    static let auth = Logger(subsystem: subsystem, category: "Auth")

    /// Logger for Sign in with Apple diagnostics
    static let appleAuth = Logger(subsystem: subsystem, category: LogPrefix.appleAuth)

    /// Logger for Apple donation subscription diagnostics
    static let appleDonation = Logger(subsystem: subsystem, category: LogPrefix.appleDonation)

    /// Logger for persisted session/token lifecycle
    static let session = Logger(subsystem: subsystem, category: "Session")

    /// Logger for font / typography selection and registry
    static let font = Logger(subsystem: subsystem, category: "Font")

    // MARK: - Private Properties

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.shamelagpt"

    enum LogPrefix {
        static let apple = "SGPApple"
        static let appleAuth = "SGPApple.Auth"
        static let appleDonation = "SGPApple.Donation"
        static let authState = "SGPAuth.State"
    }

    static func redactedEmail(_ email: String?) -> String {
        guard let email, !email.isEmpty, let atIndex = email.firstIndex(of: "@"), atIndex > email.startIndex else {
            return "null"
        }
        return "\(email[email.startIndex])***\(email[atIndex...])"
    }

    static func redactedId(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "null" }
        guard value.count > 4 else { return "***" }
        return "***\(value.suffix(4))"
    }

    static func redactedUserPayloadId(_ user: [String: AnyCodable]) -> String {
        redactedId(stringValue(from: user, keys: ["id", "uid", "userId", "firebaseUid"]))
    }

    static func redactedUserPayloadEmail(_ user: [String: AnyCodable]) -> String {
        redactedEmail(stringValue(from: user, keys: ["email"]))
    }

    private static func stringValue(from payload: [String: AnyCodable], keys: [String]) -> String? {
        for key in keys {
            if let string = payload[key]?.value as? String, !string.isEmpty {
                return string
            }
        }
        return nil
    }
}

// MARK: - Logger Extension for Convenience

extension Logger {

    /// Logs a debug message with file/function context
    func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.debug("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs an info message with file/function context
    func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.info("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs an error message with file/function context
    func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            self.error("[\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            self.error("[\(fileName):\(line)] \(function) - \(message)")
        }
    }

    /// Logs a warning message with file/function context
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.warning("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs a fault (critical error) with file/function context
    func logFault(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            self.fault("[\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            self.fault("[\(fileName):\(line)] \(function) - \(message)")
        }
    }

    /// Logs a debug message that begins with a stable prefix for console filtering.
    func logDebug(prefix: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.debug("\(prefix) [\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs an info message that begins with a stable prefix for console filtering.
    func logInfo(prefix: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.info("\(prefix) [\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs a warning message that begins with a stable prefix for console filtering.
    func logWarning(prefix: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.warning("\(prefix) [\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs an error message that begins with a stable prefix for console filtering.
    func logError(prefix: String, _ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            self.error("\(prefix) [\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            self.error("\(prefix) [\(fileName):\(line)] \(function) - \(message)")
        }
    }
}
