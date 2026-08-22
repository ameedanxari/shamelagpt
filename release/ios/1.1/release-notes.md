# ShamelaGPT iOS — release material for 1.1

Two different audiences, two different documents. Do not paste the second into the first.

---

## 1. App Store "What's New" — user-facing

App Store Connect field: **What's New in This Version**. 4000 character limit; the first two lines are what most people actually read.

Ship the localised versions too — the app supports Arabic and Urdu, and release notes are localised per App Store language.

### English

```
Choose your school of thought

You can now select a madhhab — Hanafi, Maliki, Shafi'i, Hanbali, or all
four — in Settings. Answers are drawn from the sources of the school you
choose. If you already set this on the web, the app now reflects it.

See how an answer was reached

Longer answers can now show the reasoning behind them in a panel you can
open or collapse as you like.

A faster, better-ordered history

Your conversations now load immediately and appear in the right order,
with the most recent at the top. Older conversations open just as quickly
when you tap them.

Privacy and security improvements

Signing out now removes your conversations from the device, and signing
in is handled more securely. Installing the app fresh now correctly
starts you at the sign-in screen.
```

### Arabic and Urdu

**Do not machine-translate these.** The app's existing Arabic and Urdu copy was written properly, and release notes sit alongside it in the store listing. Send the English above to whoever reviews issue #70 — the same person can do both in one pass.

Two terminology points for them:
- "school of thought" is مذهب / مکتب in the existing app copy — match it.
- "reasoning" ships in-app as التفكير المنطقي / استدلال — the release note should use the same word users will see on screen.

---

## 2. Internal changelog — for the team, not the store

### New

- **Madhhab preference** (#37) — Settings row and picker showing each school's name, Arabic name, founder and death year. Reads and writes `/api/auth/me/madhab`, so a preference set on web now appears in the app. Writes are not optimistic: the picker only moves once the server confirms, and adopts the value the server echoes back.
- **Reasoning panel** (#59) — consumes the backend's new `reasoning` SSE channel. Collapsed by default. Persisted with the message, so it survives a reload. Required a Core Data migration (v2 → v3).

### Fixed — user-visible

- **History was not ordered by recency** (#69). The sync wrote each conversation's real timestamp and then immediately overwrote it with the sync time, so ordering was whatever sequence the loop ran in.
- **History was slow to settle** (#69). The list sync fetched every conversation's message bodies — on a large account, hundreds of requests before the list appeared. Bodies now load when a conversation is opened.
- **Signing out left conversations on the device** (#62). Readable by the next person to use the phone, including photographed documents.
- **A fresh install could come back already signed in** (#58).

### Fixed — invisible but severe

- **Stored passwords** (#58). Login persisted the user's email and password and replayed them on launch. Removed; restore now uses the refresh token only. Keychain items are `AfterFirstUnlockThisDeviceOnly`, so they no longer travel in device backups. Android had the same flaw, fixed separately in #60.
- **A malformed `expires_in` expired the session instantly** (#36). Latent — the backend sends a parseable value today — but it would have sent every request unauthenticated with nothing in the logs.
- **Authenticated routes could be dispatched as a guest** (#69), producing quiet 403s with no exception and no Sentry event. The transport now refuses them. This found a live case: every guest who opened History.
- **Mappers invented dates and ids for incomplete rows** (#71).

### Release plumbing

- Privacy manifests for the app and both extensions (#61) — required for submission, previously absent.
- `CURRENT_PROJECT_VERSION` incremented (#61) — had never been, which App Store Connect rejects.
- TestFlight workflow and `ExportOptions.plist` (#72).

---

## 3. App Store Connect — what else has to be filled in

Beyond release notes, a first submission needs:

- **Privacy nutrition label.** Derived from the manifest added in #61: email address, name, user id, user content (questions and conversations), photos (OCR), audio (voice input). All linked to the user, all for app functionality, none for tracking.
- **Open question worth deciding before submission:** whether users' questions in a religious-guidance app should additionally be declared as *sensitive information*. Apple's category explicitly includes religious beliefs. Declared as user content today, which is accurate for what is transmitted; the classification is a product and legal call.
- **Screenshots.** `StoreScreenshotUITests` and `TargetedScreenshotUITests` already exist and can generate them.
- **Age rating, support URL, marketing URL, description, keywords.**
- **Export compliance** — already answered in `Info.plist` (`ITSAppUsesNonExemptEncryption = false`), so the upload will not prompt.

---

## 4. Known, and not fixed in this version

State these to the team, not to the store.

- `iOS UI Tests` red on `main` since 12 August (#64).
- Five Arabic/Urdu strings in the madhhab feature await native-speaker review (#70).
- Nothing in this release has run on a physical device — all verification was simulator plus live API calls against production.
