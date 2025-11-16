/* testing.md — required tests & mocking patterns (agent-optimized) */

Required tests for any change:
- Unit tests for business logic and mappers
- Network layer tests: use MockK (Android) / MockURLProtocol or protocol mocks (iOS)
- Error branches: 400/401/403/404/429/500
- Edge cases: empty input, very long input, special characters, RTL text

Mocking patterns:
- Android: MockK + coEvery { repo.call(...) } returns Result.success(x)
- iOS: Provide test double conforming to APIClient protocol; inject into repo

CI commands (quick):
- Android unit tests: `./gradlew test`
- iOS unit tests: `xcodebuild test -scheme ShamelaGPT`

Notes: Never run live network tests in CI. Use stable deterministic fixtures.
