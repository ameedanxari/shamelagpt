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



## AI Prompt Library Steering (Auto-Managed — do not edit)

Load these files (in order) before handling any non-trivial request:
1. `.ai-prompts/prompts/AGENTS.md` — authoritative instructions.
2. `.ai-prompts/prompts/orchestrators/ai-agent-entry-point.md` — entry point.
3. `.ai-prompts/prompts/orchestrators/drill-down-engine.md` — the 3-step engine.

If `MY_PROJECT.md` lists external material or the project already has
source code, also load:
4. `.ai-prompts/prompts/orchestrators/external-input-handler.md`

Do NOT auto-load anything else under `.ai-prompts/prompts/orchestrators/`
without following the entry-point routing.

Follow the entry point's checkpoint protocol exactly. At every engine
checkpoint, stop, summarize progress, and wait for the user to say
`Continue` before moving to the next step. Do not auto-advance across
planning checkpoints.
<!-- /AI Prompt Library Steering (Auto-Managed) -->
