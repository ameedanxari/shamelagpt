# ADR-003: Repository Pattern for Data Access

**Status**: Accepted
**Date**: 2025-11-02

## Context
Need to abstract data sources (remote API, local database) from business logic.

## Decision
Implement **Repository pattern** with:
- Protocol/interface definitions in Domain layer
- Implementations in Data layer
- Single source of truth for data operations

## Consequences
**Positive:**
- Testable business logic with mock repositories
- Easy to swap data sources
- Clear abstraction over persistence details
- Offline-first capability enabled

**Negative:**
- Additional layer of indirection
- Need to maintain mapper code