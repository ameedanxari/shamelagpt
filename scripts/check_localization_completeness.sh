#!/usr/bin/env bash
set -euo pipefail

# Script to check for missing localization strings
# Compares all localization files against the English base file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_RESOURCES_DIR="$PROJECT_ROOT/shamelagpt-ios/shamelagpt/Resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to extract keys from a .strings file
extract_keys() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        print_status "$RED" "Error: File $file not found"
        return 1
    fi
    
    # Extract keys using sed - more reliable approach
    sed -n '/^[[:space:]]*\/\]/d; /^[[:space:]]*$/d; /^[[:space:]]*"[^"]*"[[:space:]]*=/ { s/^[[:space:]]*"\([^"]*\)".*/\1/; /^.$/!p; }' "$file" | sort
}

# Function to check localization completeness
check_localization_completeness() {
    local base_file="$IOS_RESOURCES_DIR/en.lproj/Localizable.strings"
    local locales=("ar" "ur")
    
    if [[ ! -f "$base_file" ]]; then
        print_status "$RED" "Error: English base file not found at $base_file"
        return 1
    fi
    
    print_status "$BLUE" "Checking localization completeness..."
    print_status "$BLUE" "Base file: $base_file"
    echo
    
    # Extract base keys
    local base_keys
    base_keys=$(extract_keys "$base_file")
    local base_key_count
    base_key_count=$(echo "$base_keys" | wc -l | tr -d ' ')
    
    print_status "$GREEN" "English base file has $base_key_count localization keys"
    echo
    
    local has_errors=false
    
    # Check each locale
    for locale in "${locales[@]}"; do
        local locale_file="$IOS_RESOURCES_DIR/${locale}.lproj/Localizable.strings"
        print_status "$YELLOW" "Checking $locale locale..."
        
        if [[ ! -f "$locale_file" ]]; then
            print_status "$RED" "  ❌ Localization file not found: $locale_file"
            has_errors=true
            continue
        fi
        
        # Extract locale keys
        local locale_keys
        locale_keys=$(extract_keys "$locale_file")
        local locale_key_count
        locale_key_count=$(echo "$locale_keys" | wc -l | tr -d ' ')
        
        # Find missing keys
        local missing_keys
        missing_keys=$(comm -23 <(echo "$base_keys") <(echo "$locale_keys"))
        local missing_count
        missing_count=$(echo "$missing_keys" | grep -c '.*' 2>/dev/null || echo "0")
        
        # Find extra keys (keys in locale but not in base)
        local extra_keys
        extra_keys=$(comm -13 <(echo "$base_keys") <(echo "$locale_keys"))
        local extra_count
        extra_count=$(echo "$extra_keys" | grep -c '.*' 2>/dev/null || echo "0")
        
        # Report results
        if [[ $missing_count -eq 0 && $extra_count -eq 0 ]]; then
            print_status "$GREEN" "  ✅ Complete! ($locale_key_count/$base_key_count keys)"
        else
            print_status "$RED" "  ❌ Incomplete ($locale_key_count/$base_key_count keys)"
            has_errors=true
            
            if [[ $missing_count -gt 0 && -n "$missing_keys" ]]; then
                print_status "$RED" "  Missing $missing_count keys:"
                echo "$missing_keys" | grep -v '^[[:space:]]*$' | sed 's/^/    - /'
            fi
            
            if [[ $extra_count -gt 0 && -n "$extra_keys" ]]; then
                print_status "$YELLOW" "  Extra $extra_count keys (not in base):"
                echo "$extra_keys" | grep -v '^[[:space:]]*$' | sed 's/^/    - /'
            fi
        fi
        echo
    done
    
    # Check for specific error message patterns that might be missing
    print_status "$BLUE" "Checking for common error message patterns..."
    
    local error_patterns=("error" "common" "ocr" "voice" "auth")
    for pattern in "${error_patterns[@]}"; do
        local error_keys
        error_keys=$(echo "$base_keys" | grep "$pattern" || true)
        
        if [[ -n "$error_keys" ]]; then
            print_status "$BLUE" "  $pattern keys in English:"
            echo "$error_keys" | sed 's/^/    - /'
            
            for locale in "${locales[@]}"; do
                local locale_file="$IOS_RESOURCES_DIR/${locale}.lproj/Localizable.strings"
                if [[ -f "$locale_file" ]]; then
                    local locale_error_keys
                    locale_error_keys=$(extract_keys "$locale_file" | grep "$pattern" || true)
                    local missing_error_keys
                    missing_error_keys=$(comm -23 <(echo "$error_keys") <(echo "$locale_error_keys"))
                    
                    if [[ -n "$missing_error_keys" ]]; then
                        print_status "$RED" "    ❌ $locale missing $pattern keys:"
                        echo "$missing_error_keys" | sed 's/^/      - /'
                        has_errors=true
                    fi
                fi
            done
            echo
        fi
    done
    
    # Summary
    if [[ "$has_errors" == "true" ]]; then
        print_status "$RED" "❌ Localization completeness check FAILED"
        print_status "$RED" "Please add the missing localization keys before committing."
        return 1
    else
        print_status "$GREEN" "✅ All localization files are complete!"
        return 0
    fi
}

# Function to check Android localization files
check_android_localization() {
    local android_res_dir="$PROJECT_ROOT/shamelagpt-android/app/src/main/res"
    
    if [[ ! -d "$android_res_dir" ]]; then
        print_status "$YELLOW" "Android resources directory not found, skipping Android localization check"
        return 0
    fi
    
    print_status "$BLUE" "Checking Android localization completeness..."
    
    local base_strings_file="$android_res_dir/values/strings.xml"
    if [[ ! -f "$base_strings_file" ]]; then
        print_status "$YELLOW" "Android base strings.xml not found, skipping Android check"
        return 0
    fi
    
    # Extract Android string keys
    local base_keys
    base_keys=$(grep -o 'name="[^"]*"' "$base_strings_file" | sed 's/name="//' | sed 's/"//' | sort)
    
    local locales=("ar" "ur")
    local has_android_errors=false
    
    for locale in "${locales[@]}"; do
        local locale_dir="$android_res_dir/values-$locale"
        local locale_strings_file="$locale_dir/strings.xml"
        
        if [[ ! -f "$locale_strings_file" ]]; then
            print_status "$RED" "  ❌ Android $locale strings.xml not found"
            has_android_errors=true
            continue
        fi
        
        local locale_keys
        locale_keys=$(grep -o 'name="[^"]*"' "$locale_strings_file" | sed 's/name="//' | sed 's/"//' | sort)
        
        local missing_keys
        missing_keys=$(comm -23 <(echo "$base_keys") <(echo "$locale_keys"))
        local missing_count
        missing_count=$(echo "$missing_keys" | grep -c '.*' 2>/dev/null || echo "0")
        
        if [[ $missing_count -eq 0 ]]; then
            print_status "$GREEN" "  ✅ Android $locale complete"
        else
            print_status "$RED" "  ❌ Android $locale missing $missing_count keys:"
            echo "$missing_keys" | grep -v '^[[:space:]]*$' | sed 's/^/    - /'
            has_android_errors=true
        fi
    done
    
    if [[ "$has_android_errors" == "true" ]]; then
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    print_status "$BLUE" "🔍 Localization Completeness Check"
    print_status "$BLUE" "================================="
    echo
    
    local ios_failed=false
    local android_failed=false
    
    # Check iOS localization
    if ! check_localization_completeness; then
        ios_failed=true
    fi
    
    echo
    
    # Check Android localization
    if ! check_android_localization; then
        android_failed=true
    fi
    
    echo
    print_status "$BLUE" "📋 Summary"
    print_status "$BLUE" "=========="
    
    if [[ "$ios_failed" == "true" || "$android_failed" == "true" ]]; then
        print_status "$RED" "❌ Localization check FAILED"
        if [[ "$ios_failed" == "true" ]]; then
            print_status "$RED" "  - iOS localization has issues"
        fi
        if [[ "$android_failed" == "true" ]]; then
            print_status "$RED" "  - Android localization has issues"
        fi
        print_status "$RED" "Please fix the missing translations before committing."
        return 1
    else
        print_status "$GREEN" "✅ All localization checks PASSED"
        return 0
    fi
}

# Run main function
main "$@"
