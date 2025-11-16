/* implementation.md — concise decision tree & placement rules */

Decision rules (minimal):
- SEARCH first: if similar exists, EXTEND it.
- If existing code handles >=80% behavior, add method/flag; else create new file pair on both platforms.

Where to place code:
- API calls → Service/Repository
- Business logic/state → ViewModel
- UI → View/Composable
- Models/DTOs → Model layer
- Utilities → Utilities/Extensions

Naming and structure:
- Follow existing module/package paths.
- Keep single responsibility; small functions; prefer composition over inheritance.

Testing:
- New code → unit tests (mocks) + one happy-path integration test (mocked network).
