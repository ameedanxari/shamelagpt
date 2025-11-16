# ShamelaGPT API Reference

This document provides a comprehensive reference for the ShamelaGPT backend API endpoints.

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
- **Returns**: `ConversationMessagesResponse` (`messages`)

---

## System

### Health Check
`GET /api/health`
- **Returns**: `{ "status": "ok", "service": "shamelagpt-api" }`
