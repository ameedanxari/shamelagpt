# ShamelaGPT Android - Troubleshooting Guide

## Version: 1.0
## Target: Android 8.0+ (API 26+)

---

## 🔧 Common Issues & Solutions

---

## 📦 Project Setup Issues

### Issue: "Gradle sync failed"
**Error**: Various Gradle sync errors

**Solution**:
1. Check internet connection (Gradle needs to download dependencies).
2. File → Sync Project with Gradle Files.
3. File → Invalidate Caches / Restart...
4. Verify `local.properties` contains valid `sdk.dir`.
5. Check `settings.gradle.kts` for correct plugin repositories.

### Issue: "Unresolved reference" in imports
**Error**: Classes not found despite being in project

**Solution**:
1. Build → Clean Project.
2. Build → Rebuild Project.
3. File → Sync Project with Gradle Files.
4. Check if the dependency is correctly added in `build.gradle.kts`.

### Issue: "Manifest merger failed"
**Error**: Attribute application@appComponentFactory value=(...) from [com.android.support:support-compat:...]

**Solution**:
1. Ensure you are using AndroidX artifacts (check `gradle.properties` for `android.useAndroidX=true`).
2. Check for conflicting dependencies in `build.gradle.kts`.
3. Run `./gradlew app:dependencies` to see dependency tree.

---

## 💾 Room Database Issues

### Issue: "Schema export directory is not provided"
**Error**: Room cannot export schema

**Solution**:
1. In `build.gradle.kts`, ensure `ksp` arguments are set:
```kotlin
ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}
```
2. Or disable schema export in `@Database` annotation: `exportSchema = false`.

### Issue: "Migration didn't properly handle"
**Error**: Room cannot migrate database

**Solution**:
1. Uninstall the app to clear old data (Development only).
2. Increment database version in `AppDatabase`.
3. Provide a `Migration` strategy or use `.fallbackToDestructiveMigration()` in database builder.

### Issue: "Cannot access database on the main thread"
**Error**: `IllegalStateException`

**Solution**:
1. Use `suspend` functions in DAOs.
2. Call database operations within a Coroutine (`viewModelScope.launch` or `Dispatchers.IO`).
3. Don't allow main thread queries in database builder (unless for testing).

---

## 🌐 Networking Issues

### Issue: API call returns 500 error
**Error**: "Internal Server Error"

**Context**: Conversation management endpoints don't work yet.

**Solution**:
1. Only use `/api/chat` endpoint.
2. Store conversations locally in Room.
3. Don't try to create/fetch conversations from API.

### Issue: "Cleartext HTTP traffic not permitted"
**Error**: `IOException` when calling API

**Solution**:
1. Ensure API URL is `https://`.
2. If using local server (http), add `android:usesCleartextTraffic="true"` to `<application>` in `AndroidManifest.xml` (Development only).

### Issue: Response parsing fails
**Error**: `JsonDecodingException` or `MalformedJsonException`

**Solution**:
1. Enable logging interceptor in `NetworkModule`:
```kotlin
val logging = HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BODY }
```
2. Check Logcat for raw JSON response.
3. Verify `data class` properties match JSON keys (or use `@SerializedName`).
4. Check for nullability mismatches.

---

## 🎤 Voice Input Issues

### Issue: "RecognitionService unavailable"
**Error**: SpeechRecognizer returns error

**Solution**:
1. Check if Google App is installed and enabled on device/emulator.
2. Emulator might not support speech recognition; use physical device.
3. Check internet connection (some recognizers require it).

### Issue: Permission denied for microphone
**Error**: `SecurityException`

**Solution**:
1. Check `AndroidManifest.xml` has `<uses-permission android:name="android.permission.RECORD_AUDIO" />`.
2. Request permission at runtime using `ActivityResultLauncher`.
3. Check App Info → Permissions in device settings.

---

## 📷 Image/OCR Issues

### Issue: ML Kit not recognizing text
**Error**: Text recognition returns empty

**Solution**:
1. Ensure image is focused and well-lit.
2. Check if correct model is downloaded (ML Kit downloads model on first use).
3. Check Logcat for ML Kit errors.
4. Ensure `com.google.mlkit:text-recognition` dependency is correct.

### Issue: Camera crash
**Error**: App crashes when opening camera

**Solution**:
1. If using `ActivityResultContracts.TakePicture`, ensure URI is valid (use `FileProvider`).
2. Confirm `FileProvider` is configured correctly in `AndroidManifest.xml`.
3. Verify temporary file creation succeeds in app cache directory.
4. Handle camera app absence/failure and surface a user-friendly error.

---

## 🎨 UI/UX Issues (Jetpack Compose)

### Issue: Preview not rendering
**Error**: "Render Problem" in Design view

**Solution**:
1. Build & Refresh.
2. Check if Preview Composable has parameters (it shouldn't, or provide default values/`@PreviewParameter`).
3. Check for `ViewModel` usage in Preview (use mock/fake data instead).
4. Check for `Context` usage that might be invalid in preview.

### Issue: Recomposition loops
**Error**: UI lags or freezes

**Solution**:
1. Use Layout Inspector to check recomposition counts.
2. Ensure stable keys in `LazyColumn` (`items(key = { ... })`).
3. Avoid creating objects/lambdas inside Composable body (use `remember`).
4. Use `@Stable` or `@Immutable` annotations for state classes.

### Issue: Dark mode colors wrong
**Error**: Poor contrast

**Solution**:
1. Use `MaterialTheme.colorScheme` instead of hardcoded colors.
2. Define colors in `Theme.kt` for both `LightColorScheme` and `DarkColorScheme`.
3. Test with "Dark Theme" toggle in device settings.

---

## 🧪 Testing Issues

### Issue: Unit tests failing "Method not mocked"
**Error**: `java.lang.RuntimeException: Method ... not mocked`

**Solution**:
1. You are calling Android framework classes in a unit test.
2. Mock the dependency (using MockK).
3. Or use Robolectric if you really need Android context.
4. Or move the logic to a pure Kotlin class.

### Issue: "No answer found for: ..." (MockK)
**Error**: `MockKException`

**Solution**:
1. Ensure you stubbed the call: `coEvery { mock.method() } returns value`.
2. Or use `relaxed = true` in mock creation (use with caution).

### Issue: Instrumentation tests fail "No target device"
**Error**: No connected devices

**Solution**:
1. Start an emulator via AVD Manager.
2. Connect physical device via USB (enable USB Debugging).

---

## ⚡ Performance Issues

### Issue: Jank / Dropped frames
**Error**: UI stuttering

**Solution**:
1. Enable "Profile GPU Rendering" in Developer Options.
2. Use Android Profiler (CPU/Memory).
3. In Compose, ensure you are not doing heavy work in the main thread or during composition.
4. Use `LaunchedEffect` for side effects.

### Issue: Memory Leaks
**Error**: `OutOfMemoryError`

**Solution**:
1. Use Android Profiler -> Memory Dump.
2. Check for `Context` leaks (e.g., passing Activity context to singletons).
3. Cancel CoroutineScopes when ViewModel is cleared (automatic for `viewModelScope`).

---

## 📞 Getting More Help

### Resources
1. **Android Developers**: https://developer.android.com/
2. **Kotlin Docs**: https://kotlinlang.org/docs/home.html
3. **Jetpack Compose**: https://developer.android.com/jetpack/compose
4. **Stack Overflow**: Tag `android`, `kotlin`, `jetpack-compose`

### Debug Logging
Use Timber or standard Log class:
```kotlin
Log.d("Tag", "Debug message")
Log.e("Tag", "Error message", exception)
```
Filter by tag in Logcat.
