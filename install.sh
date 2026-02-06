#!/bin/bash
# Claude Context Watch - Installation Script
set -e

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/claude-context-watch"
CLAUDE_DIR="${HOME}/.claude"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo ""
    printf "${CYAN}╔════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║     🔍 Claude Context Watch Installer          ║${NC}\n"
    printf "${CYAN}║                v${VERSION}                          ║${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"
    echo ""
}

# Progress indicator
TOTAL_STEPS=4
CURRENT_STEP=0
progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    printf "\033[1;34m[%d/%d]\033[0m %s\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$1"
}

check_dependencies() {
    printf "Checking dependencies...\n"

    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        printf "  ${RED}✗${NC} jq not found\n"
        echo ""
        echo "Please install jq first:"
        if [ "$(uname)" = "Darwin" ]; then
            echo "  brew install jq"
        else
            echo "  apt install jq  # Debian/Ubuntu"
            echo "  yum install jq  # RHEL/CentOS"
        fi
        exit 1
    fi
    printf "  ${GREEN}✓${NC} jq\n"

    # Check bash version
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        printf "  ${YELLOW}!${NC} Bash ${BASH_VERSION} (4+ recommended)\n"
    else
        printf "  ${GREEN}✓${NC} Bash ${BASH_VERSION}\n"
    fi

    echo ""
}

install_files() {
    printf "This installation requires sudo privileges.\n"
    printf "You may be prompted for your password.\n\n"

    # Get script directory and normalize path
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SCRIPT_DIR="$(realpath "$SCRIPT_DIR" 2>/dev/null || echo "$SCRIPT_DIR")"

    # Verify source files exist before installation
    if [ ! -f "$SCRIPT_DIR/bin/claude-context-watch" ]; then
        printf "  ${RED}✗${NC} Source file not found: $SCRIPT_DIR/bin/claude-context-watch\n"
        exit 1
    fi
    if [ ! -d "$SCRIPT_DIR/lib" ] || [ -z "$(ls -A "$SCRIPT_DIR/lib/"*.sh 2>/dev/null)" ]; then
        printf "  ${RED}✗${NC} Source directory not found or empty: $SCRIPT_DIR/lib/\n"
        exit 1
    fi

    # Create directories
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$SHARE_DIR"
    mkdir -p "$CLAUDE_DIR"
    chmod 700 "$CLAUDE_DIR"

    # Install main binary
    sudo cp "$SCRIPT_DIR/bin/claude-context-watch" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/claude-context-watch"
    printf "  ${GREEN}✓${NC} Installed claude-context-watch to $INSTALL_DIR\n"

    # Install library files
    sudo cp "$SCRIPT_DIR/lib/"*.sh "$SHARE_DIR/"
    printf "  ${GREEN}✓${NC} Installed libraries to $SHARE_DIR\n"

    # Install context-writer to .claude
    cp "$SCRIPT_DIR/lib/context-writer.sh" "$CLAUDE_DIR/"
    chmod +x "$CLAUDE_DIR/context-writer.sh"
    printf "  ${GREEN}✓${NC} Installed context-writer.sh to $CLAUDE_DIR\n"

    echo ""
}

configure_statusline() {
    printf "Configuring StatusLine...\n"

    local settings_file="$CLAUDE_DIR/settings.json"
    local statusline_config='{"type":"command","command":"~/.claude/context-writer.sh"}'

    if [ -f "$settings_file" ]; then
        # Backup existing settings
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d%H%M%S)"

        # Check if statusLine already configured
        if jq -e '.statusLine' "$settings_file" >/dev/null 2>&1; then
            printf "  ${YELLOW}!${NC} StatusLine already configured (updating)\n"
        fi

        # Merge statusLine setting
        local updated
        updated=$(jq --argjson sl "$statusline_config" '.statusLine = $sl' "$settings_file")
        if [ -n "$updated" ]; then
            local temp_file
            temp_file=$(mktemp)
            if echo "$updated" > "$temp_file" && [ -s "$temp_file" ]; then
                mv "$temp_file" "$settings_file"
                printf "  ${GREEN}✓${NC} Updated settings.json\n"
            else
                rm -f "$temp_file"
                printf "  ${RED}✗${NC} Failed to update settings.json\n"
                exit 1
            fi
        else
            printf "  ${RED}✗${NC} Failed to update settings.json\n"
            exit 1
        fi
    else
        # Create new settings file
        echo "{\"statusLine\":$statusline_config}" | jq '.' > "$settings_file"
        printf "  ${GREEN}✓${NC} Created settings.json\n"
    fi

    echo ""
}

print_success() {
    printf "${GREEN}✅ Installation complete!${NC}\n\n"
    echo "Next steps:"
    echo "  1. Restart Claude Code (if running)"
    echo "  2. Start a conversation to activate monitoring"
    echo "  3. Run 'claude-context-watch' in another terminal"
    echo ""
    echo "Commands:"
    echo "  claude-context-watch          # Start monitoring"
    echo "  claude-context-watch -s       # Select session"
    echo "  claude-context-watch --setup  # Reconfigure StatusLine"
    echo ""
}

# Main
print_banner
progress "Checking dependencies..."
check_dependencies
progress "Installing files..."
install_files
progress "Configuring StatusLine..."
configure_statusline
progress "Finishing up..."
print_success
