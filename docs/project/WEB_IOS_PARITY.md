# Web ↔ iOS parity: what the web app has that iOS doesn't

Snapshot: **2026-08-11**. Derived by reading `shamela-frontend`, `shamela-qa-rag`
and `shamelagpt-ios` directly, not from the roadmap. Re-verify before trusting; the
web app moves faster than this file.

Companion: `docs/getting-started/IOS_SIMULATOR_RUNBOOK.md` for how to build/run/verify.

---

## 1. Status

| Feature | Web | iOS | Notes |
|---|---|---|---|
| Email / password auth | ✅ | ✅ | |
| Guest mode | ✅ | ✅ | |
| **Google sign-in** | ✅ | ✅ *(PR)* | Web uses Google Identity Services; iOS uses `ASWebAuthenticationSession` + PKCE |
| **Apple sign-in** | ✅ | ✅ *(PR)* | Web uses Firebase `signInWithPopup`; iOS uses `ASAuthorizationAppleIDProvider` |
| **Conversation modes** | ✅ | ✅ *(PR)* | UI/preference layer only — mode is endpoint-driven server-side, see §2 |
| **Mode onboarding gate** | ✅ | ✅ *(PR)* | Fires when `mode_preference == 0` |
| Response language | ✅ | ✅ | |
| Response style (length/style/focus) | ✅ | ✅ | |
| **Madhhab preference** | ✅ | ❌ **missing** | `all \| hanafi \| maliki \| shafii \| hanbali` |
| Deep-thinking toggle | ✅ | ⚠️ partial | iOS hardcodes `enableThinking: true` |
| In-composer mode chip | ✅ | ❌ | iOS changes mode via Settings only |
| Conversation sharing | ✅ | ✅ | |
| Kids mode | 🚧 "coming soon" | ❌ | Not implemented anywhere |

---

## 2. Things that are easy to get wrong

### Conversation mode is **endpoint-driven**, not preference-driven

The single most important detail, and the easiest thing to get wrong — an earlier
version of this document had it wrong, which is why it is spelled out here.

`users.mode_preference` **does not decide how the backend answers.** Backend PR #91
made mode a property of the *endpoint*:

| Endpoint | conversation_mode |
|---|---|
| `POST /api/chat/stream` | **always `research`** (hardcoded, `routes/chat.py`) |
| `POST /api/chat/confirm-factcheck` | **always `fact_check`** |
| `POST /api/guest/chat/stream` | always research |

The rationale is in the source (`routes/chat.py`):

> Mode is endpoint-driven: /chat/stream always runs in research mode. Fact-check runs
> only via /chat/confirm-factcheck. The global users.mode_preference toggle is
> intentionally NOT used for routing (#4 / backend #74) — a web-set fact-check toggle
> must not hijack a new app chat, nor turn a bare "ok" follow-up into a fact-check turn.

`_is_fact_check_origin` likewise decides from conversation *history* (image input or
fact-check metadata), never from the toggle.

**Consequences for any client:**

- Setting `mode_preference = 2` and then typing a question gets you a **research**
  answer. Copy that promises otherwise is a lie to the user.
- The only route into fact-check is the **capture flow**: image/screenshot → OCR →
  review → `POST /api/chat/confirm-factcheck`.
- `mode_preference` is still real and worth storing — it drives **client UI** (which
  affordances to foreground, the onboarding gate) and is shared across web and mobile.
  It just is not an answering-engine switch.

Also note the web sends `mode_preference` in the chat request body
(`useAuthenticatedMessaging.ts`). `ChatRequest` has no such field and Pydantic drops it.
**That field does nothing.** Don't copy it.

Mapping: `0` unset · `1` research · `2` fact check. New accounts start at `0`, which is
the onboarding trigger. `PUT /api/auth/me/mode` rejects anything outside 0–2 with **400**.

### What actually differs between the two backend modes

Once `conversation_mode` is set by the endpoint:

1. **System prompt** — `FACT_CHECK_PROMPT` (structured VERDICT / CONFIDENCE / CLAIMS)
   vs `RAG_PROMPT_OPTIMIZED` (scholarly markdown with citations)
2. **Retrieval depth** — fact check forces `num_results = 25`; research uses the
   classifier's dynamic *k*
3. **Extra SSE event** — fact check emits `fact_check_result`
4. **Not** the model — that depends only on `enable_thinking`

### Social sign-in needs no Firebase SDK on the client

The backend does the IdP exchange (`accounts:signInWithIdp`) and returns the same
`AuthResponse` as email login. The client only has to obtain a provider token:

- Google → `ASWebAuthenticationSession` + PKCE → `id_token` → `POST /api/auth/google`
- Apple → `ASAuthorizationAppleIDCredential.identityToken` → `POST /api/auth/apple`

Apple returns `fullName`/`email` **only on the first authorization ever** for that
Apple ID + app pair. Never rely on them.

### `expires_in` is a **string**

Firebase returns `"3600"`, and the backend passes it through unchanged. Parse
defensively — see the landmine in §3.

### SSE heartbeats are comment lines

The backend emits `: heartbeat\n\n` every 15s specifically to defeat iOS's idle
timeout. Any SSE parser must skip lines that aren't `data: ` rather than erroring.

---

## 3. Known defects and landmines

Track these; several are not yet fixed.

| Issue | Where | Status |
|---|---|---|
| Long answers truncated at 60s (`timeoutIntervalForResource`) | `APIClient` | fixed in PR |
| `URLError` unmapped on SSE → generic `E-APP-000` | `APIClient.streamRequest` | fixed in PR |
| Expired token → header omitted → 403 → user bounced to login | `SessionManager` / `APIClient` | fixed in PR |
| Keychain failures silently discarded | `KeychainHelper` | fixed in PR |
| **`{"type":"error"}` SSE events swallowed** | `StreamingMessageHandler.yieldEvent` has no `"error"` case, hits `default: break` — backend errors render as an empty bubble | ❌ **open** |
| **`Double(expiresIn) ?? 0`** | `AuthRepositoryImpl.persistSession` — a non-numeric `expires_in` yields expiry = *now*, i.e. instantly expired, so every request goes out unauthenticated | ❌ **open** |
| **Madhhab preference absent** | no `GET/PUT /api/auth/me/madhab` on iOS at all | ❌ **open** |
| **Deep-thinking hardcoded** | `ChatViewModel` sends `enableThinking: true` always | ❌ **open** |
| Backend returns **403 for missing credentials** | FastAPI `HTTPBearer(auto_error=True)`; 401 would be correct and would let clients distinguish "refresh and retry" from "give up" | ❌ **open** (backend) |

### The 403-vs-401 trap

FastAPI's `HTTPBearer(auto_error=True)` answers a **missing** `Authorization` header
with **403 "Not authenticated"**, not 401. Any client-side "refresh and retry on 401"
logic therefore misses the most common real case. Retry on **401 *and* 403**.

Corollary for triage: a 403 on a conversation ID that doesn't exist in the database
proves the request died at the auth layer — the route returns 404 for a missing
conversation and 403 only for one owned by someone else.

---

## 4. Attribution when reading production logs

Getting this wrong wastes real time — it already did once.

- **Uppercase UUIDs** (`FA2A16BC-…`) are Swift's `UUID().uuidString`. Lowercase is
  Java/Kotlin's `UUID.randomUUID().toString()`. Useful for telling iOS from Android.
- **Always check every branch, not just `main`**, before claiming a client cannot call
  an endpoint. `/api/auth/me/mode` is absent from `main` but present on
  `chore/sync-release-v1.1-with-main`, so shipped 1.1 builds *do* call it.
- Build numbers are bumped by hand at archive time (no release automation in
  `.github/workflows/`), so `CURRENT_PROJECT_VERSION = 1` in the pbxproj tells you
  nothing about what shipped.

---

## 5. Backend endpoints iOS should know about

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/auth/me/mode` | `{mode_preference, mode_name}` |
| `PUT` | `/api/auth/me/mode` | `{mode_preference: 0\|1\|2}` |
| `GET` / `PUT` | `/api/auth/me/madhab` | `all\|hanafi\|maliki\|shafii\|hanbali` — **unused by iOS** |
| `GET` / `PUT` | `/api/auth/me/preferences` | language, custom prompt, length/style/focus |
| `POST` | `/api/auth/google` | `{id_token}` — Google ID token |
| `POST` | `/api/auth/apple` | `{id_token}` — Apple identity token |
| `POST` | `/api/auth/refresh` | `{refresh_token}` |
| `POST` | `/api/chat/stream` | SSE, authenticated; applies mode + madhhab |
| `POST` | `/api/guest/chat/stream` | SSE, no auth; always research |
