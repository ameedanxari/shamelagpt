# ShamelaGPT Mobile Parity Plan (Dec 2025)

## Sources
- Latest OpenAPI: `docs/api/openapi_latest.json` (fetched 2025-12-05)
- Web portal UI: `https://shamelagpt.com` (signin/signup, Tailwind-based emerald/amber gradient look)
- Current mobile code:
  - Android: `shamelagpt-android/app/src/main/java/com/shamelagpt/android/...`
  - iOS: `shamelagpt-ios/shamelagpt/...`
- Internal guides: `.claude/cross-platform-instructions.md`, `.claude/IMPLEMENTATION_GUIDE.md`

## Goals
- Achieve feature parity with web (auth, conversations, streaming chat, preferences) on both platforms.
- Preserve existing capabilities: OCR fact-check, voice input, local cache, history, error handling.
- Minimize regression risk by reusing existing MVVM architecture and test harnesses.

## New Backend Surface (from OpenAPI)
- Auth (no bearer required): `POST /api/auth/signup`, `POST /api/auth/login`
- Authenticated user: `GET|PUT|DELETE /api/auth/me`, `GET /api/auth/verify`
- Preferences: `GET|PUT /api/auth/me/preferences` (language, custom_system_prompt, response_preferences{length,style,focus})
- Protected chat: `POST /api/chat`, `POST /api/chat/stream` (SSE), `POST /api/chat/generate-title`
- Conversations (protected): list/create/delete, fetch messages
- Guest: `POST /api/guest/chat/stream` (rate limited 10 RPM/IP), `GET /api/guest/health`
- Health: `GET /api/health`
- Request model deltas: `prompt_config`, `language_preference`, `custom_system_prompt`, `enable_thinking`, `session_id` (guest)

## Current Mobile Snapshot (before changes)
- Android
  - Base URL `https://api.shamelagpt.com/` (Retrofit), endpoints: `/api/health`, `/api/chat` only.
  - Local Room conversations/messages; thread_id stored locally; no auth, no streaming, no preferences, no server conversation sync.
  - OCR + voice input wired in `ChatViewModel`; local conversation title derived from first message.
- iOS
  - Base URL `https://api.shamelagpt.com` (URLSession); endpoints: `/api/health`, `/api/chat` only.
  - Core Data conversations/messages; no auth, no streaming, no preferences, no server sync; title derived locally.
  - OCR + voice input supported; history UI relies on local store.

## Gap Analysis (web/API vs mobile)
- Auth & session: mobile lacks signup/login, token storage, /me update/delete, token verify; API now requires bearer for chat/conversations.
- Base URL: server now exposed at `shamelagpt.com`; mobile still points to `api.shamelagpt.com`.
- Chat contract: request models missing `prompt_config`, `language_preference`, `custom_system_prompt`, `enable_thinking`; no SSE support; no bearer header.
- Guest chat: not implemented; current chat path would 401 once auth enforced.
- Conversation sync: mobile uses local-only store; no calls to `/api/conversations` or `/messages`; delete-all/delete-one not mirrored to backend.
- Title generation: mobile generates locally; API offers `/chat/generate-title`.
- Preferences: mobile only stores language locally (and welcome flag); no server-backed preferences.
- Error handling: no 401/403 handling, no guest rate-limit handling (429), no refresh/reauth flow.
- UI parity: no login/signup screens; settings lack preference fields; web color system uses emerald/amber gradients while apps use older palette.

## Architecture & Implementation Plan

### 1) Networking + Config
- Update base URL to `https://shamelagpt.com/` on both platforms.
- Introduce auth-aware client:
  - Android: OkHttp interceptor injecting `Authorization: Bearer <id_token>` when session available; handle 401 → emit session invalid event.
  - iOS: URLSession configuration with request adapter (or custom APIClient) adding bearer header; surface 401 for reauth.
- Expand API interfaces to match OpenAPI:
  - Auth: signup/login, me (GET/PUT/DELETE), verify, preferences.
  - Chat: chat, chat stream (SSE), generate-title, guest chat stream, health endpoints.
  - Conversations: list/create/delete/delete-all, messages fetch.
- Streaming:
  - Android: OkHttp `EventSource`/`SSE` reader; expose flow of chunks and completion/error; cancellation on scope cancel.
  - iOS: URLSession `bytes(for:)` / `AsyncSequence` over SSE; handle `data:` chunks and end-of-stream.
- Models: align DTOs with OpenAPI fields (snake_case via serializers); include prompt_config union (string/object), enable_thinking flag defaults, response_preferences model.

### 2) Auth Flow (Firebase-backed per API description)
- Use Firebase email/password auth to obtain ID token & refresh_token; store securely (Android EncryptedSharedPreferences; iOS Keychain).
- Flows:
  - Signup/login screens → Firebase auth → call `/api/auth/signup|login` to register server-side, receive token bundle & user payload.
  - Session bootstrap on app launch: verify stored token with `/api/auth/verify`; fetch `/api/auth/me` + `/preferences`; fall back to guest if invalid.
  - Logout/delete account: clear tokens, local caches, and hit `/api/auth/me` DELETE for account removal (after client-side Firebase delete when applicable).
  - Profile update: PUT `/api/auth/me` (display_name/email) after Firebase reauth for email changes.
- State holder: SessionManager per platform exposing auth state (guest/authenticated), token provider for network layer, and user profile/preferences cache.

### 3) Chat & Conversations
- Request construction:
  - Merge user preferences: language precedence (request > conversation > user > auto), `custom_system_prompt`, `response_preferences`, `enable_thinking` default true.
  - Support guest chat via `/api/guest/chat/stream` when no session; authenticated chat via `/api/chat` or `/api/chat/stream`.
  - Fact-check OCR flow: keep existing prompt wrapping (`Please fact-check...`) but send through same chat endpoint with prompt_config if available.
- Streaming UI:
  - Pipe SSE chunks into incremental message rendering; preserve current loading/typing indicators; allow cancel.
  - Finalize message and save to local store with sources parsed as today.
- Conversation sync:
  - Authenticated: source of truth is backend. Create via `/api/conversations` (server title) and `/chat/generate-title` for first message. Sync list/messages on open; apply deletes to server + local.
  - Guest/offline: continue using local-only conversations; mark them as guest and skip server sync.
  - Thread IDs: keep storing per conversation; update from responses.
- Title generation: replace local truncation with `/api/chat/generate-title` when online; fallback to local when offline/guest.

### 4) Preferences & Settings
- Map UI settings to API:
  - Language picker ↔ `language_preference`
  - Custom system prompt text field ↔ `custom_system_prompt`
  - Response style (length/style/focus) controls ↔ `response_preferences`
- On login bootstrap, fetch preferences and hydrate local settings; save changes locally and PUT to `/api/auth/me/preferences`.
- Keep existing welcome flag untouched.

### 5) UI Parity Updates
- Add signin/signup screens with email/password + display_name fields, error states, and loading buttons.
- Auth gating:
  - If unauthenticated, allow guest chat (stream) but prompt to sign in for persistence.
  - If authenticated, show profile menu (display name/email), logout/delete actions, preferences.
- Visuals: adopt web palette (emerald/amber gradients, dark backgrounds `#0f0f0f`/`#171717`, rounded cards) without breaking current theming structure (`presentation/theme` on Android, `Theme` on iOS).
- History screen: indicate whether a conversation is synced (server) vs local guest; offer delete-all that calls server endpoint when authenticated.

### 6) Data & Storage Changes
- Android Room/Core Data:
  - Add flags for `isGuest`, optional `serverConversationId` (for mapping), and store `responsePreferences`, `customPrompt` locally for offline use.
  - Migration strategy: default existing rows to guest/local; add lightweight migration scripts.
- Session storage:
  - Android: EncryptedSharedPreferences for tokens/user/profile/preferences snapshot.
  - iOS: Keychain wrapper for token bundle; UserDefaults for lightweight flags; Core Data for cached preferences if needed for offline.

### 7) Error Handling & Resilience
- Handle 401/403: force logout to guest mode with toast + reauth prompt.
- Handle 429 for guest chat: surface rate-limit message, backoff timer.
- Network timeouts: reuse existing SafeApiCall/NetworkError mapping; ensure SSE cancellation closes connections.
- Maintain OCR/voice paths: no changes to recognition pipeline; only ensure auth state does not block fact-check flow.

### 8) Testing (high-value, no full-suite run here)
- Android (MockK/Coroutines):
  - AuthRepository/AuthApi tests: signup/login success + 401.
  - ApiService request serialization for chat with prompt_config/language_preference.
  - SSE parser emits incremental chunks → final message persisted.
  - Conversation sync: delete-all calls remote + local; create conversation stores server id & thread_id.
  - Preferences mapper: PUT payload built from UI settings; GET populates local manager.
- iOS (XCTest with protocol mocks):
  - APIClient encodes/decodes new fields; adds bearer header.
  - Chat streaming AsyncSequence parses SSE data; cancellation closes task.
  - SessionManager token bootstrap + verify; logout clears keychain.
  - Conversation sync: list/delete, message fetch mapping.
  - Preferences roundtrip mapping (language/custom prompt/response style).
- Keep existing OCR/voice tests intact; add regression checks where necessary.

## Execution Checklist
1. Wire networking/base URL + models (both platforms).
2. Add SessionManager + secure token storage; implement auth flows/UI.
3. Expand repositories for auth, chat (stream), conversations, preferences.
4. Update UI screens (chat, history, settings) to consume new data and show auth state; keep OCR/voice intact.
5. Add migrations for local stores to tag guest vs server conversations.
6. Refresh mocks/tests (targeted high-value cases listed above).
7. Manual QA (post-handoff): auth lifecycle, guest rate limits, streaming, OCR fact-check, offline fallback.

## Notes/Risks
- Firebase auth dependency must be added/configured on both platforms (appId/Google-Services/Info.plist changes not covered here).
- SSE support needs careful cancellation to avoid leaks; ensure background/foreground handling.
- Aligning server conversation IDs with local primary keys requires migration and mapping; avoid breaking existing history by preserving current IDs for guest mode.
- Web theming adoption should respect existing design tokens; avoid wholesale replacements without verification.

