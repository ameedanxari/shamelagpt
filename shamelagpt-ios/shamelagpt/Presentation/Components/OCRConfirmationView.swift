//
//  OCRConfirmationView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// View for confirming OCR-extracted text before submitting for fact-checking
struct OCRConfirmationView: View {

    // MARK: - Properties

    let imageData: Data
    let extractedText: String
    let detectedLanguage: String?
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    @State private var editedText: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(
        imageData: Data,
        extractedText: String,
        detectedLanguage: String?,
        onConfirm: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.imageData = imageData
        self.extractedText = extractedText
        self.detectedLanguage = detectedLanguage
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        self._editedText = State(initialValue: extractedText)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Language detection info
                    if let language = detectedLanguage {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundColor(.secondary)
                            Text("Detected language: \(languageDisplayName(for: language))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Image preview
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                    }

                    // Editable text field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted text (editable):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)

                        TextEditor(text: $editedText)
                            .frame(minHeight: 150)
                            .padding(8)
                            // Remove the light gray background so the screen background spans end-to-end
                            .background(Color.clear)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Confirm Fact-Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fact-Check") {
                        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedText.isEmpty {
                            onConfirm(trimmedText)
                        }
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns a display name for the language code
    /// - Parameter code: ISO language code (e.g., "en", "ar")
    /// - Returns: Display name (e.g., "English", "Arabic")
    private func languageDisplayName(for code: String) -> String {
        switch code {
        case "ar":
            return "Arabic"
        case "en":
            return "English"
        default:
            return code.uppercased()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OCRConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        OCRConfirmationView(
            imageData: Data(),
            extractedText: "This is sample extracted text from an image.\nIt can span multiple lines.",
            detectedLanguage: "en",
            onConfirm: { text in
                print("Confirmed: \(text)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}
#endif
