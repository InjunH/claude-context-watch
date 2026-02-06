#!/bin/bash
# Claude Context Watch - Uninstallation Script
set -e

INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/claude-context-watch"
CLAUDE_DIR="${HOME}/.claude"
CONTEXT_FILE="/tmp/claude-context.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo ""
    printf "${CYAN}╔════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║     🔍 Claude Context Watch Uninstaller        ║${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"
    echo ""
}

remove_files() {
    printf "Removing files...\n"

    # Remove binary
    if [ -f "$INSTALL_DIR/claude-context-watch" ]; then
        sudo rm -f "$INSTALL_DIR/claude-context-watch"
        printf "  ${GREEN}✓${NC} Removed $INSTALL_DIR/claude-context-watch\n"
    else
        printf "  ${YELLOW}-${NC} Binary not found (skipped)\n"
    fi

    # Remove library files
    if [ -d "$SHARE_DIR" ]; then
        sudo rm -rf "$SHARE_DIR"
        printf "  ${GREEN}✓${NC} Removed $SHARE_DIR\n"
    else
        printf "  ${YELLOW}-${NC} Library directory not found (skipped)\n"
    fi

    # Remove context-writer from .claude
    if [ -f "$CLAUDE_DIR/context-writer.sh" ]; then
        rm -f "$CLAUDE_DIR/context-writer.sh"
        printf "  ${GREEN}✓${NC} Removed $CLAUDE_DIR/context-writer.sh\n"
    else
        printf "  ${YELLOW}-${NC} context-writer.sh not found (skipped)\n"
    fi

    # Remove context file
    if [ -f "$CONTEXT_FILE" ]; then
        rm -f "$CONTEXT_FILE"
        printf "  ${GREEN}✓${NC} Removed $CONTEXT_FILE\n"
    fi

    echo ""
}

remove_statusline_config() {
    local settings_file="$CLAUDE_DIR/settings.json"

    if [ ! -f "$settings_file" ]; then
        printf "Settings file not found (skipped)\n\n"
        return
    fi

    printf "Remove StatusLine configuration from settings.json? [y/N] "
    if [ -t 0 ]; then
        read -r response
    else
        response="N"
    fi

    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Backup
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d%H%M%S)"

        # Remove statusLine key
        local updated
        updated=$(jq 'del(.statusLine)' "$settings_file")
        echo "$updated" > "$settings_file"
        printf "  ${GREEN}✓${NC} Removed StatusLine configuration\n"
    else
        printf "  ${YELLOW}-${NC} Kept StatusLine configuration\n"
    fi

    echo ""
}

print_success() {
    printf "${GREEN}✅ Uninstallation complete!${NC}\n\n"
    echo "Note: If you kept the StatusLine configuration,"
    echo "Claude Code may show an error on startup."
    echo "Run 'claude-context-watch --setup' to reconfigure,"
    echo "or manually remove 'statusLine' from ~/.claude/settings.json"
    echo ""
}

# Main
print_banner
remove_files
remove_statusline_config
print_success
