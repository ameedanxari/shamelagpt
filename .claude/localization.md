/* localization.md — localization rules for agents (compact) */

Principal rules:
- Store canonical server values in English/ASCII (e.g., `short`,`medium`,`detailed`) and map to localized display strings in UI.
- Localize only display strings; never change server payload values.
- Provide `Localizable.strings` (iOS) and `strings.xml` / resource maps (Android) for each supported locale.

RTL handling:
- Use system locale to set layout direction; ensure tab ordering and default selections use logical ordering, not visual index.
- Test with Arabic/Urdu locales and verify first-tab logic, text alignment, and font selection.

Font & script mapping:
- Map language codes (`ar`, `ur`) to preferred fonts; keep fallback chain.

Localization workflow for agents:
1. Add keys to `LocalizationKeys.swift` and add entries to `Localizable.strings` (en + target locales).
2. On Android, add resource strings and ensure `Context.getString(key)` mappings are used.
3. Preserve server values in models; only UI uses localized labels.
