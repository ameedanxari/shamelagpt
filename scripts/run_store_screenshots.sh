#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Store Screenshots Script
# ============================================================================
# Captures screenshots for App Store / Play Store across all screens, locales,
# and device form factors (phones and tablets) for iOS and Android.
#
# Usage: ./run_store_screenshots.sh [--ios|--android] [artifacts_dir]
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
    echo "Store screenshots script did not complete." >&2
    echo "============================================" >&2
    
    # Capture debug info if available
    capture_debug_info
    
    exit 1
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
LOCK_DIR="${TMPDIR:-/tmp}/shamelagpt_store_screenshots.lock"

# Handle flags and optional artifacts dir
RUN_IOS=true
RUN_ANDROID=true

for arg in "$@"; do
    if [[ "$arg" == "--ios" ]]; then
        RUN_ANDROID=false
    elif [[ "$arg" == "--android" ]]; then
        RUN_IOS=false
    elif [[ "$arg" != -* ]]; then
        # If it doesn't start with a dash, it's the artifacts directory
        ARTIFACTS_DIR="$arg"
    fi
done

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
    [ "$RUN_IOS" = true ] && cleanup_ios_simulators
    [ "$RUN_ANDROID" = true ] && cleanup_android_emulators
}

cleanup_derived_data() {
    if [ -n "${DERIVED_DATA_BASE_DIR:-}" ] && [ -d "$DERIVED_DATA_BASE_DIR" ]; then
        rm -rf "$DERIVED_DATA_BASE_DIR" 2>/dev/null || true
    fi
}

# Acquire a simple cross-process lock (fail fast if another run is active).
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    fail "Another run_store_screenshots.sh instance is already running (lock: $LOCK_DIR)"
fi

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

# Unique derived data path for this run to avoid locks; keep under artifacts so it’s auto-cleaned on next run
DERIVED_DATA_BASE_DIR="$ARTIFACTS_DIR/derived_data/session_$(date +%s)"
mkdir -p "$DERIVED_DATA_BASE_DIR"

# ============================================================================
# iOS Configuration
# ============================================================================

# Reduced Workload: Pick exactly 1 iPhone and 1 iPad for efficiency
IOS_CANDIDATE_IPHONE=("iPhone 16 Pro Max" "iPhone 16" "iPhone 15" "iPhone 14" "iPhone 16 Pro")
IOS_CANDIDATE_TABLET=("iPad Pro 13-inch (M5)" "iPad Pro 13-inch (M4)" "iPad Pro 12.9-inch (6th generation)")
if [ -z "${IOS_LOCALES:-}" ]; then
    IOS_LOCALES=("en_US" "ar_SA" "ur_PK")
else
    IFS=',' read -ra IOS_LOCALES_ARR <<< "$IOS_LOCALES"
    IOS_LOCALES=("${IOS_LOCALES_ARR[@]}")
fi

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
        IOS_DEVICES+=("$(pick_sim "${IOS_CANDIDATE_IPHONE[@]}")")
        IOS_DEVICES+=("$(pick_sim "${IOS_CANDIDATE_TABLET[@]}")")
    else
        # Allow manual override if comma-separated string provided
        IFS=',' read -ra IOS_DEVICES_ARR <<< "$IOS_DEVICES"
        IOS_DEVICES=("${IOS_DEVICES_ARR[@]}")
    fi

    echo "Selected iOS devices: ${IOS_DEVICES[*]}"
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
# iOS Screenshot Generation
# ============================================================================

run_ios_screenshots() {
    if [ -z "$AVAILABLE_SIMS" ]; then
        return 0
    fi
    
    echo "============================================"
    echo "== iOS Screenshots =="
    echo "============================================"
    
    for device in "${IOS_DEVICES[@]}"; do
        # Extract name without ID if present
        local device_name
        device_name=$(echo "$device" | cut -d',' -f1 | sed 's/name://')
        
        # Get UDID for faster targeting
        local device_id
        device_id=$(echo "${AVAILABLE_SIMS:-}" | grep "name:$device_name" | head -1 | grep -o 'id:[^,)]*' | cut -d':' -f2 || echo "$device_name")
        
        # No more locale loop here! The LocalizedUITestCase handles en, ar, ur internally.
        echo "--------------------------------------------"
        echo "Device: $device_name | All Locales (en, ar, ur)"
        echo "--------------------------------------------"
        
        # Derived data lives inside the run-scoped session dir for easy cleanup
        local dd_path="$DERIVED_DATA_BASE_DIR/${device_name// /_}"
        mkdir -p "$dd_path"
        
        # RUN ALL TESTS IN ONE CLASS CALL
        local result_bundle="$ARTIFACTS_DIR/ios/${device_name// /_}.xcresult"
        rm -rf "$result_bundle" 2>/dev/null || true
        
        # Clean up old screenshots in simulator and temp dir
        xcrun simctl spawn "$device_id" rm -rf "Documents/screenshots" 2>/dev/null || true
        rm -rf "/tmp/screenshots" 2>/dev/null || true
        mkdir -p "/tmp/screenshots"
        
        if ! xcodebuild test \
            -project "$ROOT_DIR/shamelagpt-ios/ShamelaGPT.xcodeproj" \
            -scheme ShamelaGPT \
            -destination "platform=iOS Simulator,id=$device_id" \
            -only-testing:ShamelaGPTUITests/StoreScreenshotUITests \
            -resultBundlePath "$result_bundle" \
            -derivedDataPath "$dd_path" \
            -parallel-testing-enabled NO \
            2>&1 | tee "$ARTIFACTS_DIR/debug/ios_${device_name// /_}.log"; then
            
            fail_soft "iOS Class StoreScreenshotUITests failed for $device_name"
        else
            ((PASSED_COUNT++))
        fi
        
        # Pull screenshots from /tmp/screenshots (where the tests save them internally)
        if [ -d "/tmp/screenshots" ]; then
            echo "Moving screenshots from /tmp/screenshots to $ARTIFACTS_DIR/ios/..."
            mv -v /tmp/screenshots/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
        fi
        
        # Still check app containers just in case of any fallback saving
        for bid in "com.shamelagpt.ios" "com.shamelagpt.ios.shamelagptUITests.xctrunner" "com.shamelagpt.ios.ShamelaGPTUITests.xctrunner"; do
            local sim_data_dir
            sim_data_dir=$(xcrun simctl get_app_container "$device_id" "$bid" data 2>/dev/null || true)
            if [ -n "$sim_data_dir" ]; then
                local sim_screenshots="$sim_data_dir/Documents/screenshots"
                if [ -d "$sim_screenshots" ]; then
                    echo "Pulling screenshots from $bid container..."
                    cp -v "$sim_screenshots"/*.png "$ARTIFACTS_DIR/ios/" 2>/dev/null || true
                fi
            fi
        done
    done
}

# ============================================================================
# Android Screenshot Generation
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
    
    # Check if exists
    if emulator -list-avds 2>/dev/null | grep -q "^${avd_name}$"; then
        echo "$avd_name"
        return 0
    fi
    
    echo "AVD $avd_name not found. Attempting to create..." >&2
    
    # Decide arch
    local abi="arm64-v8a"
    if [ "$(uname -m)" = "x86_64" ]; then abi="x86_64"; fi
    
    local image="system-images;android-34;google_apis;$abi"
    
    # Try to install image if missing
    if ! (sdkmanager --list_installed 2>/dev/null | grep -q "$image"); then
        echo "Installing system image $image..." >&2
        echo "y" | sdkmanager "$image" >/dev/null 2>&1 || return 1
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

    # Wait for boot
    local waited=0
    while [ $waited -lt 480 ]; do
        if [ -z "$serial" ]; then
            serial=$(adb devices 2>/dev/null | awk '/^emulator-[0-9]+[[:space:]]+device$/{print $1; exit}')
        fi
        if [ -n "$serial" ] && adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q "^1$"; then
            export ANDROID_SERIAL="$serial"
            echo "Emulator $name ready on $serial."
            return 0
        fi
        sleep 5
        waited=$((waited+5))
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
        elapsed=$((elapsed+5))
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

run_android_screenshots() {
    if ! setup_android_environment; then return 0; fi
    
    echo "============================================"
    echo "== Android Screenshots =="
    echo "============================================"
    
    cd "$ROOT_DIR/shamelagpt-android"
    
    # Run for Phone, then Tablet
    local devices=("phone" "tablet")
    local android_test_timeout_secs="${ANDROID_TEST_TIMEOUT_SECS:-900}"
    for type in "${devices[@]}"; do
        local candidates=()
        if [ "$type" == "phone" ]; then candidates=("${ANDROID_CANDIDATE_PHONE[@]}"); else candidates=("${ANDROID_CANDIDATE_TABLET[@]}"); fi
        
        local avd=""
        for cand in "${candidates[@]}"; do
            avd=$(find_or_create_avd "$cand" "$type" | tail -n 1) || true
            if [ -n "$avd" ] && [[ ! "$avd" == *"not found"* ]]; then break; fi
        done
        
        [ -z "$avd" ] && { fail_soft "Could not find/create Android $type emulator"; continue; }
        
        if ! launch_android_emulator "$avd"; then
            echo "Recreating AVD $avd due to boot failure..." >&2
            rm -rf "$HOME/.android/avd/${avd}.avd" "$HOME/.android/avd/${avd}.ini" 2>/dev/null || true
            avd=$(find_or_create_avd "$avd" "$type" | tail -n 1) || true
            if [ -z "$avd" ]; then
                fail_soft "Could not recreate Android $type emulator"
                continue
            fi
            launch_android_emulator "$avd" || { fail_soft "Failed to launch $avd"; continue; }
        fi

        # launch_android_emulator exports ANDROID_SERIAL for the launched device.
        if ! ensure_android_target_isolated; then
            fail_soft "Android device isolation failed (more than one connected device). Disconnect external devices and retry."
            adb emu kill 2>/dev/null || true
            continue
        fi
        
        for locale in "${ANDROID_LOCALES[@]}"; do
            echo "Generating Android $type screenshots for locale: $locale"
            
            if ! ensure_android_target_isolated; then
                fail_soft "Android device isolation failed before locale $locale"
                continue
            fi

            local gradle_log="$ARTIFACTS_DIR/debug/android_${type}_${locale}.log"
            local gradle_cmd="cd '$ROOT_DIR/shamelagpt-android' && ANDROID_SERIAL='$ANDROID_SERIAL' ./gradlew :app:connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.shamelagpt.android.screenshots.StoreScreenshotTest -Pandroid.testInstrumentationRunnerArguments.locale=$locale --info 2>&1 | tee '$gradle_log'"

            if ! run_android_gradle_with_timeout "$android_test_timeout_secs" "$gradle_cmd"; then
                fail_soft "Android $type tests failed for $locale"
            else
                ((PASSED_COUNT++))
            fi
            
            # Pull screenshots
            local out_dir="$ARTIFACTS_DIR/android/$type/$locale"
            mkdir -p "$out_dir"
            local connected_out="$ROOT_DIR/shamelagpt-android/app/build/outputs/connected_android_test_additional_output/debugAndroidTest/connected"
            if [ -d "$connected_out" ]; then
                # Find the locale folder under screenshots (device subfolder is dynamic)
                local locale_path
                locale_path=$(find "$connected_out" -type d -path "*/screenshots/*/$locale" | head -1)
                if [ -n "$locale_path" ] && [ -d "$locale_path" ]; then
                    find "$locale_path" -type f -name '*.png' -print -exec cp "{}" "$out_dir/" \;
                fi
            fi

            # Fallback pulls directly from device external storage (newer Android stores additionalTestOutput here)
            adb_cmd pull "/sdcard/Android/media/com.shamelagpt.android/additional_test_output/screenshots" "$out_dir/" 2>/dev/null || true
            adb_cmd pull "/sdcard/Android/data/com.shamelagpt.android/files/screenshots" "$out_dir/" 2>/dev/null || true

            # Clear intermediate output to avoid cross-locale bleed
            rm -rf "$connected_out" 2>/dev/null || true
        done
        adb_cmd emu kill 2>/dev/null || true
    done
}

# ============================================================================
# Main Execution
# ============================================================================

# Check for specific platform flags - handled at the top

[ "$RUN_IOS" = true ] && run_ios_screenshots
[ "$RUN_ANDROID" = true ] && run_android_screenshots

# ============================================================================
# Summary Report
# ============================================================================

echo ""
echo "============================================"
echo "== Screenshot Generation Summary =="
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
    echo "SUCCESS: All screenshot sets completed!"
    echo "--------------------------------------------"
    exit 0
fi
