#!/bin/bash
# platform.sh - Cross-platform utility functions
# Provides compatibility layer for macOS and Linux

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)

# MD5 hash function
# Usage: md5_hash <file>
md5_hash() {
    local file="$1"
    case "$PLATFORM" in
        macos) md5 -q "$file" 2>/dev/null ;;
        linux) md5sum "$file" 2>/dev/null | cut -d' ' -f1 ;;
        *)     md5sum "$file" 2>/dev/null | cut -d' ' -f1 ;;
    esac
}

# File modification time
# Usage: file_mtime <file>
file_mtime() {
    local file="$1"
    case "$PLATFORM" in
        macos) stat -f '%m' "$file" 2>/dev/null ;;
        linux) stat --format='%Y' "$file" 2>/dev/null ;;
        *)     stat --format='%Y' "$file" 2>/dev/null ;;
    esac
}

# File size in bytes
# Usage: file_size <file>
file_size() {
    local file="$1"
    case "$PLATFORM" in
        macos) stat -f '%z' "$file" 2>/dev/null ;;
        linux) stat --format='%s' "$file" 2>/dev/null ;;
        *)     stat --format='%s' "$file" 2>/dev/null ;;
    esac
}

# Format timestamp to human readable date
# Usage: format_date <unix_timestamp> [format]
format_date() {
    local ts="$1"
    local fmt="${2:-%m/%d %H:%M}"
    case "$PLATFORM" in
        macos) date -r "$ts" "+$fmt" 2>/dev/null ;;
        linux) date -d "@$ts" "+$fmt" 2>/dev/null ;;
        *)     date -d "@$ts" "+$fmt" 2>/dev/null ;;
    esac
}

# Current timestamp in ISO format
current_timestamp() {
    date '+%Y-%m-%dT%H:%M:%S'
}

# Find files with modification time (returns: mtime filepath)
# Usage: find_files_with_mtime <directory> <pattern> [limit]
find_files_with_mtime() {
    local dir="$1"
    local pattern="$2"
    local limit="${3:-15}"

    case "$PLATFORM" in
        macos)
            find "$dir" -name "$pattern" -type f -exec stat -f '%m %N' {} \; 2>/dev/null | sort -rn | head -"$limit"
            ;;
        linux)
            find "$dir" -name "$pattern" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -"$limit"
            ;;
        *)
            find "$dir" -name "$pattern" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -"$limit"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies
check_dependencies() {
    local missing=()

    if ! command_exists jq; then
        missing+=("jq")
    fi

    # Check bash version (need 4+ for associative arrays)
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        echo "Warning: Bash 4+ recommended for full functionality" >&2
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}" >&2
        echo "Install with:" >&2
        case "$PLATFORM" in
            macos) echo "  brew install ${missing[*]}" >&2 ;;
            linux) echo "  apt install ${missing[*]}  # or yum/dnf" >&2 ;;
        esac
        return 1
    fi
    return 0
}

# Get Claude config directory
get_claude_config_dir() {
    echo "${HOME}/.claude"
}

# Get settings file path
get_settings_file() {
    echo "$(get_claude_config_dir)/settings.json"
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    [ -d "$dir" ] || mkdir -p "$dir"
}
