//
//  ShareViewController.swift
//  FactCheckShareExtension
//
//  Created by Ameed Khalid on 22/01/2026.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

private struct FactCheckTransferPayload: Codable {
    let text: String
    let detectedLanguage: String?
    let imageDataBase64: String?
}

final class ShareViewController: UIViewController {

    private let pasteboardType = "com.shamelagpt.factcheck"
    private let targetURL = URL(string: "shamelagpt://factcheck")!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await handleInputAndOpenApp() }
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func handleInputAndOpenApp() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            finish(); return
        }

        // Keep parity with Android share flow: prioritize images for OCR/fact-check.
        if let imagePayload = await extractImagePayload(from: items) {
            await transferAndLaunchApp(payload: imagePayload)
            return
        }

        // Fallback to explicit text, then URLs
        if let text = await extractText(from: items) {
            await transferAndLaunchApp(payload: FactCheckTransferPayload(text: text, detectedLanguage: nil, imageDataBase64: nil))
            return
        }

        if let url = await extractURL(from: items) {
            await transferAndLaunchApp(payload: FactCheckTransferPayload(text: url, detectedLanguage: nil, imageDataBase64: nil))
            return
        }

        finish()
    }

    private func extractText(from items: [NSExtensionItem]) async -> String? {
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    do {
                        let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) as? String
                        if let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
                            return trimmed
                        }
                    } catch { continue }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    do {
                        let data = try await provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil)
                        if let text = data as? String {
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty { return trimmed }
                        }
                    } catch { continue }
                }
            }
        }
        return nil
    }

    private func extractURL(from items: [NSExtensionItem]) async -> String? {
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    do {
                        let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) as? URL
                        return url?.absoluteString
                    } catch { continue }
                }
            }
        }
        return nil
    }

    private func extractImagePayload(from items: [NSExtensionItem]) async -> FactCheckTransferPayload? {
        for item in items {
            for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                do {
                    let object = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil)
                    let image: UIImage?
                    if let url = object as? URL {
                        image = UIImage(contentsOfFile: url.path)
                    } else if let data = object as? Data {
                        image = UIImage(data: data)
                    } else if let img = object as? UIImage {
                        image = img
                    } else {
                        continue
                    }

                    guard let uiImage = image,
                          let compressed = compressImage(uiImage, maxKB: 200),
                          let encoded = compressed.base64EncodedString().nilIfEmpty else { continue }

                    return FactCheckTransferPayload(
                        text: " ", // OCR will be performed in the main app
                        detectedLanguage: nil,
                        imageDataBase64: encoded
                    )
                } catch {
                    continue
                }
            }
        }
        return nil
    }

    private func transferAndLaunchApp(payload: FactCheckTransferPayload) async {
        do {
            let data = try JSONEncoder().encode(payload)
            UIPasteboard.general.setData(data, forPasteboardType: pasteboardType)
        } catch {
            finish()
            return
        }

        extensionContext?.open(targetURL) { _ in
            self.finish()
        }
    }
}

// MARK: - Helpers

private extension ShareViewController {
    func compressImage(_ image: UIImage, maxKB: Int) -> Data? {
        let maxBytes = maxKB * 1024
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        while let data = imageData, data.count > maxBytes, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        return imageData
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
