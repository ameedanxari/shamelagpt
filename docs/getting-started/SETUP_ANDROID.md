# Android Setup Guide

This guide details the steps to set up the Android development environment for ShamelaGPT.

## Prerequisites
- **Android Studio Hedgehog** (2023.1.1) or newer.
- **Java Development Kit (JDK) 17**.
- **Android SDK Platform 34** (UpsideDownCake).

## Getting Started

1. **Clone the project**:
   ```bash
   git clone https://github.com/your-org/ShamelaGPT.git
   cd ShamelaGPT/shamelagpt-android
   ```

2. **Open in Android Studio**:
   - File > Open...
   - Select the `shamelagpt-android` directory.

3. **Gradle Sync**:
   - Allow Android Studio to perform a Gradle sync. This will download all necessary dependencies including Jetpack Compose, Koin, Retrofit, and Room.

4. **KSP Setup**:
   - This project uses KSP (Kotlin Symbol Processing) for Room. Ensure the KSP plugin is compatible with your Kotlin version (managed in `libs.versions.toml`).

## Environment Variables / Secrets
The app uses a `local.properties` file for sensitive configuration (like API Keys if any are added in the future). Currently, the base URL is hardcoded in `Constants.kt` for development.

## Running the App
- Select a device or emulator (API Level 26+ recommended).
- Click the "Run" button (Green Play Icon).

## Running Tests

### Unit Tests
Run from the terminal:
```bash
./gradlew test
```
Or right-click the `src/test` folder in Android Studio and select "Run 'Tests in...'".

### UI Tests (Instrumented)
Ensure an emulator or device is connected:
```bash
./gradlew connectedAndroidTest
```
Or right-click the `src/androidTest` folder.

## Build Variants
- `debug`: Development build with logging enabled.
- `release`: Production build with R8/ProGuard enabled.

## Common Gradle Commands
- `./gradlew clean`: Clean the build.
- `./gradlew assembleDebug`: Build debug APK.
- `./gradlew bundleRelease`: Build release App Bundle (AAB).
