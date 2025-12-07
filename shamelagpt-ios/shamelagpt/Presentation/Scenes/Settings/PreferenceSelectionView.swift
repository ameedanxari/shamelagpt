import SwiftUI

/// Reusable selection list for a preference (e.g., Length, Style, Focus)
struct PreferenceSelectionView: View {
    enum PrefKey {
        case length, style, focus
    }

    let title: String
    let key: PrefKey
    let options: [(display: String, value: String)]
    @Binding var selectedValue: String
    let preferencesRepository: PreferencesRepository?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(0..<options.count, id: \ .self) { idx in
                let opt = options[idx]
                Button(action: {
                    Task {
                        await select(option: opt)
                    }
                }) {
                    HStack {
                        Text(LocalizedStringKey(opt.display))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)
                        Spacer()
                        if selectedValue == opt.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(AppTheme.Typography.body)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            // If the current selected value is not one of the provided options, show it as custom
            if !selectedValue.isEmpty && !options.contains(where: { $0.value == selectedValue }) {
                Section(header: Text(LocalizationKeys.prefCurrent.localizedKey)) {
                    HStack {
                        Text(selectedValue)
                            .font(AppTheme.Typography.body)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(LocalizedStringKey(title))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(option: (display: String, value: String)) async {
        // Update server-side prefs by fetching current, updating, and saving.
        guard let repo = preferencesRepository else {
            DispatchQueue.main.async {
                selectedValue = option.value
                dismiss()
            }
            return
        }

        do {
            var current = try await repo.fetchPreferences()
            let currentResp = current.responsePreferences
            // Build updated response preferences by replacing the selected key
            let newLength = (key == .length) ? option.value : currentResp?.length
            let newStyle = (key == .style) ? option.value : currentResp?.style
            let newFocus = (key == .focus) ? option.value : currentResp?.focus

            let updatedResp = ResponsePreferencesRequest(
                length: newLength,
                style: newStyle,
                focus: newFocus
            )

            let newModel = UserPreferencesModel(
                languagePreference: current.languagePreference,
                customSystemPrompt: current.customSystemPrompt,
                responsePreferences: updatedResp
            )

            try await repo.updatePreferences(newModel)

            DispatchQueue.main.async {
                selectedValue = option.value
                dismiss()
            }
        } catch {
            AppLogger.ui.logError("Failed to update preference selection: \(error.localizedDescription)")
            DispatchQueue.main.async {
                selectedValue = option.value
                dismiss()
            }
        }
    }
}

struct PreferenceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PreferenceSelectionView(
                title: "Length",
                key: .length,
                options: [("Short","short"),("Medium","medium"),("Detailed","detailed")],
                selectedValue: .constant("short"),
                preferencesRepository: nil
            )
        }
    }
}
