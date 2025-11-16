# AI Prompt Library - Project Brief

## Purpose
Serve as both user input form and project README, collecting project requirements and configuration preferences to generate comprehensive software specifications.

---

## Project Brief (Required)

**What do you want to build and why?**

**Brief**: Help me fix tests and improve coverage on iOS and Android. While most of the functionality is working fine, the tests still fail. The main reasons identified are:
- There is a mismatch on how the UI elements are checked for. Tests fail even if UI renders correctly. The failures are very consistent in this state
- Sometimes the mocks are not properly configured or present at all. This leads to inconsistent state where the test is correctly testing for a functionality that is otherwise also implemented correctly, but just not testable because of mocks.
- There maybe genuine corner cases as well where UI is not being rendered correctly. Logs should be present to help identify, trace, debug and fix such issues
- The UI tests are many in number and take a LONG time to execute. This task should be broken into test by test or file by file tasklist to ensure that all tests can be reliably tested and fix with limited noise and in a token optimized manner

---

## Optional Configuration (Power Users)

### Target Platforms
- [x] iOS Mobile App  
- [x] Android Mobile App
- [x] API/Backend Only (existing backend, need to test client-side integration)

### Technology Preferences

**Mobile Development Approach:**
- [x] Native iOS/Android (separate codebases) - **Already implemented**
  - iOS: Swift + SwiftUI + Combine
  - Android: Kotlin + Jetpack Compose + Coroutines

**Backend Architecture:**
- [x] Existing serverless backend (API already deployed)

### Deployment Environment

**Cloud Provider:**
- [x] Existing infrastructure (no changes needed)

**Budget Preference:**
- [x] Let system optimize for cost

### Localization and Accessibility

**Target Languages:**
- Primary: English (en)
- Additional: Arabic (ar), Urdu (ur)

**Accessibility Requirements:**
- [x] WCAG 2.1 AA compliance (recommended)

**Right-to-Left (RTL) Support:**
- [x] Yes, include RTL language support (Arabic)

### Design and Branding

**Color Theme Preference:**
- [x] Both light and dark modes (already implemented)

**Branding Requirements:**
- [x] Fixed branding (Emerald #10B981 + Amber #F59E0B color scheme)

**Design Assets Available:**
- [x] I have existing designs/mockups (app is already built)
- [x] I have brand guidelines (docs/THEMING.md)

### Advanced Configuration

**Architecture Preferences:**
- [x] MVVM architecture (already implemented on both platforms)

**Database Preferences:**
- iOS: Core Data + SwiftData
- Android: Room Database

**Authentication Preferences:**
- [x] Email/Password authentication
- [x] Social login (Google)
- [x] Guest mode (local-only)

**Token Usage Level:**
- [x] **High**: Comprehensive verification with full testing (thorough approach needed)

**COVE (Chain-of-Verification):**
- [x] **Enabled** (Default): Use verification checkpoints to reduce hallucinations and stale assumptions

---

## Reference Assets (Available)

### Existing Documentation
- `docs/PROJECT_STATUS.md` - Current state and completion tracking
- `docs/USE_CASES.md` - Comprehensive use cases and feature checklist
- `docs/THEMING.md` - Color palette and design system
- `docs/QUICK_REFERENCE.md` - Developer cheat sheet
- `AGENTS.md` - AI agent instructions (existing)
- `.claude/` - Claude-specific steering files

### Platform Documentation
- `shamelagpt-ios/docs/` - iOS architecture, features, API, UI/UX, build guide
- `shamelagpt-android/docs/` - Android architecture, features, API, UI/UX, build guide

### Test Plans (Existing)
- `docs/iOS_TEST_PLAN.md` - iOS test strategy
- `docs/ANDROID_TEST_PLAN.md` - Android test strategy

---

## Dry-Run Option

**Validation Mode:**
- [x] **Full Generation**: Complete specifications and implementation plans

---

## Key Constraints & Considerations

1. **Existing Codebase**: This is an enhancement project, not greenfield development
2. **Working Functionality**: All current features must remain functional
3. **Platform Parity**: iOS and Android must maintain feature parity
4. **No Breaking Changes**: Refactoring must preserve existing behavior
5. **Test-First Approach**: New tests should validate existing functionality first
6. **Documentation Sync**: Documentation must reflect actual implementation

---

## Success Criteria

### Documentation
- [ ] Single source of truth for project documentation
- [ ] Clear onboarding path for contributors (`PROJECT_STATE.md` + `NEXT_ACTION.md` + `AGENTS.md`)
- [ ] API documentation matches implementation (`docs/api/openapi_latest.json`)
- [ ] Architecture decisions documented with rationale

### Code Quality
- [ ] Consistent patterns across platforms (MVVM)
- [ ] No obvious code smells or anti-patterns
- [ ] Clear separation of concerns
- [ ] Proper error handling throughout

### Testing
- [ ] 80%+ unit test coverage for business logic
- [ ] Integration tests for critical API-backed flows
- [ ] UI tests for critical user flows across en/ar/ur
- [ ] Edge cases identified and tested (offline/empty/error states)
- [ ] CI pipeline executes tests automatically

---

*This project brief describes enhancement work on an existing, production-ready mobile application.*
