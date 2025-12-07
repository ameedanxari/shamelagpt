/* parity.md — platform mapping & parity rules (agent-optimized) */

Constraints:
- Default: apply changes to BOTH Android + iOS unless explicitly flagged
- MVVM enforced: Views ↔ ViewModels ↔ Services/Repositories
- No network in Views

Platform mapping (common tokens):
- Android: `@Composable`, `ViewModel+StateFlow`, `Retrofit`, `Gson`
- iOS: SwiftUI `View`, `ObservableObject+@Published`, `URLSession`, `Codable`

Parity rules (do in order):
1. Search for existing feature on both platforms
2. Implement on one platform following local conventions
3. Mirror behavior/naming/DTOs on the other platform
4. Keep tests and mocks same contract

Edge cases:
- If platform limitation prevents full parity, add a short rationale in PR description and a TODO ticket.
