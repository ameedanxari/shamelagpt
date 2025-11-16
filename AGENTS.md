# AGENTS PLAYBOOK (ShamelaGPT) — Agent-optimized

Purpose: concise, machine-readable instructions and links for agent work. This file is sent with prompts; keep it minimal and reference atomic files under `.claude/`.

Quick rules (1–3 lines each):
- **Parity:** Unless flagged, implement on BOTH platforms (Android/iOS).
- **Search First:** Always grep for existing ViewModel/Service/UI before creating files.
- **MVVM:** UI ↔ ViewModel ↔ Service/Repository separation mandatory.
 
 Required atomics (read before coding):
 - `.claude/parity.md` — platform mappings & parity rules
 - `.claude/implementation.md` — where to place code, reuse decision tree
 - `.claude/testing.md` — test patterns, mocking, CI commands
 - `.claude/localization.md` — localization keys, formats, RTL notes
 - **Translation requirement:** When adding new localization keys, include translations for all supported locales (at minimum `en` and `ar`) and add the key into `LocalizationKeys.swift`. Ensure `Localizable.strings` files are updated for each locale and verify in a clean build.
- `.claude/quick_rules.md` — short grep patterns & commands

Environment pointers (fast):
- OpenAPI: `docs/api/openapi_latest.json`
- Android entry points: `shamelagpt-android/app/src/main/java/.../presentation/chat/ChatViewModel.kt`
- iOS entry points: `shamelagpt-ios/shamelagpt/Presentation/Scenes/Chat/ChatViewModel.swift`

When to ask: if a change touches platform-native storage, network schema, or localization, request a design confirmation.

Cache & API minimization (compact): prefer server single source-of-truth + local cached JSON for instant reads; background refresh; debounce writes; persist canonical server values; test for failure/backoff.

References: see `.claude/*` atomic files.


