//
//  OCRManagerProtocol.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation
import UIKit
import Combine

/// Protocol for OCR management
@MainActor
protocol OCRManagerProtocol: AnyObject, ObservableObject {
    var extractedText: String { get }
    var isProcessing: Bool { get }
    var error: OCRError? { get }
    
    var extractedTextPublisher: Published<String>.Publisher { get }
    var isProcessingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<OCRError?>.Publisher { get }
    
    func recognizeText(from image: UIImage) async throws -> String
    func recognizeTextWithLanguage(from image: UIImage) async throws -> OCRResult
    func clearError()
}

/// Extension to make OCRManager conform to the protocol
extension OCRManager: OCRManagerProtocol {
    var extractedTextPublisher: Published<String>.Publisher { $extractedText }
    var isProcessingPublisher: Published<Bool>.Publisher { $isProcessing }
    var errorPublisher: Published<OCRError?>.Publisher { $error }
}
