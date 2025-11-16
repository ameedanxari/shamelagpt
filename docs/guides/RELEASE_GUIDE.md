# Release Guide

This document outlines the process for releasing a new version of ShamelaGPT.

## 1. Versioning
We use **Semantic Versioning** (MAJOR.MINOR.PATCH).
- MAJOR: Breaking changes or major feature overhaul.
- MINOR: New features, parity updates.
- PATCH: Bug fixes.

## 2. Pre-Release Checklist
- [ ] iOS unit & UI tests pass.
- [ ] Android unit & instrumented tests pass.
- [ ] Parity verified for all new features.
- [ ] Localization complete for new strings (EN/AR).
- [ ] Legal strings (Privacy/Terms) updated if necessary.
- [ ] App icon and branding verified.

## 3. iOS Submission (App Store)
1. Increment `CFBundleShortVersionString` and `CFBundleVersion` in Xcode.
2. Build Archive (`Generic iOS Device` target).
3. Validate Archive in Organizer.
4. Upload to TestFlight.
5. Submit for Review via App Store Connect.

## 4. Android Submission (Google Play)
1. Increment `versionName` and `versionCode` in `build.gradle.kts` (or `libs.versions.toml`).
2. Run `./gradlew bundleRelease`.
3. Sign the `.aab` file using the upload key.
4. Upload to Internal Testing or Beta track in Play Console.
5. Promote to Production.

## 5. Post-Release
- Create a GitHub Release with changelog.
- Tag the commit with the version number (e.g., `v1.2.0`).
- Update the `CHANGELOG.md` in the root.
