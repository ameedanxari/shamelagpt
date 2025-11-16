# ADR-007: Localization Strategy

**Status**: Accepted
**Date**: 2025-11-02

## Context
App supports English, Arabic (RTL), and Urdu. Need consistent localization approach.

## Decision
Use **platform-native localization**:
- iOS: `Localizable.strings` with `NSLocalizedString`
- Android: `strings.xml` with `stringResource()`
- RTL layout support via layout direction APIs

## Consequences
**Positive:**
- Platform-standard approach
- Automatic RTL layout support
- Easy to add new languages
- App Store/Play Store localization integration

**Negative:**
- Duplicate string files across platforms
- String key synchronization required