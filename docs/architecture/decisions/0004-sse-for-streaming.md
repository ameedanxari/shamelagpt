# ADR-004: Server-Sent Events (SSE) for Streaming

**Status**: Accepted
**Date**: 2025-11-02

## Context
AI chat responses are generated incrementally. Need to display text as it's generated for better UX.

## Decision
Use **Server-Sent Events (SSE)** for real-time streaming:
- iOS: Custom URLSession-based SSE parser
- Android: OkHttp-based SSE handling

## Consequences
**Positive:**
- Real-time streaming improves perceived performance
- Simple HTTP-based protocol
- Works with existing API infrastructure
- Supports guest and authenticated flows

**Negative:**
- Custom parsing logic required
- More complex error handling than request/response
- Buffering and chunking edge cases