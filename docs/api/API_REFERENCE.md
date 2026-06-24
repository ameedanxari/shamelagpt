# ShamelaGPT API Reference

> **Source of truth:** `docs/api/openapi_latest.json`
>
> This file is a human-readable summary of the OpenAPI contract. It is **manually maintained** and will drift quickly as the backend evolves. To refresh the local spec and regenerate this document:
>
> ```bash
> # fetch latest JSON from prod docs and overwrite local copy
> ./scripts/update_openapi.sh
>
> # optionally run any generator you have for producing Markdown/clients
> ```
>
> The CI workflow and mobile contract tests already consume `docs/api/openapi_latest.json`.

This document provides a comprehensive reference for the ShamelaGPT backend API endpoints, grouped by feature area.

## Base URL
`https://shamelagpt.com`

---

## Authentication

### Signup
`POST /api/auth/signup`
- **Body**: `SignupRequest` (`email`, `password`, `displayName`)
- **Returns**: `AuthResponse` (`token`, `refreshToken`, `expiresIn`, `user`)

### Login
`POST /api/auth/login`
- **Body**: `LoginRequest` (`email`, `password`)
- **Returns**: `AuthResponse`

### Forgot Password
`POST /api/auth/forgot-password`
- **Body**: `{ "email": "string" }`
- **Returns**: `200 OK` (Empty)

### Google Sign-In
`POST /api/auth/google`
- **Body**: `{ "idToken": "string" }`
- **Returns**: `AuthResponse`

### Refresh Token
`POST /api/auth/refresh`
- **Body**: `{ "refreshToken": "string" }`
- **Returns**: `AuthResponse`

---

## User Profile & Preferences

### Get Current User
`GET /api/auth/me`
- **Returns**: `UserResponse`

### Update User
`PUT /api/auth/me`
- **Body**: `UpdateUserRequest` (`displayName`)
- **Returns**: `UserResponse`

### Delete Account
`DELETE /api/auth/me`
- **Returns**: `200 OK`

### Get Preferences
`GET /api/auth/me/preferences`
- **Returns**: `UserPreferencesRequest`

### Update Preferences
`PUT /api/auth/me/preferences`
- **Body**: `UserPreferencesRequest` (`languagePreference`, `customSystemPrompt`, `responsePreferences`)
- **Returns**: `200 OK`

### User Mode Preference
`GET /api/auth/me/mode`
- **Returns**: `{ mode_preference: 0|1|2 }` (0=auto,1=research,2=fact-check)

`PUT /api/auth/me/mode`
- **Body**: `{ "mode_preference": int }`
- **Returns**: updated user data with new mode preference

---

## Chat & AI Functions

### Send Message
`POST /api/chat` (Authenticated)
`POST /api/guest/chat` (Guest)
- **Body**: `ChatRequest` (`question`, `threadId`)
- **Returns**: `ChatResponse` (`answer`, `threadId`)

### Stream Message (SSE)
`POST /api/chat/stream`
`POST /api/guest/chat/stream`
- **Body**: `ChatRequest`
- **Returns**: Server-Sent Events stream of text chunks.

### OCR (Optical Character Recognition)
`POST /api/chat/ocr`
- **Body**: `OCRRequest` (`imageBase64`)
- **Returns**: `OCRResponse` (`extractedText`, `imageUrl`, `metadata`)

### Confirm Fact-Check (SSE)
`POST /api/chat/confirm-factcheck`
- **Body**: `ConfirmFactCheckRequest` (`imageBase64`, `question`, `threadId`)
- **Returns**: Server-Sent Events stream.

### Generate Conversation Title
`POST /api/chat/generate-title`
- **Body**: `{ "threadId": "string" }`
- **Returns**: `{ "title": "string" }`

---

## Conversation Management

### List Conversations
`GET /api/conversations`
- **Returns**: `[ConversationResponse]`

### Create Conversation
`POST /api/conversations`
- **Body**: `ConversationRequest` (`title`)
- **Returns**: `ConversationResponse`

### Delete All Conversations
`DELETE /api/conversations`
- **Returns**: `200 OK`

### Delete Single Conversation
`DELETE /api/conversations/{id}`
- **Returns**: `200 OK`

### Get Messages for Conversation
`GET /api/conversations/{id}/messages`
- **Query parameters**:
  - `auto_presign` (bool, default `true`) – automatically expand S3 image URLs
  - `expiration` (int seconds, default `3600`) – presigned URL lifetime
- **Returns**: `ConversationMessagesResponse` (`messages`)

### Conversation Share Status
`GET /api/conversations/{id}/share`
- **Returns**: share metadata (public URL, is_shared flag)

`PUT /api/conversations/{id}/share`
- **Body**: `{ "is_shared": bool }`
- **Returns**: updated share metadata

### Presigned URL for Images
`GET /api/conversations/images/presigned-url` (query)
`POST /api/conversations/images/presigned-url` (body)
- **Purpose**: generate a temporary S3 url for a private image.
- **Parameters**: `s3_url` (key or full url), optional `expiration`.
- **Returns**: `{ presigned_url, expires_in }`

### Public Shared Conversation
`GET /api/shared/{conversation_id}`
- **Public endpoint** – no authentication required.
- Only succeeds if the conversation has been shared.
- **Returns**: conversation title and messages.

---

## System

### Health Check
`GET /api/health`
- **Returns**: `{ "status": "ok", "service": "shamelagpt-api" }`
