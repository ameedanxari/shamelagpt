# ADR-001: MVVM Architecture Pattern

**Status**: Accepted
**Date**: 2025-11-02

## Context
Need to select an architecture pattern for both iOS and Android platforms that supports:
- Clean separation of concerns
- Testability of business logic
- Modern declarative UI frameworks (SwiftUI, Jetpack Compose)
- Platform parity

## Decision
Adopt **MVVM (Model-View-ViewModel)** architecture on both platforms:
- iOS: MVVM + Coordinator pattern for navigation
- Android: MVVM + Clean Architecture layers

## Consequences
**Positive:**
- Native fit with SwiftUI's `@ObservableObject` and Compose's `ViewModel`
- ViewModels can be unit tested without UI
- Clear separation enables parallel development
- Industry standard, easy to onboard new developers

**Negative:**
- ViewModels can become large (e.g., ChatViewModel: 1381 lines)
- Requires careful state management across layers

## Alternatives Considered
- **MVI (Model-View-Intent)**: More strict unidirectional flow, slightly more complex
- **VIPER**: Too much ceremony for mobile app of this size
- **MVP**: Doesn't align naturally with declarative UI