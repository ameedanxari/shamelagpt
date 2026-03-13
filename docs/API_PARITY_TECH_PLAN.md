lo# ShamelaGPT Mobile Parity Plan (March 2026)

## Sources
- OpenAPI contract: `docs/api/openapi_latest.json` (updated 2026‑03‑09)
- Web portal: https://shamelagpt.com (Tailwind emerald/amber theme)
- Mobile code:
  - Android: `shamelagpt-android/app/src/main/java/com/shamelagpt/android/...` (see `ApiService` for implemented endpoints)
  - iOS: `shamelagpt-ios/shamelagpt/...` (client interfaces mirror Android)
- Derived docs: `docs/api/API_REFERENCE.md`, internal `.claude` guides.

## Goals
1. Match the web backend’s functionality on Android and iOS.
2. Keep existing offline/guest, OCR and voice features intact.
3. Use the current MVVM/test architecture to minimise regressions.

## Backend surface (significant endpoints)

Below is the canonical API surface.  **bold** items are already exercised by the mobile clients (see `ApiService` on Android and equivalent iOS clients); the rest are present in the OpenAPI spec but not yet consumed.

### Authentication & session
- **`POST /api/auth/signup`** – new account via Firebase
- **`POST /api/auth/login`**
- **`POST /api/auth/forgot-password`** (email reset)
- **`POST /api/auth/google`** (Google‑signin flow)
- **`POST /api/auth/refresh`** (refresh token)
- **`GET /api/auth/verify`** (token validity)
- **`GET/PUT/DELETE /api/auth/me`** (profile)
- **`GET/PUT /api/auth/me/preferences`** (language, prompt, style)
- `GET/PUT /api/auth/me/mode` (0=auto,1=research,2=fact_check) — not yet used by mobile

### Chat & AI
- **`POST /api/chat`** (auth) / **`POST /api/guest/chat`** (guest)
- **`POST /api/chat/stream`** (SSE) / **`POST /api/guest/chat/stream`**
- **`POST /api/chat/generate-title`**
- **`POST /api/chat/ocr`** – server‑side OCR
- `POST /api/guest/chat/ocr` – guest OCR (unused)
- **`POST /api/chat/confirm-factcheck`** (SSE)
- Extra request fields: `prompt_config`, `language_preference`, `custom_system_prompt`, `enable_thinking`, `image_base64`, `image_url`, `url`, `input_type`, `session_id` (guest)

### Conversations
- **`GET/POST/DELETE /api/conversations`**
- **`GET /api/conversations/{conversation_id}/messages`** (with `auto_presign` & `expiration` query params)
- `GET/PUT /api/conversations/{conversation_id}/share` — planned
- `GET/POST /api/conversations/images/presigned-url` — planned
- `GET /api/shared/{conversation_id}` (public view) — planned

### Guest & system
- `GET /api/guest/health` — planned (not yet invoked)
- **`GET /api/health`**

## Current mobile snapshot (pre‑work)

**Android**
- Base URL still `https://api.shamelagpt.com/`.
- Retrofit client only knows `/api/health` and `/api/chat`.
- Conversations/messages stored locally (Room); no auth, no streaming.
- OCR & voice integrated; titles local.

**iOS**
- Base URL `https://api.shamelagpt.com`.
- URLSession client with health/chat only.
- Core Data local storage; same limitations as Android.
- OCR/voice present; history local.

## Gap analysis

| Area | Web/API | Mobile | Gap |
|------|--------|--------|-----|
| Base URL | `shamelagpt.com` | `api.shamelagpt.com` | ✔️
| Auth | full (signup/login/refresh/verify/profile) | none | ✔️
| Chat fields | rich (prefs, prompt, SSE) | minimal | ✔️
| Guest chat | streaming, rate‑limit | none | ✔️
| OCR & factcheck | multi‑step endpoints | local hack | ✔️
| Conversations | CRUD, messages, sharing | local only | ✔️
| Preferences | server‑backed | local language only | ✔️
| Mode preference | server flag | none | ✔️
| Error handling | 401/429/refresh | naive | ✔️
| UI | login/signup, settings fields, new theme | missing | ✔️

## Architecture & implementation plan

### Networking
- Use `https://shamelagpt.com/` as base.
- Auth interceptor/adapter adds Bearer token; on 401 emit session invalid.
- Update all service interfaces per OpenAPI (auto‑generate where possible).
- SSE helpers: OkHttp `EventSource` → Kotlin Flow; URLSession `AsyncSequence`.
- DTOs match snake_case, include all new properties and default values.

### Session & auth
- Firebase email/pass + Google sign‑in to obtain ID token + refresh.
- Persist token bundle + user info securely (EncryptedSP / Keychain).
- On launch: call `/auth/verify`; fetch `/me` & prefs; if failure, drop to guest.
- Logout: clear storage, optionally call `/auth/me` DELETE (after Firebase remove).
- Profile updates mirror Firebase-side changes.
- Singleton `SessionManager` provides token, user, prefs, mode.

### Chat & conversation workflows
- Build request merging local prefs/conversation metadata.
- Route to guest endpoints when unauthenticated.
- Streaming UI renders SSE chunks, supports cancel.
- After message completes, persist to local store (respect server IDs).
- Conversation sync: create/list/delete on backend; store server IDs locally.
- Generate title via API when online.

### Preferences & modes
- Bind settings UI to server-backed model.
- Fetch on login, PUT on change.
- Mode preference toggles research/fact-check behavior.

### UI
- Add login/signup/forgot-password/Google screens.
- Display auth state in header/menu; show profile/ logout/ delete.
- Settings page: language, custom prompt, response style, mode.
- History: tag server vs guest chats; buttons call appropriate endpoints.
- Adopt web colour palette via theme adjustments.

### Storage changes
- Add fields: `isGuest`, `serverConversationId`, `responsePreferences`, `customPrompt` to RDC/Room.
- Migrate existing data marking as guest.
- Store session snapshot securely; lightweight prefs in UserDefaults.

### Error handling
- On 401/403: show toast, switch to guest, force reauth.
- Handle 429 for guest chat with user-friendly message & cooldown.
- Preserve existing network error mapping; ensure SSE closes on cancel.

### Testing (high‑leverage cases)
- **Android**: Auth flows, serializer tests, SSE parsing, conversation sync, prefs mapper.
- **iOS**: APIClient encoding/decoding, SSE sequence, SessionManager bootstraps, sync logic.
- Keep existing OCR/voice tests and add regressions.

## Execution checklist
1. Update base URL & retrofit/URLSession clients.
2. Implement SessionManager + secure storage + auth screens.
3. Expand repositories/services for new endpoints.
4. Wire chat stream and conversation sync logic.
5. Update settings/history UI and theme tokens.
6. Add local store migrations.
7. Refresh and extend unit tests as noted.
8. Run manual QA: full auth lifecycle, guest rate limits, streaming, OCR fact‑check, offline behavior.

## Notes & risks
- Firebase configuration required on both platforms (Google‑Services, Info.plist).
- SSE cancellation must survive background/foreground transitions.
- Mapping server IDs into existing DB must avoid corrupting guest history.
- Theme changes should reuse current design tokens to avoid cascade refactor.

