# Localization Guide

ShamelaGPT currently supports **English** and **Arabic**. This guide explains how to add new strings and maintain RTL (Right-to-Left) compatibility.

## 1. Adding New Strings

### iOS
1. Open `Localizable.strings` (or `Localizable.xcstrings`).
2. Add the key and translation for both English and Arabic.
3. Use the `LocalizationKeys` enum or `String.localized` extension.
   ```swift
   Text(LocalizationKeys.chatTitle.localized)
   ```

### Android
1. Add the string to `shamelagpt-android/app/src/main/resources/values/strings.xml`.
2. Add the translation to `shamelagpt-android/app/src/main/resources/values-ar/strings.xml`.
3. Reference in Compose:
   ```kotlin
   stringResource(R.string.chat_title)
   ```

## 2. RTL Considerations
Since Arabic is a Right-to-Left language, layouts must mirror correctly.

### Best Practices
- Use **Leading/Trailing** instead of Left/Right.
- Ensure icons that have a "direction" (like arrows) are mirrored.
- Text alignment should usually be `natural` (Top-Left for EN, Top-Right for AR).

### Platform Specifics
- **iOS**: SwiftUI handles RTL mirroring automatically for most components if using `padding(.leading)` etc.
- **Android**: Jetpack Compose handles RTL if `Modifier.padding(start = ...)` is used instead of `absoluteLeft`.

## 3. Language Switching
Users can change the app language independently of the system language in **Settings**.
- Selected language is persisted in `UserDefaults` (iOS) or `DataStore` (Android).
- The app should restart or update the root view immediately upon language change.

## 4. Arabic Content Guidelines
When translating:
- Use **Modern Standard Arabic** (Fusha).
- Ensure religious terminology is accurate and respectful.
- Use Eastern Arabic numerals (١، ٢، ٣) where appropriate for the locale.
