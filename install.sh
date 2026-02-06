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
    printf "Installing files...\n"

    # Create directories
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$SHARE_DIR"
    mkdir -p "$CLAUDE_DIR"

    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
        echo "$updated" > "$settings_file"
        printf "  ${GREEN}✓${NC} Updated settings.json\n"
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
check_dependencies
install_files
configure_statusline
print_success
