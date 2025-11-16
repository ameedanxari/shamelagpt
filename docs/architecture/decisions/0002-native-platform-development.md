# ADR-002: Native Platform Development

**Status**: Accepted
**Date**: 2025-11-02

## Context
Need to decide between cross-platform framework (React Native, Flutter, KMP) vs native development for iOS and Android.

## Decision
Use **native development** with separate codebases:
- iOS: Swift + SwiftUI
- Android: Kotlin + Jetpack Compose

## Consequences
**Positive:**
- Best performance and native UX
- Full access to platform APIs (OCR, Voice, Camera)
- Optimal App Store/Play Store integration
- Platform-specific optimizations possible

**Negative:**
- Two codebases to maintain
- Feature parity requires coordination
- Higher initial development cost

## Alternatives Considered
- **React Native**: Would require native modules for OCR/Voice anyway
- **Flutter**: Less native feel, Dart learning curve
- **KMP**: Could share business logic, but added complexity