/* quick_rules.md — minimal grep/build/test commands for agents */

Search patterns:
- Find ViewModels: `rg "class .*ViewModel" -g "**/*.kt"`
- Find SwiftUI Views: `rg "struct .*View: View" -g "**/*.swift"`
- Find API methods: `rg "suspend fun .*" -g "**/*.kt"` and `rg "func .*async" -g "**/*.swift"`

Build/test commands:
- Android build: `cd shamelagpt-android && ./gradlew assembleDebug`
- Android tests: `./gradlew test`
- iOS tests: `xcodebuild test -scheme ShamelaGPT`

Quick grep tips: use alternation for multiple keywords: `rg "search|filter|favorite" -i`
