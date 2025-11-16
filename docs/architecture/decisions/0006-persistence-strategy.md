# ADR-006: Core Data (iOS) and Room (Android) for Persistence

**Status**: Accepted
**Date**: 2025-11-02

## Context
Need local persistence for conversations, messages, and offline support.

## Decision
Use **platform-native ORMs**:
- iOS: Core Data
- Android: Room

## Consequences
**Positive:**
- Native performance and optimization
- Platform-standard patterns (DAOs, entities)
- Migration support built-in
- Publisher/Flow integration for reactive updates

**Negative:**
- Different APIs require platform-specific code
- Core Data testing requires in-memory store setup
- Schema changes need careful migration planning