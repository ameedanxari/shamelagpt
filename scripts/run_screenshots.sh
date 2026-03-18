#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Unified Screenshot Runner
# ============================================================================
# Merges store and targeted screenshot generation for iOS + Android.
#
# Modes:
#   store    - full store/AppStore/PlayStore screenshots across all screens
#   targeted - focused validation by screen/locale/scenario/device
#
# Artifacts:
#   All outputs are written under <repo>/artifacts so they remain git-ignored.
#
# Usage:
#   ./run_screenshots.sh [--store|--targeted|--mode <store|targeted>] [OPTIONS]
# ============================================================================

# Track failures instead of exiting immediately
FAILED_TESTS=()
PASSED_COUNT=0

fail_soft() {
    echo "============================================" >&2
    echo "SOFT FAILURE: $1" >&2
    echo "============================================" >&2
    FAILED_TESTS+=("$1")
}

fail() {
    echo "============================================" >&2
    echo "CRITICAL ERROR: $1" >&2
    echo "Screenshot script did not complete." >&2
    echo "============================================" >&2

    # Capture debug info if available
    capture_debug_info

    exit 1
}

print_list_options() {
    echo "Available screens:"
    echo "  auth      - Authentication screens (login, signup, errors)"
    echo "  chat      - Chat screens (happy path, errors)"
    echo "  settings  - Settings screen"
    echo "  history   - History screen"
    echo "  welcome   - Welcome screen"
    echo ""
    echo "Available locales:"
    echo "  en        - English"
    echo "  ar        - Arabic"
    echo "  ur        - Urdu"
    echo ""
    echo "Available device types:"
    echo "  phone     - Phone devices"
    echo "  tablet    - Tablet devices"
    echo ""
    echo "Example scenarios:"
    echo "  auth_login"
    echo "  auth_signup"
    echo "  auth_error"
    echo "  chat_happy"
    echo "  chat_error"
    echo "  settings_main"
    echo "  history_list"
    echo "  welcome_main"
}

print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "MODE OPTIONS:"
    echo "  --store                  Run full store screenshots"
    echo "  --targeted               Run targeted screenshot validation"
    echo "  --mode <store|targeted>  Explicitly select mode"
    echo ""
    echo "PLATFORM OPTIONS:"
    echo "  --ios                    Run iOS screenshots only"
    echo "  --android                Run Android screenshots only"
    echo ""
    echo "TARGETED OPTIONS (targeted mode):"
    echo "  --screen <name>          Target specific screen"
    echo "  --locale <code>          Target specific locale"
    echo "  --scenario <pattern>     Target specific scenario pattern"
    echo "  --dark-only              Generate dark mode screenshots only"
    echo "  --device <type>          Target device type (phone, tablet)"
    echo ""
    echo "GENERAL OPTIONS:"
    echo "  --list-options           Show valid screen/locale/device/scenario options"
    echo "  --dry-run                Show what would be executed"
    echo "  --help                   Show this help message"
    echo ""
    echo "NOTES:"
    echo "  - Outputs are always written under: <repo>/artifacts"
    echo "  - Legacy positional artifacts path argument is ignored intentionally"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --store"
    echo "  $0 --store --ios"
    echo "  $0 --targeted --screen auth --android"
    echo "  $0 --targeted --screen chat --locale en --device phone"
    echo "  $0 --mode targeted --scenario auth_login --dark-only"
}

capture_debug_info() {
    local debug_dir="${ARTIFACTS_DIR:-./artifacts}/debug"
    mkdir -p "$debug_dir"

    echo "Capturing debug information to $debug_dir..."

    # iOS: Capture view hierarchy if simulator is running
    if command -v xcrun >/dev/null 2>&1; then
        local booted_sim
        booted_sim=$(xcrun simctl list devices booted -j 2>/dev/null | grep -o '"udid" : "[^"]*"' | head -1 | sed 's/"udid" : "\(.*\)"/\1/' || true)
        if [ -n "$booted_sim" ]; then
            echo "Capturing iOS simulator view hierarchy..."
            xcrun simctl io "$booted_sim" screenshot "$debug_dir/ios_failure_screenshot.png" 2>/dev/null || true
            if xcrun simctl ui "$booted_sim" help 2>&1 | grep -q "dump-hierarchy"; then
                xcrun simctl ui "$booted_sim" dump-hierarchy > "$debug_dir/ios_view_hierarchy.xml" 2>/dev/null || true
            fi
        fi
    fi
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACTS_DIR="$ROOT_DIR/artifacts"
LOCK_DIR=""

# Defaults
MODE=""
RUN_IOS=true
RUN_ANDROID=true
TARGET_SCREEN=""
TARGET_LOCALE=""
TARGET_SCENARIO=""
DARK_ONLY=false
TARGET_DEVICE=""
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --store)
            MODE="store"
            shift
            ;;
        --targeted)
            MODE="targeted"
            shift
            ;;
        --mode)
            if [[ $# -lt 2 ]]; then
                echo "Error: --mode requires a value: store|targeted"
                exit 1
            fi
            MODE="$2"
            shift 2
            ;;
        --ios)
            RUN_ANDROID=false
            shift
            ;;
        --android)
            RUN_IOS=false
            shift
            ;;
        --screen)
            if [[ $# -lt 2 ]]; then
                echo "Error: --screen requires a value"
                exit 1
            fi
            TARGET_SCREEN="$2"
            shift 2
            ;;
        --locale)
            if [[ $# -lt 2 ]]; then
                echo "Error: --locale requires a value"
                exit 1
            fi
            TARGET_LOCALE="$2"
            shift 2
            ;;
        --scenario)
            if [[ $# -lt 2 ]]; then
                echo "Error: --scenario requires a value"
                exit 1
            fi
            TARGET_SCENARIO="$2"
            shift 2
            ;;
        --dark-only)
            DARK_ONLY=true
            shift
            ;;
        --device)
            if [[ $# -lt 2 ]]; then
                echo "Error: --device requires a value"
                exit 1
            fi
            TARGET_DEVICE="$2"
            shift 2
            ;;
        --list-options)
            print_list_options
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            if [[ "$1" != -* ]]; then
                echo "Warning: Ignoring custom artifacts path '$1'. Using $ARTIFACTS_DIR to keep outputs git-ignored."
                shift
            else
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

# Auto mode selection (if not explicit)
if [[ -z "$MODE" ]]; then
    if [[ -n "$TARGET_SCREEN" || -n "$TARGET_LOCALE" || -n "$TARGET_SCENARIO" || "$DARK_ONLY" == true || -n "$TARGET_DEVICE" || "$DRY_RUN" == true ]]; then
        MODE="targeted"
    else
        MODE="store"
    fi
fi

# Validate mode
if [[ "$MODE" != "store" && "$MODE" != "targeted" ]]; then
    echo "Error: Invalid mode '$MODE'. Use --mode store or --mode targeted."
    exit 1
fi

# Validate platforms
if [[ "$RUN_IOS" == false && "$RUN_ANDROID" == false ]]; then
    echo "Error: At least one platform must be enabled (remove one of --ios/--android)."
    exit 1
fi

# Validate targeted values
if [[ -n "$TARGET_SCREEN" && "$TARGET_SCREEN" != "auth" && "$TARGET_SCREEN" != "chat" && "$TARGET_SCREEN" != "settings" && "$TARGET_SCREEN" != "history" && "$TARGET_SCREEN" != "welcome" ]]; then
    echo "Error: Invalid screen '$TARGET_SCREEN'. Use --list-options to see available screens."
    exit 1
fi

if [[ -n "$TARGET_LOCALE" && "$TARGET_LOCALE" != "en" && "$TARGET_LOCALE" != "ar" && "$TARGET_LOCALE" != "ur" ]]; then
    echo "Error: Invalid locale '$TARGET_LOCALE'. Use --list-options to see available locales."
    exit 1
fi

if [[ -n "$TARGET_DEVICE" && "$TARGET_DEVICE" != "phone" && "$TARGET_DEVICE" != "tablet" ]]; then
    echo "Error: Invalid device type '$TARGET_DEVICE'. Use --list-options to see available device types."
    exit 1
fi

# Guard against unsupported filters in store mode
if [[ "$MODE" == "store" ]]; then
    if [[ -n "$TARGET_SCREEN" || -n "$TARGET_LOCALE" || -n "$TARGET_SCENARIO" || "$DARK_ONLY" == true ]]; then
        echo "Error: --screen/--locale/--scenario/--dark-only require targeted mode."
        echo "Use: $0 --targeted ..."
        exit 1
    fi
fi

LOCK_DIR="${TMPDIR:-/tmp}/shamelagpt_${MODE}_screenshots.lock"

# Show configuration summary
echo "============================================"
echo "== Screenshot Configuration =="
echo "============================================"
echo "Mode: $MODE"
echo "Platforms: iOS=$RUN_IOS, Android=$RUN_ANDROID"
if [[ -n "$TARGET_DEVICE" ]]; then
    echo "Target Device: $TARGET_DEVICE"
fi
if [[ "$MODE" == "targeted" ]]; then
    if [[ -n "$TARGET_SCREEN" ]]; then
        echo "Target Screen: $TARGET_SCREEN"
    fi
    if [[ -n "$TARGET_LOCALE" ]]; then
        echo "Target Locale: $TARGET_LOCALE"
    fi
    if [[ -n "$TARGET_SCENARIO" ]]; then
        echo "Target Scenario: $TARGET_SCENARIO"
    fi
    if [[ "$DARK_ONLY" == true ]]; then
        echo "Dark Mode Only: Yes"
    fi
fi
echo "Artifacts Directory: $ARTIFACTS_DIR"
echo "Dry Run: $DRY_RUN"
echo "============================================"

# Acquire a simple cross-process lock (fail fast if another run is active)
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    fail "Another screenshot run is already active (lock: $LOCK_DIR)"
fi

cleanup_ios_simulators() {
    if command -v xcrun >/dev/null 2>&1; then
        local booted_count
        booted_count=$(xcrun simctl list devices booted 2>/dev/null | grep -c "(Booted)" || true)
        if [ "${booted_count:-0}" -gt 0 ]; then
            echo "Shutting down $booted_count booted iOS simulators..."
            xcrun simctl shutdown all 2>/dev/null || true
        fi
        killall Simulator 2>/dev/null || true

        local remaining
        remaining=$(xcrun simctl list devices booted 2>/dev/null | grep -c "(Booted)" || true)
        if [ "${remaining:-0}" -gt 0 ]; then
            echo "Warning: $remaining iOS simulators are still booted after cleanup."
        fi
    fi
}

cleanup_android_emulators() {
    # Attempt to find adb even if env vars were not exported yet.
    if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
        for cand in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "/opt/homebrew/share/android-sdk"; do
            [ -d "$cand" ] && export ANDROID_HOME="$cand" ANDROID_SDK_ROOT="$cand" && break
        done
    fi
    if [ -n "${ANDROID_HOME:-}" ]; then
        export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
    fi

    if command -v adb >/dev/null 2>&1; then
        local emulators
        emulators=$(adb devices 2>/dev/null | awk '/^emulator-/{print $1}' || true)
        if [ -n "$emulators" ]; then
            echo "Shutting down running Android emulators..."
            while IFS= read -r emu; do
                [ -n "$emu" ] && adb -s "$emu" emu kill 2>/dev/null || true
            done <<< "$emulators"
            sleep 2
        fi
    fi

    # Ensure no lingering emulator/qemu processes remain.
    pkill -f "emulator @" 2>/dev/null || true
    pkill -f "emulator64-crash-service" 2>/dev/null || true
    pkill -f "qemu-system" 2>/dev/null || true

    if command -v adb >/dev/null 2>&1; then
        local remaining_emulators
        remaining_emulators=$(adb devices 2>/dev/null | awk '/^emulator-/{print $1}' || true)
        if [ -n "$remaining_emulators" ]; then
            echo "Warning: Some Android emulators are still running: $remaining_emulators"
        fi
    fi
}

cleanup_all_devices() {
    if [ "$RUN_IOS" = true ]; then
        cleanup_ios_simulators
    fi
    if [ "$RUN_ANDROID" = true ]; then
        cleanup_android_emulators
    fi
}

cleanup_derived_data() {
    if [ -n "${DERIVED_DATA_BASE_DIR:-}" ] && [ -d "$DERIVED_DATA_BASE_DIR" ]; then
        rm -rf "$DERIVED_DATA_BASE_DIR" 2>/dev/null || true
    fi
}

echo "Ensuring clean simulator/emulator state before start..."
cleanup_all_devices
trap 'cleanup_all_devices; cleanup_derived_data; rm -rf "$LOCK_DIR"' EXIT

# Clean up artifacts directory before each run
echo "Cleaning up artifacts directory: $ARTIFACTS_DIR"
if [ -d "$ARTIFACTS_DIR" ]; then
    chmod -R 755 "$ARTIFACTS_DIR" 2>/dev/null || true
    rm -rf "$ARTIFACTS_DIR" 2>/dev/null || true
fi

mkdir -p "$ARTIFACTS_DIR/ios" "$ARTIFACTS_DIR/android" "$ARTIFACTS_DIR/debug"

# Unique derived data path for this run to avoid locks
DERIVED_DATA_BASE_DIR="$ARTIFACTS_DIR/derived_data/session_$(date +%s)"
mkdir -p "$DERIVED_DATA_BASE_DIR"

# ============================================================================
# iOS Configuration
# ============================================================================

IOS_CANDIDATE_IPHONE=("iPhone 16 Pro Max" "iPhone 16" "iPhone 15" "iPhone 14" "iPhone 16 Pro")
IOS_CANDIDATE_TABLET=("iPad Pro 13-inch (M5)" "iPad Pro 13-inch (M4)" "iPad Pro 12.9-inch (6th generation)")

pick_sim() {
    local name
    for name in "$@"; do
        if echo "${AVAILABLE_SIMS:-}" | grep -q "name:$name"; then
            echo "$name"
            return 0
        fi
    done
    echo "$1"
}

if [ "$RUN_IOS" = true ]; then
    echo "Discovering available iOS simulators..."
    if command -v xcodebuild >/dev/null 2>&1; then
        AVAILABLE_SIMS="$(xcodebuild -project "$ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj" -scheme ShamelaGPT -showdestinations 2>/dev/null || true)"
    else
        AVAILABLE_SIMS=""
        echo "Warning: xcodebuild not found. Skipping iOS screenshots."
    fi

    if [ -z "${IOS_DEVICES:-}" ]; then
        IOS_DEVICES=()

        local_want_phone=true
        local_want_tablet=true
        if [[ -n "$TARGET_DEVICE" ]]; then
            local_want_phone=false
            local_want_tablet=false
            [[ "$TARGET_DEVICE" == "phone" ]] && local_want_phone=true
            [[ "$TARGET_DEVICE" == "tablet" ]] && local_want_tablet=true
        fi

        if [[ "$local_want_phone" == true ]]; then
            IOS_DEVICES+=("$(pick_sim "${IOS_CANDIDATE_IPHONE[@]}")")
        fi
        if [[ "$local_want_tablet" == true ]]; then
            IOS_DEVICES+=("$(pick_sim "${IOS_CANDIDATE_TABLET[@]}")")
        fi
    else
        # Allow manual override if comma-separated string provided
        IFS=',' read -ra IOS_DEVICES_ARR <<< "$IOS_DEVICES"
        IOS_DEVICES=("${IOS_DEVICES_ARR[@]}")
    fi

    echo "Selected iOS devices: ${IOS_DEVICES[*]:-none}"
else
    AVAILABLE_SIMS=""
    IOS_DEVICES=()
fi

# ============================================================================
# Android Configuration
# ============================================================================

ANDROID_CANDIDATE_PHONE=("ShamelaGPT_Phone" "Pixel_9" "Pixel_8" "Pixel_6")
ANDROID_CANDIDATE_TABLET=("ShamelaGPT_Tablet" "Pixel_Tablet" "Nexus_10")
ANDROID_LOCALES=("en" "ar" "ur")

# ============================================================================
# iOS Store Screenshot Generation
# ============================================================================

run_ios_store_screenshots() {
    if [ -z "$AVAILABLE_SIMS" ]; then
        return 0
    fi

    echo "============================================"
    echo "== iOS Store Screenshots =="
    echo "============================================"

    for device in "${IOS_DEVICES[@]}"; do
        local device_name
        device_name=$(echo "$device" | cut -d',' -f1 | sed 's/name://')

        local device_id
        device_id=$(echo "${AVAILABLE_SIMS:-}" | grep "name:$device_name" | head -1 | grep -o 'id:[^,)]*' | cut -d':' -f2 || echo "$device_name")

        echo "--------------------------------------------"
        echo "Device: $device_name | All Store Scenarios"
        echo "--------------------------------------------"

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run iOS store screenshots for: $device_name"
            echo "[DRY RUN] Command: xcodebuild test -project $ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj -scheme ShamelaGPT -destination 'platform=iOS Simulator,id=$device_id' -only-testing:ShamelaGPTUITests/StoreScreenshotUITests"
            continue
        fi

        local dd_path="$DERIVED_DATA_BASE_DIR/${device_name// /_}"
        mkdir -p "$dd_path"

        local result_bundle="$ARTIFACTS_DIR/ios/${device_name// /_}.xcresult"
        rm -rf "$result_bundle" 2>/dev/null || true

        # Keep /tmp fallback cleanup for compatibility, but primary output is artifacts/ios.
        xcrun simctl spawn "$device_id" rm -rf "Documents/screenshots" 2>/dev/null || true
        rm -rf "/tmp/screenshots" 2>/dev/null || true
        mkdir -p "/tmp/screenshots"

        if ! env \
            SCREENSHOT_OUTPUT_DIR="$ARTIFACTS_DIR/ios" \
            SCREENSHOT_DEVICE="$device_name" \
            xcodebuild test \
                -project "$ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj" \
                -scheme ShamelaGPT \
                -destination "platform=iOS Simulator,id=$device_id" \
                -only-testing:ShamelaGPTUITests/StoreScreenshotUITests \
                -resultBundlePath "$result_bundle" \
                -derivedDataPath "$dd_path" \
                -parallel-testing-enabled NO \
                2>&1 | tee "$ARTIFACTS_DIR/debug/ios_store_${device_name// /_}.log"; then

            fail_soft "iOS StoreScreenshotUITests failed for $device_name"
        else
            ((PASSED_COUNT++))
        fi

        # Fallback move from /tmp/screenshots if tests still write there.
        if [ -d "/tmp/screenshots" ]; then
            mv -v /tmp/screenshots/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
        fi

        # Fallback: app containers
        for bid in "com.shamelagpt.ios" "com.shamelagpt.ios.shamelagptUITests.xctrunner" "com.shamelagpt.ios.ShamelaGPTUITests.xctrunner"; do
            local sim_data_dir
            sim_data_dir=$(xcrun simctl get_app_container "$device_id" "$bid" data 2>/dev/null || true)
            if [ -n "$sim_data_dir" ]; then
                local sim_screenshots="$sim_data_dir/Documents/screenshots"
                if [ -d "$sim_screenshots" ]; then
                    cp -v "$sim_screenshots"/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
                fi
            fi
        done
    done
}

# ============================================================================
# iOS Targeted Screenshot Generation
# ============================================================================

run_ios_targeted_screenshots() {
    if [ -z "$AVAILABLE_SIMS" ]; then
        return 0
    fi

    echo "============================================"
    echo "== iOS Targeted Screenshots =="
    echo "============================================"

    local ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests"
    local use_targeted_env=false

    if [[ -n "$TARGET_SCREEN" && -z "$TARGET_LOCALE" && -z "$TARGET_SCENARIO" && "$DARK_ONLY" == false ]]; then
        case "$TARGET_SCREEN" in
            auth)
                ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureAuthScreenshots"
                ;;
            chat)
                ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureChatScreenshots"
                ;;
            settings)
                ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureSettingsScreenshots"
                ;;
            history)
                ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureHistoryScreenshots"
                ;;
            welcome)
                ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureWelcomeScreenshots"
                ;;
        esac
    elif [[ -n "$TARGET_SCREEN" || -n "$TARGET_LOCALE" || -n "$TARGET_SCENARIO" || "$DARK_ONLY" == true ]]; then
        ios_only_testing="-only-testing:ShamelaGPTUITests/TargetedScreenshotUITests/test_captureTargetedScreenshots"
        use_targeted_env=true
    fi

    for device in "${IOS_DEVICES[@]}"; do
        local device_name
        device_name=$(echo "$device" | cut -d',' -f1 | sed 's/name://')

        local device_id
        device_id=$(echo "${AVAILABLE_SIMS:-}" | grep "name:$device_name" | head -1 | grep -o 'id:[^,)]*' | cut -d':' -f2 || echo "$device_name")

        echo "--------------------------------------------"
        echo "Device: $device_name | Target: ${TARGET_SCREEN:-all}"
        echo "--------------------------------------------"

        local -a xcode_env
        xcode_env=(
            "SCREENSHOT_OUTPUT_DIR=$ARTIFACTS_DIR/ios"
            "SCREENSHOT_DEVICE=$device_name"
        )

        if [[ "$use_targeted_env" == true ]]; then
            [[ -n "$TARGET_SCREEN" ]] && xcode_env+=("TARGET_SCREEN=$TARGET_SCREEN")
            [[ -n "$TARGET_LOCALE" ]] && xcode_env+=("TARGET_LOCALE=$TARGET_LOCALE")
            [[ -n "$TARGET_SCENARIO" ]] && xcode_env+=("TARGET_SCENARIO=$TARGET_SCENARIO")
            [[ "$DARK_ONLY" == true ]] && xcode_env+=("DARK_MODE=true")
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run iOS targeted screenshots for: $device_name"
            echo "[DRY RUN] Env: ${xcode_env[*]}"
            echo "[DRY RUN] Command: xcodebuild test -project $ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj -scheme ShamelaGPT -destination 'platform=iOS Simulator,id=$device_id' $ios_only_testing"
            continue
        fi

        local dd_path="$DERIVED_DATA_BASE_DIR/${device_name// /_}"
        mkdir -p "$dd_path"

        local result_bundle="$ARTIFACTS_DIR/ios/${device_name// /_}.xcresult"
        rm -rf "$result_bundle" 2>/dev/null || true

        xcrun simctl spawn "$device_id" rm -rf "Documents/screenshots" 2>/dev/null || true
        rm -rf "/tmp/screenshots" 2>/dev/null || true
        mkdir -p "/tmp/screenshots"

        if ! env "${xcode_env[@]}" xcodebuild test \
            -project "$ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj" \
            -scheme ShamelaGPT \
            -destination "platform=iOS Simulator,id=$device_id" \
            "$ios_only_testing" \
            -resultBundlePath "$result_bundle" \
            -derivedDataPath "$dd_path" \
            -parallel-testing-enabled NO \
            2>&1 | tee "$ARTIFACTS_DIR/debug/ios_targeted_${device_name// /_}.log"; then

            fail_soft "iOS TargetedScreenshotUITests failed for $device_name"
        else
            ((PASSED_COUNT++))
        fi

        # Fallback move from /tmp/screenshots if tests still write there.
        if [ -d "/tmp/screenshots" ]; then
            mv -v /tmp/screenshots/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
        fi

        # Fallback: app containers
        for bid in "com.shamelagpt.ios" "com.shamelagpt.ios.shamelagptUITests.xctrunner" "com.shamelagpt.ios.ShamelaGPTUITests.xctrunner"; do
            local sim_data_dir
            sim_data_dir=$(xcrun simctl get_app_container "$device_id" "$bid" data 2>/dev/null || true)
            if [ -n "$sim_data_dir" ]; then
                local sim_screenshots="$sim_data_dir/Documents/screenshots"
                if [ -d "$sim_screenshots" ]; then
                    cp -v "$sim_screenshots"/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
                fi
            fi
        done
    done
}

# ============================================================================
# Android Shared Helpers
# ============================================================================

setup_android_environment() {
    # Resolve Android SDK root from common install paths if env vars are missing.
    if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ]; then
        local candidates=(
            "$HOME/Library/Android/sdk"
            "$HOME/Android/Sdk"
            "/usr/local/share/android-sdk"
            "/opt/android-sdk"
            "/opt/homebrew/share/android-sdk"
        )
        for cand in "${candidates[@]}"; do
            if [ -d "$cand" ]; then
                export ANDROID_HOME="$cand"
                export ANDROID_SDK_ROOT="$cand"
                break
            fi
        done
    else
        # Keep both vars aligned for tools that prefer one or the other.
        export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"
        export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    fi

    if [ -n "${ANDROID_HOME:-}" ]; then
        export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    fi

    if ! command -v adb >/dev/null 2>&1; then
        echo "Warning: Android SDK not found (adb missing). Skipping Android screenshots."
        return 1
    fi
    return 0
}

find_or_create_avd() {
    local avd_name="$1"
    local device_type="$2"

    # Decide arch
    local abi="arm64-v8a"
    if [ "$(uname -m)" = "x86_64" ]; then abi="x86_64"; fi

    local image=""
    local image_candidates=(
        "system-images;android-36;google_apis;$abi"
        "system-images;android-35;google_apis;$abi"
        "system-images;android-34;google_apis;$abi"
    )

    # Prefer already-installed highest API image first.
    for candidate in "${image_candidates[@]}"; do
        if sdkmanager --list_installed 2>/dev/null | grep -q "$candidate"; then
            image="$candidate"
            break
        fi
    done

    # If none are installed, try to install from highest to lowest.
    if [ -z "$image" ]; then
        for candidate in "${image_candidates[@]}"; do
            echo "Installing system image $candidate..." >&2
            if echo "y" | sdkmanager "$candidate" >/dev/null 2>&1; then
                image="$candidate"
                break
            fi
        done
    fi

    if [ -z "$image" ]; then
        echo "Failed to find/install a supported Android system image (36/35/34)." >&2
        return 1
    fi

    if [ "$image" != "${image_candidates[0]}" ]; then
        echo "Warning: Android 36 image unavailable; falling back to $image" >&2
    fi

    local desired_sysdir="${image//;/\/}/"

    # If AVD exists, ensure it targets the selected image. Recreate when outdated.
    if emulator -list-avds 2>/dev/null | grep -q "^${avd_name}$"; then
        local avd_config="$HOME/.android/avd/${avd_name}.avd/config.ini"
        local current_sysdir=""
        if [ -f "$avd_config" ]; then
            current_sysdir="$(awk -F'=' '/^image.sysdir.1/ {gsub(/^ +| +$/, "", $2); print $2; exit}' "$avd_config")"
        fi
        if [ -n "$current_sysdir" ] && [ "$current_sysdir" = "$desired_sysdir" ]; then
            echo "$avd_name"
            return 0
        fi

        echo "Recreating AVD $avd_name to use $image (current: ${current_sysdir:-unknown})..." >&2
        rm -rf "$HOME/.android/avd/${avd_name}.avd" "$HOME/.android/avd/${avd_name}.ini" 2>/dev/null || true
    else
        echo "AVD $avd_name not found. Attempting to create..." >&2
    fi

    local profile="pixel_6"
    if [ "$device_type" = "tablet" ]; then profile="pixel_tablet"; fi

    echo "Creating AVD $avd_name with $image..." >&2
    echo "no" | avdmanager create avd -n "$avd_name" -k "$image" -d "$profile" --force >/dev/null || return 1
    echo "$avd_name"
}

launch_android_emulator() {
    local name="$1"
    echo "Launching emulator $name..."
    adb emu kill 2>/dev/null || true
    sleep 2

    local safe_name="${name//[^A-Za-z0-9._-]/_}"
    emulator @"$name" -no-audio -no-boot-anim -no-window -gpu swiftshader_indirect -no-snapshot -wipe-data >"/tmp/emulator_${safe_name}.log" 2>&1 &
    local emulator_pid=$!
    local serial=""
    local stable_ready_count=0

    # Wait for boot
    local waited=0
    while [ $waited -lt 480 ]; do
        if [ -z "$serial" ]; then
            serial=$(adb devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]+device$/{print $1; exit}')
        fi
        if [ -n "$serial" ]; then
            local boot_completed sdk_level
            boot_completed="$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
            sdk_level="$(adb -s "$serial" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')"

            if [[ "$boot_completed" == "1" ]] && [[ "$sdk_level" =~ ^[0-9]+$ ]] && [ "$sdk_level" -ge 21 ] \
                && adb -s "$serial" shell cmd package list packages >/dev/null 2>&1; then
                stable_ready_count=$((stable_ready_count + 1))
            else
                stable_ready_count=0
            fi

            # Require two consecutive healthy checks to avoid startup races.
            if [ "$stable_ready_count" -ge 2 ]; then
                export ANDROID_SERIAL="$serial"
                echo "Emulator $name ready on $serial (API $sdk_level)."
                return 0
            fi
        fi
        sleep 5
        waited=$((waited + 5))
    done

    echo "Emulator $name did not boot within timeout; killing pid $emulator_pid" >&2
    kill -9 "$emulator_pid" 2>/dev/null || true
    return 1
}

run_android_gradle_with_timeout() {
    local timeout_secs="$1"
    shift
    local command="$*"
    local elapsed=0

    bash -o pipefail -lc "$command" &
    local cmd_pid=$!

    while kill -0 "$cmd_pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout_secs" ]; then
            echo "Gradle command timed out after ${timeout_secs}s. Terminating PID $cmd_pid..." >&2
            kill -TERM "$cmd_pid" 2>/dev/null || true
            sleep 5
            kill -KILL "$cmd_pid" 2>/dev/null || true
            wait "$cmd_pid" 2>/dev/null || true
            return 124
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    wait "$cmd_pid"
}

adb_cmd() {
    if [ -n "${ANDROID_SERIAL:-}" ]; then
        adb -s "$ANDROID_SERIAL" "$@"
    else
        adb "$@"
    fi
}

ensure_android_target_isolated() {
    local target="${ANDROID_SERIAL:-}"
    if [ -z "$target" ]; then
        # Default to the first booted emulator if caller did not set ANDROID_SERIAL.
        target="$(adb devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]+device$/{print $1; exit}')"
        [ -n "$target" ] && export ANDROID_SERIAL="$target"
    fi

    # Best-effort disconnect of remote/tcp devices to avoid Gradle selecting them.
    while IFS= read -r serial; do
        [ -z "$serial" ] && continue
        [ "$serial" = "${ANDROID_SERIAL:-}" ] && continue
        if [[ "$serial" == *._adb-tls-connect._tcp || "$serial" == *:* ]]; then
            adb disconnect "$serial" >/dev/null 2>&1 || true
        fi
    done < <(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')

    local connected
    connected="$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1}')"
    local count
    count="$(printf "%s\n" "$connected" | awk 'NF{c++} END{print c+0}')"
    if [ "$count" -gt 1 ]; then
        echo "Connected Android devices:" >&2
        printf "%s\n" "$connected" >&2
        return 1
    fi
    return 0
}

# ============================================================================
# Android Store Screenshot Generation
# ============================================================================

run_android_store_screenshots() {
    if ! setup_android_environment; then return 0; fi

    echo "============================================"
    echo "== Android Store Screenshots =="
    echo "============================================"

    cd "$ROOT_DIR/shamelagpt-android"

    local store_class="com.shamelagpt.android.screenshots.StoreScreenshotTest"

    local devices=()
    if [[ -n "$TARGET_DEVICE" ]]; then
        devices=("$TARGET_DEVICE")
    else
        devices=("phone" "tablet")
    fi

    local android_test_timeout_secs="${ANDROID_TEST_TIMEOUT_SECS:-900}"
    for type in "${devices[@]}"; do
        local candidates=()
        if [ "$type" == "phone" ]; then
            candidates=("${ANDROID_CANDIDATE_PHONE[@]}")
        else
            candidates=("${ANDROID_CANDIDATE_TABLET[@]}")
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run Android store screenshots for: $type"
            for locale in "${ANDROID_LOCALES[@]}"; do
                echo "[DRY RUN] Command: ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=$store_class -Pandroid.testInstrumentationRunnerArguments.locale=$locale"
            done
            continue
        fi

        local avd=""
        for cand in "${candidates[@]}"; do
            avd=$(find_or_create_avd "$cand" "$type" | tail -n 1) || true
            if [ -n "$avd" ] && [[ ! "$avd" == *"not found"* ]]; then break; fi
        done

        [ -z "$avd" ] && {
            fail_soft "Could not find/create Android $type emulator"
            continue
        }

        if ! launch_android_emulator "$avd"; then
            echo "Recreating AVD $avd due to boot failure..." >&2
            rm -rf "$HOME/.android/avd/${avd}.avd" "$HOME/.android/avd/${avd}.ini" 2>/dev/null || true
            avd=$(find_or_create_avd "$avd" "$type" | tail -n 1) || true
            if [ -z "$avd" ]; then
                fail_soft "Could not recreate Android $type emulator"
                continue
            fi
            launch_android_emulator "$avd" || {
                fail_soft "Failed to launch $avd"
                continue
            }
        fi

        # launch_android_emulator exports ANDROID_SERIAL for the launched device.
        if ! ensure_android_target_isolated; then
            fail_soft "Android device isolation failed (more than one connected device). Disconnect external devices and retry."
            adb emu kill 2>/dev/null || true
            continue
        fi

        for locale in "${ANDROID_LOCALES[@]}"; do
            echo "Generating Android $type store screenshots for locale: $locale"

            if ! ensure_android_target_isolated; then
                fail_soft "Android device isolation failed before locale $locale"
                continue
            fi

            local gradle_log="$ARTIFACTS_DIR/debug/android_store_${type}_${locale}.log"
            local gradle_cmd="cd '$ROOT_DIR/shamelagpt-android' && ANDROID_SERIAL='$ANDROID_SERIAL' ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=$store_class -Pandroid.testInstrumentationRunnerArguments.locale=$locale --info 2>&1 | tee '$gradle_log'"

            if ! run_android_gradle_with_timeout "$android_test_timeout_secs" "$gradle_cmd"; then
                fail_soft "Android $type store tests failed for locale=$locale"
            else
                ((PASSED_COUNT++))
            fi

            # Pull screenshots
            local out_dir="$ARTIFACTS_DIR/android/$type/$locale"
            mkdir -p "$out_dir"
            local connected_out="$ROOT_DIR/shamelagpt-android/app/build/outputs/connected_android_test_additional_output/debugAndroidTest/connected"
            if [ -d "$connected_out" ]; then
                # Find locale folder under screenshots (device subfolder is dynamic)
                local locale_path
                locale_path=$(find "$connected_out" -type d -path "*/screenshots/*/$locale" | head -1)
                if [ -n "$locale_path" ] && [ -d "$locale_path" ]; then
                    find "$locale_path" -type f -name '*.png' -print -exec cp "{}" "$out_dir/" \;
                fi
            fi

            # Fallback pulls directly from device external storage
            adb_cmd pull "/sdcard/Android/media/com.shamelagpt.android/additional_test_output/screenshots" "$out_dir/" 2>/dev/null || true
            adb_cmd pull "/sdcard/Android/data/com.shamelagpt.android/files/screenshots" "$out_dir/" 2>/dev/null || true

            # Clear intermediate output to avoid cross-locale bleed
            rm -rf "$connected_out" 2>/dev/null || true
        done

        adb_cmd emu kill 2>/dev/null || true
    done
}

# ============================================================================
# Android Targeted Screenshot Generation
# ============================================================================

run_android_targeted_screenshots() {
    if ! setup_android_environment; then return 0; fi

    echo "============================================"
    echo "== Android Targeted Screenshots =="
    echo "============================================"

    cd "$ROOT_DIR/shamelagpt-android"

    local test_class="com.shamelagpt.android.screenshots.TargetedScreenshotTest"
    local test_method="captureTargetedScreenshots"

    if [[ -n "$TARGET_SCREEN" && -z "$TARGET_LOCALE" && -z "$TARGET_SCENARIO" && "$DARK_ONLY" == false ]]; then
        case "$TARGET_SCREEN" in
            auth)
                test_method="captureAuthScreenshots"
                ;;
            chat)
                test_method="captureChatScreenshots"
                ;;
            settings)
                test_method="captureSettingsScreenshots"
                ;;
            history)
                test_method="captureHistoryScreenshots"
                ;;
            welcome)
                test_method="captureWelcomeScreenshots"
                ;;
        esac
    fi

    local devices=()
    if [[ -n "$TARGET_DEVICE" ]]; then
        devices=("$TARGET_DEVICE")
    else
        devices=("phone" "tablet")
    fi

    local locales=()
    if [[ -n "$TARGET_LOCALE" ]]; then
        locales=("$TARGET_LOCALE")
    else
        # Run once and let the test class iterate its full locale matrix.
        locales=("all")
    fi

    local android_test_timeout_secs="${ANDROID_TEST_TIMEOUT_SECS:-900}"
    for type in "${devices[@]}"; do
        local candidates=()
        if [ "$type" == "phone" ]; then
            candidates=("${ANDROID_CANDIDATE_PHONE[@]}")
        else
            candidates=("${ANDROID_CANDIDATE_TABLET[@]}")
        fi

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would run Android targeted screenshots for: $type"
            for locale in "${locales[@]}"; do
                local dry_gradle_args="-Pandroid.testInstrumentationRunnerArguments.class=$test_class -Pandroid.testInstrumentationRunnerArguments.method=$test_method"
                if [[ "$locale" != "all" ]]; then
                    dry_gradle_args="$dry_gradle_args -Pandroid.testInstrumentationRunnerArguments.locale=$locale"
                fi
                if [[ -n "$TARGET_SCENARIO" ]]; then
                    dry_gradle_args="$dry_gradle_args -Pandroid.testInstrumentationRunnerArguments.scenario=$TARGET_SCENARIO"
                fi
                if [[ "$DARK_ONLY" == true ]]; then
                    dry_gradle_args="$dry_gradle_args -Pandroid.testInstrumentationRunnerArguments.darkMode=true"
                fi
                echo "[DRY RUN] Command: ./gradlew :app:connectedDebugAndroidTest $dry_gradle_args"
            done
            continue
        fi

        local avd=""
        for cand in "${candidates[@]}"; do
            avd=$(find_or_create_avd "$cand" "$type" | tail -n 1) || true
            if [ -n "$avd" ] && [[ ! "$avd" == *"not found"* ]]; then break; fi
        done

        [ -z "$avd" ] && {
            fail_soft "Could not find/create Android $type emulator"
            continue
        }

        if ! launch_android_emulator "$avd"; then
            echo "Recreating AVD $avd due to boot failure..." >&2
            rm -rf "$HOME/.android/avd/${avd}.avd" "$HOME/.android/avd/${avd}.ini" 2>/dev/null || true
            avd=$(find_or_create_avd "$avd" "$type" | tail -n 1) || true
            if [ -z "$avd" ]; then
                fail_soft "Could not recreate Android $type emulator"
                continue
            fi
            launch_android_emulator "$avd" || {
                fail_soft "Failed to launch $avd"
                continue
            }
        fi

        # launch_android_emulator exports ANDROID_SERIAL for the launched device.
        if ! ensure_android_target_isolated; then
            fail_soft "Android device isolation failed (more than one connected device). Disconnect external devices and retry."
            adb emu kill 2>/dev/null || true
            continue
        fi

        for locale in "${locales[@]}"; do
            local locale_label="$locale"
            echo "Generating Android $type targeted screenshots for locale: $locale_label"

            if ! ensure_android_target_isolated; then
                fail_soft "Android device isolation failed before locale $locale_label"
                continue
            fi

            local gradle_args="-Pandroid.testInstrumentationRunnerArguments.class=$test_class"
            gradle_args="$gradle_args -Pandroid.testInstrumentationRunnerArguments.method=$test_method"

            if [[ "$locale" != "all" ]]; then
                gradle_args="$gradle_args -Pandroid.testInstrumentationRunnerArguments.locale=$locale"
            fi

            if [[ -n "$TARGET_SCENARIO" ]]; then
                gradle_args="$gradle_args -Pandroid.testInstrumentationRunnerArguments.scenario=$TARGET_SCENARIO"
            fi

            if [[ "$DARK_ONLY" == true ]]; then
                gradle_args="$gradle_args -Pandroid.testInstrumentationRunnerArguments.darkMode=true"
            fi

            local gradle_log="$ARTIFACTS_DIR/debug/android_targeted_${type}_${locale_label}.log"
            local gradle_cmd="cd '$ROOT_DIR/shamelagpt-android' && ANDROID_SERIAL='$ANDROID_SERIAL' ./gradlew :app:connectedDebugAndroidTest $gradle_args --info 2>&1 | tee '$gradle_log'"

            if ! run_android_gradle_with_timeout "$android_test_timeout_secs" "$gradle_cmd"; then
                fail_soft "Android $type targeted tests failed for locale=$locale_label"
            else
                ((PASSED_COUNT++))
            fi

            local out_dir="$ARTIFACTS_DIR/android/$type"
            if [[ "$locale" != "all" ]]; then
                out_dir="$ARTIFACTS_DIR/android/$type/$locale"
            fi
            mkdir -p "$out_dir"

            local connected_out="$ROOT_DIR/shamelagpt-android/app/build/outputs/connected_android_test_additional_output/debugAndroidTest/connected"
            if [ -d "$connected_out" ]; then
                if [[ "$locale" == "all" ]]; then
                    find "$connected_out" -type f -name '*.png' -print -exec cp "{}" "$out_dir/" \;
                else
                    local locale_path
                    locale_path=$(find "$connected_out" -type d -path "*/screenshots/*/$locale" | head -1)
                    if [ -n "$locale_path" ] && [ -d "$locale_path" ]; then
                        find "$locale_path" -type f -name '*.png' -print -exec cp "{}" "$out_dir/" \;
                    fi
                fi
            fi

            adb_cmd pull "/sdcard/Android/media/com.shamelagpt.android/additional_test_output/screenshots" "$out_dir/" 2>/dev/null || true
            adb_cmd pull "/sdcard/Android/data/com.shamelagpt.android/files/screenshots" "$out_dir/" 2>/dev/null || true

            rm -rf "$connected_out" 2>/dev/null || true
        done

        adb_cmd emu kill 2>/dev/null || true
    done
}

# ============================================================================
# Visual QC (Contact Sheets + Summary)
# ============================================================================

run_visual_qc() {
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    echo "============================================"
    echo "== Visual QC =="
    echo "============================================"

    if ! command -v python3 >/dev/null 2>&1; then
        fail_soft "Visual QC skipped: python3 not found"
        return 0
    fi

    local qc_log="$ARTIFACTS_DIR/debug/visual_qc.log"
    local qc_out="$ARTIFACTS_DIR/visual_qc"
    mkdir -p "$qc_out"

    if python3 "$ROOT_DIR/scripts/visual_qc.py" \
        --artifacts "$ARTIFACTS_DIR" \
        --out "$qc_out" \
        2>&1 | tee "$qc_log"; then
        ((PASSED_COUNT++))
    else
        local rc=$?
        if [ "$rc" -eq 2 ]; then
            fail_soft "Visual QC detected screenshot issues"
        else
            fail_soft "Visual QC stage failed"
        fi
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

if [ "$MODE" = "store" ]; then
    [ "$RUN_IOS" = true ] && run_ios_store_screenshots
    [ "$RUN_ANDROID" = true ] && run_android_store_screenshots
else
    [ "$RUN_IOS" = true ] && run_ios_targeted_screenshots
    [ "$RUN_ANDROID" = true ] && run_android_targeted_screenshots
fi

run_visual_qc

# ============================================================================
# Summary Report
# ============================================================================

echo ""
echo "============================================"
if [ "$MODE" = "store" ]; then
    echo "== Store Screenshot Generation Summary =="
else
    echo "== Targeted Screenshot Generation Summary =="
fi
echo "============================================"
echo "Completed at: $(date)"
echo "Total successful test sets: $PASSED_COUNT"
echo "Log files: $ARTIFACTS_DIR/debug/"
echo "Screenshots: $ARTIFACTS_DIR/"

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo "--------------------------------------------"
    echo "FAILED CATEGORIES (${#FAILED_TESTS[@]}):"
    for f in "${FAILED_TESTS[@]}"; do
        echo " - $f"
    done
    echo "--------------------------------------------"
    exit 1
else
    echo "--------------------------------------------"
    if [ "$MODE" = "store" ]; then
        echo "SUCCESS: All store screenshot sets completed!"
    else
        echo "SUCCESS: All targeted screenshot sets completed!"
    fi
    echo "--------------------------------------------"
    exit 0
fi
