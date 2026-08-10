# iOS Simulator Runbook (agent-operable)

How to build, run, and **drive** the iOS app in the Simulator without Xcode's UI —
including the signing workarounds this repo needs, and the hard limitations.

Companion to `SETUP_IOS.md` (human setup) and `TROUBLESHOOTING_IOS.md`.

---

## 1. Machine prerequisites

| Requirement | Check | Fix |
|---|---|---|
| Full Xcode (not just CLT) | `xcode-select -p` → must end in `Xcode.app/Contents/Developer` | `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` |
| iOS runtime installed | `xcrun simctl list runtimes` | Xcode → Settings → Components |
| A simulator device | `xcrun simctl list devices available` | Xcode → Window → Devices & Simulators |

Verified working on: **Xcode 26.6, iOS 26.5 runtime, iPhone 17 Pro simulator, macOS Darwin 25.6.**

---

## 2. Signing — why the obvious path fails

The project targets **`DEVELOPMENT_TEAM = SSTKXHNR6U`** (paid team) and declares
`associated-domains` in `shamelagpt/ShamelaGPT.entitlements`.

Opening the project and hitting ⌘R on a machine whose Apple ID is **not a member of
that team** fails at the signing step, not the compile step:

```
No Account for Team "SSTKXHNR6U"
No profiles for 'com.shamelagpt.ios' were found
```

Switching the Team dropdown to a **free personal team** does not fix it — it trades one
error for two:

```
Personal development teams ... do not support the Associated Domains capability
Failed Registering Bundle Identifier: com.shamelagpt.ios.FactCheckShareExtension
  cannot be registered to your development team
```

Both are inherent to free teams (see §7 Limitations).

### The fix: ad-hoc sign, do **not** build unsigned

**Simulator builds do not need a *team*, but they do need to be signed.**

The obvious move is to turn signing off entirely:

```bash
# ⛔️ DO NOT USE — breaks the Keychain
CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

It builds and launches fine, and it is **actively misleading**. An unsigned app has no
`application-identifier` entitlement, so the whole Keychain API is unavailable. Every
`SecItemAdd` / `SecItemCopyMatching` returns **`errSecMissingEntitlement (-34018)`**.

`KeychainHelper` used to discard those statuses, so the failure was completely silent and
produced a very convincing fake bug:

1. Sign-in succeeds (HTTP 200) and the app moves to the chat screen — `isAuthenticated`
   is in-memory, so the UI looks correct.
2. `saveSession` writes the token to the Keychain — the write fails, silently.
3. The next request reads the token back — `nil`, so `APIClient` omits the
   `Authorization` header entirely.
4. Server answers **403 `{"detail":"Not authenticated"}`**.
5. `handleError` sets `requiresAuth`, and the user is dumped on the login screen.

Read as "the app signs me out the moment I send a message" — but nothing is wrong with the
app. It is purely an artefact of building unsigned. **Never debug auth on an unsigned build.**

Use **ad-hoc signing** with an explicit keychain entitlement instead. Still no team, no
Apple ID, no provisioning profile:

```bash
cat > /tmp/sim.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>application-identifier</key>
	<string>com.shamelagpt.ios</string>
	<key>keychain-access-groups</key>
	<array><string>com.shamelagpt.ios</string></array>
</dict>
</plist>
EOF

CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
CODE_SIGN_ENTITLEMENTS=/tmp/sim.entitlements \
DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER=""
```

Note this entitlements file deliberately omits `associated-domains` — that is the
capability a free team cannot have, and it is not needed to run in the simulator.

**Sanity check before trusting any auth-related result:**

```bash
xcrun simctl spawn "$DEV" log stream --style compact \
  --predicate 'subsystem == "com.shamelagpt.ios"' | grep -i keychain
```

Any `Keychain WRITE/READ failed ... -34018` means you are on an unsigned build and every
authenticated request will 403. Fix the build before believing anything else you see.

> **Do not commit a `DEVELOPMENT_TEAM` change.** Flipping the team in Xcode's UI rewrites
> `project.pbxproj` for every target. Committing a personal team ID breaks device builds,
> TestFlight, and CI for everyone else. `git checkout` that file when you're done.

---

## 3. Build, install, launch

```bash
IOS_DIR=mobile_app/shamelagpt/shamelagpt-ios
DEV="iPhone 17 Pro"
DD=/tmp/shamela-dd          # keep DerivedData out of the repo

# 1. Build (ad-hoc signed — see §2 for why NOT unsigned)
xcodebuild \
  -project "$IOS_DIR/ShamelaGPT.xcodeproj" \
  -scheme ShamelaGPT \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$DEV" \
  -derivedDataPath "$DD" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_ENTITLEMENTS=/tmp/sim.entitlements \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  build

# 2. Boot + install + launch
xcrun simctl boot "$DEV" 2>/dev/null || true
open -a Simulator
xcrun simctl install "$DEV" "$DD/Build/Products/Debug-iphonesimulator/ShamelaGPT.app"
xcrun simctl launch "$DEV" com.shamelagpt.ios
```

Useful follow-ups:

```bash
xcrun simctl terminate "$DEV" com.shamelagpt.ios     # stop
xcrun simctl uninstall  "$DEV" com.shamelagpt.ios    # wipe app + its storage
xcrun simctl io "$DEV" screenshot out.png            # capture device screen (no chrome)
xcrun simctl spawn "$DEV" log stream --predicate 'processImagePath CONTAINS "ShamelaGPT"'
xcrun simctl pbcopy "$DEV" < some.txt                # push text to device pasteboard
```

`xcodebuild` output is extremely verbose. Filter it:

```bash
... build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)"
```

---

## 4. Driving the UI (the part that isn't obvious)

`simctl` can install, launch, screenshot, and set the pasteboard — but it has **no tap or
type command**. Two ways to actually interact:

### 4a. AppleScript + the Accessibility bridge — *preferred for exploration*

The Simulator republishes the **iOS app's accessibility tree** into macOS's AX API. That
means you can find and press *real elements by label*, with no pixel coordinates:

```bash
# Enumerate the tree
osascript -e 'tell application "System Events" to tell process "Simulator" \
  to tell window 1 to get entire contents'

# Read labels + positions of buttons in a container
osascript <<'EOF'
tell application "System Events" to tell process "Simulator" to tell window 1
  set g to group 1 of group 1 of group 1 of group 1 of group 1 of group 1
  repeat with b in (buttons of g)
    log (description of b) & " @ " & (position of b as string)
  end repeat
end tell
EOF

# Press a button by its label
osascript -e 'tell application "System Events" to tell process "Simulator" to tell window 1 \
  to click (first button of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 \
  whose description is "Get Started")'

# Type into the focused field (goes through the Mac hardware keyboard)
osascript -e 'tell application "Simulator" to activate'
osascript -e 'tell application "System Events" to keystroke "hello@example.com"'
```

**Requirements and gotchas — all of these bit us:**

| Gotcha | Symptom | Handling |
|---|---|---|
| Accessibility permission | `osascript is not allowed assistive access (-1719)` | Grant **Accessibility** to the app that *spawns the shell* (e.g. Visual Studio Code, Terminal, iTerm) in System Settings → Privacy & Security → Accessibility, then **restart that app**. Walk the parent chain with `ps -o ppid=` to find it. |
| Simulator must be frontmost | `entire contents` returns `0` elements | `osascript -e 'tell application "Simulator" to activate'` before each interaction. |
| Tree goes permanently stale | count stays `0` after activating | Relaunch the app (`simctl terminate` + `launch`). The AX bridge does not always recover in place. |
| Multi-display | Window `position` has a **negative** Y | Normal — it's on a display above the main one. AX clicks still work; `screencapture -R` also accepts negative origins. Prefer `simctl io screenshot` and avoid coordinates entirely. |
| Deep, brittle paths | `Can't get group 1 of ... Invalid index` | SwiftUI nests ~17 `group 1` levels and the depth **changes per screen**. Build the reference in a loop (`repeat 17 times / set g to group 1 of g`) or search `entire contents` by `description` instead of hardcoding a path. |
| `class of e` comparisons fail | `Can't make item 1 ... into type specifier (-1700)` | Don't compare `class`. Wrap `description of e` in `try` and match on the string. |
| Edit menu steals keystrokes | Field shows a caret but typing does nothing; a `Paste / AutoFill` bubble is visible | Dismiss it first (tap elsewhere / `key code 53`), re-focus, then type. Verify with a screenshot before submitting. |
| Keystrokes double up | Secure field shows 2× the expected dot count | The earlier `keystroke` landed late. Clear with `repeat 30 times / key code 51` and retype once. Always verify the character count. |
| Software keyboard absent | — | Expected: the Mac hardware keyboard is connected, so iOS hides the on-screen one. `keystroke` still reaches the app. In XCUITest this means `app.keyboards.firstMatch` does **not** exist — never assert on it. Assert on the field's `value` after typing instead. |

### 4b. XCUITest — *preferred for anything repeatable*

Needs **no** Accessibility permission and is immune to the AX-bridge staleness. The repo
already has a suite with stable identifiers in
`ShamelaGPTUITests/Helpers/UITestIDs.swift` (`UITestID.Auth.emailTextField`, etc.).

```bash
xcodebuild test \
  -project "$IOS_DIR/ShamelaGPT.xcodeproj" \
  -scheme ShamelaGPTUITests \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$DEV" \
  -derivedDataPath "$DD" \
  -resultBundlePath /tmp/res.xcresult \
  -only-testing:ShamelaGPTUITests/AuthUITests \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

- The target uses **file-system synchronized groups** (Xcode 16+), so a `.swift` file
  dropped into `ShamelaGPTUITests/` is compiled automatically — no `project.pbxproj` edit.
- The standard suite runs against **mocked** networking (`NetworkMockHelper`,
  `UITestLauncher.launch`). To hit the **real** backend, construct `XCUIApplication()`
  yourself and set only `launchEnvironment` you need — do **not** call `UITestLauncher`.
- Screenshots: `XCTAttachment(screenshot: app.screenshot())` with
  `lifetime = .keepAlways`, then pull them out of the `.xcresult` with `xcrun xcresulttool`.

**Choosing:** AX/AppleScript for one-off manual driving and quick visual checks;
XCUITest for anything that must be re-run, asserted, or put in CI.

**Assert on presence, never only on absence.** A driver whose only check is "no error
banner appeared" passes trivially when the app is sitting on the login screen and nothing
was ever sent. This has already produced one confidently-reported false PASS. Every driver
should assert, in order:

1. the typed text actually landed — `XCTAssertTrue((field.value as? String ?? "").contains(...))`
2. the send landed — the question appears in the transcript
3. the failure states are absent — no error banner **and** no auth screen

and use `continueAfterFailure = false` so it stops at the first broken link instead of
sailing on to a meaningless green.

---

## 5. What the app talks to

- Live base URL: **`https://shamelagpt.com`** — `Core/Networking/APIClient.swift`
  (`Configuration.baseURLString`).
- `Core/Utilities/Constants.swift` also defines `https://api.shamelagpt.com`, but **nothing
  injects it**. Don't be misled — changing it has no effect.
- The simulator therefore hits **production** by default. Any sign-in you perform creates
  real data. Use a disposable account.

---

## 6. Known-good smoke path

1. Build + install + launch (§3).
2. Welcome → `Get Started`.
3. Auth screen → email, password → `Sign In`.
4. Land on chat with the `Chat / History / Settings` tab bar.
5. Send a message; expect a streamed answer.

Screenshot after **every** step — the AX tree lies more often than the pixels do.

---

## 7. Limitations (read before promising anything)

**Free personal Apple team cannot:**
- Use **Associated Domains** → universal links (`applinks:shamelagpt.com`) can't be tested.
- Use **Sign in with Apple** (`com.apple.developer.applesignin`) — requires paid membership.
- Use Push Notifications.
- Register bundle IDs already claimed by another team (`com.shamelagpt.ios` and both
  extension IDs are owned by `SSTKXHNR6U`).

→ Any work on those features needs the Apple ID added to team **`SSTKXHNR6U`**.

**Simulator cannot:**
- Use the **camera** (blocks OCR / fact-check-from-photo capture paths).
- Reliably exercise the **microphone** (voice input).
- Test push notifications end-to-end (only `simctl push` with a payload file).
- Reproduce real cellular conditions, thermals, or true performance.
- Run **Sign in with Apple** without an iCloud account signed into the simulator.

**Unsigned builds cannot:**
- Use the **Keychain at all** (`-34018`). Auth silently breaks in a way that looks exactly
  like a server-side sign-out. See §2 — always ad-hoc sign.

**Tooling cannot:**
- Tap or type via `simctl` — see §4.
- Keep the AX bridge alive indefinitely — expect to relaunch.
- Read very large screenshots in some agent contexts — downscale first:
  `sips --resampleHeightWidthMax 1000 in.png --out out.png`.

---

## 8. Cleanup checklist

- [ ] `git checkout shamelagpt-ios/ShamelaGPT.xcodeproj/project.pbxproj` if you touched the Team dropdown
- [ ] Delete any temporary `*UITests.swift` driver files you dropped in
- [ ] `xcrun simctl uninstall "$DEV" com.shamelagpt.ios` if you signed into a real account
- [ ] Confirm `git status` is clean apart from intended changes
