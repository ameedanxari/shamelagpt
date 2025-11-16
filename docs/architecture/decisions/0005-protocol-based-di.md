# ADR-005: Protocol-Based Dependency Injection

**Status**: Accepted
**Date**: 2025-11-02

## Context
Need to support dependency injection for testability without heavy framework overhead.

## Decision
Use **protocol/interface-based DI**:
- iOS: Custom `DependencyContainer` with factory methods
- Android: Koin with module-based configuration

## Consequences
**Positive:**
- Enables mock injection for testing
- Loose coupling between components
- Factory methods for configurable instantiation
- UI test support with mock network layer

**Negative:**
- iOS container is basic (Swinject available but unused)
- Manual registration required on iOS

## Future Consideration
Consider enabling Swinject on iOS for lifecycle management and autowiring.