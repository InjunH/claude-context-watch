#!/bin/bash
# context-writer.sh - StatusLine script for Claude Code
# This script is called by Claude Code every ~300ms with context data
#
# Input: JSON data via stdin with context_window, cost, model info
# Output: Status text to stdout (displayed in Claude Code terminal)
# Side effect: Saves full data to ~/.claude/context.json for external monitoring

set -e

CONTEXT_FILE="${CLAUDE_CONTEXT_FILE:-${HOME}/.claude/context.json}"

# Security: Ensure directory exists with proper permissions
CONTEXT_DIR="$(dirname "$CONTEXT_FILE")"
if [ ! -d "$CONTEXT_DIR" ]; then
    mkdir -p "$CONTEXT_DIR"
    chmod 700 "$CONTEXT_DIR"
fi

# Security: Check for symlink attacks
if [ -L "$CONTEXT_FILE" ]; then
    echo "⚠️ Security: symlink detected"
    exit 1
fi

# Read JSON from stdin
read_input() {
    cat
}

# Format token count (e.g., 15234 -> "15.2k")
format_tokens() {
    local tokens="${1:-0}"
    if ! [[ "$tokens" =~ ^[0-9]+$ ]]; then
        echo "0"
        return
    fi
    if [ "$tokens" -ge 1000 ]; then
        printf "%.1fk" "$(echo "scale=1; $tokens / 1000" | bc 2>/dev/null || echo "$((tokens / 1000))")"
    else
        echo "$tokens"
    fi
}

# Get status indicator based on percentage
get_status_indicator() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then
        echo "🔴"
    elif [ "$pct" -ge 80 ]; then
        echo "🟠"
    elif [ "$pct" -ge 60 ]; then
        echo "🟡"
    else
        echo "🟢"
    fi
}

# Main processing
main() {
    local input
    input=$(read_input)

    # Validate JSON
    if ! echo "$input" | jq -e . >/dev/null 2>&1; then
        echo "⚠️ Invalid JSON from Claude Code"
        exit 0
    fi

    # Add timestamp and save to file for external monitoring
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

    # Extract session_id for per-session context file
    local session_id
    session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)

    # Write with secure permissions (owner read/write only)
    umask 077

    # Save to main context file (for current active session)
    echo "$input" | jq --arg ts "$timestamp" '. + {timestamp: $ts}' > "$CONTEXT_FILE" 2>/dev/null || true
    chmod 600 "$CONTEXT_FILE" 2>/dev/null || true

    # Also save per-session context file (for session switching)
    if [ -n "$session_id" ]; then
        local sessions_dir="${HOME}/.claude/contexts"
        mkdir -p "$sessions_dir" 2>/dev/null
        chmod 700 "$sessions_dir" 2>/dev/null || true
        local session_file="${sessions_dir}/${session_id}.json"
        echo "$input" | jq --arg ts "$timestamp" '. + {timestamp: $ts}' > "$session_file" 2>/dev/null || true
        chmod 600 "$session_file" 2>/dev/null || true
    fi

    # Extract all values in a single jq call
    local used_pct total_input context_size cost model_name cache_creation cache_read
    read -r used_pct total_input context_size cost model_name cache_creation cache_read < <(
        echo "$input" | jq -r '[
            (.context_window.used_percentage // 0 | floor),
            (.context_window.total_input_tokens // 0),
            (.context_window.context_window_size // 200000),
            (.cost.total_cost_usd // 0),
            (.model.display_name // "Claude"),
            (.context_window.current_usage.cache_creation_input_tokens // 0),
            (.context_window.current_usage.cache_read_input_tokens // 0)
        ] | @tsv' 2>/dev/null
    ) || { used_pct=0; total_input=0; context_size=200000; cost=0; model_name="Claude"; cache_creation=0; cache_read=0; }

    # Format values
    local input_fmt context_fmt
    input_fmt=$(format_tokens "$total_input")
    context_fmt=$(format_tokens "$context_size")

    # Build status line
    local indicator
    indicator=$(get_status_indicator "$used_pct")

    local status_line="${indicator} ${input_fmt}/${context_fmt} (${used_pct}%)"

    # Add cache info if significant
    if [ "$cache_read" -gt 1000 ]; then
        local cache_fmt
        cache_fmt=$(format_tokens "$cache_read")
        status_line="${status_line} 📦${cache_fmt}"
    fi

    # Add cost
    local cost_fmt
    cost_fmt=$(printf '$%.2f' "$cost")
    status_line="${status_line} ${cost_fmt}"

    # Output to stdout (displayed by Claude Code)
    echo "$status_line"
}

main "$@"
