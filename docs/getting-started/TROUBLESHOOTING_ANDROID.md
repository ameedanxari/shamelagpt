# 🔧 Android Troubleshooting Guide

Common issues encountered when building or running the Android project and how to fix them.

## Build Issues

### "JDK Location not found" or "Incorrect JDK version"
**Error**: Gradle sync fails with JDK errors.
**Fix**:
1. Check `File > Project Structure > SDK Location > Gradle Settings`.
2. Ensure **Gradle JDK** is set to **Java 17** (e.g., `jbr-17` or `temurin-17`).
3. Does your `JAVA_HOME` environment variable point to JDK 17?

### "Koin / Dependency Injection crashes"
**Error**: `Caused by: org.koin.core.error.NoBeanDefFoundException`
**Fix**:
1. Did you add your new ViewModel/Repository to the Koin modules?
2. Check `app/src/main/java/com/shamelagpt/android/di/AppModule.kt`.
3. Ensure you use `viewModel { ... }` for ViewModels and `single { ... }` for singletons.

### "Unresolved reference: R"
**Error**: All resource IDs are red.
**Fix**:
1. This is usually due to an XML error preventing `R.java` generation.
2. Check your layout XMLs or `strings.xml` for typos.
3. Run `Build > Clean Project` then `Build > Rebuild Project`.

## Emulator / Runtime Issues

### App crashes immediately on launch
**Fix**:
1. Check Logcat (`Cmd+6` on Mac).
2. Filter by `Error` level.
3. Look for "Fatal Exception". Common causes: missing permissions in `AndroidManifest.xml` or missing DI definitions.

### "Emulation engine failed"
**Fix**:
1. Check if you have enough disk space.
2. Try "Cold Boot Now" from the Device Manager actions menu.
3. If on Apple Silicon (M1/M2/M3), ensure you downloaded the **ARM64** system image, not x86.

## Gradle Issues

### "Connection timed out" downloading dependencies
**Fix**:
1. Check your internet connection.
2. Toggle "Offline Mode": opens Gradle tool window -> Toggle Offline Mode button -> Sync -> Untoggle -> Sync again.
3. Verify proxy settings in `gradle.properties` if you are on a corporate network.

### Duplicate Class / Dependency Conflict
**Error**: `Duplicate class found`
**Fix**:
1. Run `./gradlew app:dependencies` to see the tree.
2. You might have transitive dependencies clashing (e.g., different versions of Kotlin stdlib).
3. Exclude the module in `build.gradle.kts`:
   ```kotlin
   implementation("com.example:library:1.0") {
       exclude(group = "org.jetbrains.kotlin")
   }
   ```
