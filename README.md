# Claude Context Watch

Real-time context window monitor for Claude Code using the StatusLine feature.

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

## Features

- **Real-time monitoring** - Updates every 300ms via StatusLine
- **Visual grid display** - 10x10 grid with color-coded usage
- **Complete metrics** - Tokens, cache, cost, percentage
- **Cross-platform** - macOS and Linux support
- **Easy setup** - One command configuration

## Prerequisites

- [Claude Code](https://github.com/anthropics/claude-code) CLI installed
- `jq` command-line JSON processor
- Bash 4.0+

## Installation

### Homebrew (macOS)

```bash
brew tap anthropics/claude-context-watch
brew install claude-context-watch
claude-context-watch --setup
```

### Manual Installation

```bash
git clone https://github.com/anthropics/claude-context-watch.git
cd claude-context-watch
./install.sh
```

### Quick Install (curl)

```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-context-watch/main/install.sh | bash
```

## Usage

```bash
# Start monitoring (TUI)
claude-context-watch

# Select session from list
claude-context-watch -s

# Configure/reconfigure StatusLine
claude-context-watch --setup

# Show help
claude-context-watch -h
```

## How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Claude Code    │────▶│  StatusLine      │────▶│  ~/.claude/     │
│  (300ms cycle)  │     │  context-writer  │     │  context.json   │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                               │                          │
                               ▼                          │
                        ┌──────────────────┐              │
                        │  Terminal status │              │
                        │  bar display     │              │
                        └──────────────────┘              │
                                                          │
                        ┌──────────────────┐              │
                        │  claude-context  │◀─────────────┘
                        │  -watch (TUI)    │  (0.3s read)
                        └──────────────────┘
```

1. **Claude Code** sends context data to StatusLine every ~300ms
2. **context-writer.sh** receives the data, saves to file, outputs status text
3. **claude-context-watch** reads the file and displays the TUI monitor

## Display

```
  ╔════════════════════════════════════════════════╗
  ║     🔍 Claude Context Monitor v1.0.0          ║
  ╚════════════════════════════════════════════════╝

  Model: Opus
  Session: a1b2c3d4...

  Context Usage
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   Context Monitor
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ Low
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁ ⛁   ⛁ Mid
     ⛁ ⛁ ⛁ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶   ⛁ High
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛶ Free
     ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   ⛝ Buffer
     ⛶ ⛶ ⛶ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝
     ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝

  45k / 200k tokens  (45%)
  Cache read: 12k tokens

  ✅ Healthy

  Cost: $0.0142
  Updated: 2025-02-05T10:30:00
  Ctrl+C to exit | -s to select session
```

## StatusLine Output

When configured, Claude Code's terminal shows a compact status:

```
🟢 45.2k/200k (22%) 📦12.5k $0.01
```

- 🟢/🟡/🟠/🔴 - Usage indicator
- Token usage / Total
- Cache read amount (if significant)
- Session cost

## Status Indicators

| Usage | Status | Indicator |
|-------|--------|-----------|
| < 60% | Healthy | 🟢 |
| 60-80% | Moderate | 🟡 |
| 80-90% | High | 🟠 |
| > 90% | Critical | 🔴 |

## Configuration

### Environment Variables

```bash
# Custom context file location
export CLAUDE_CONTEXT_FILE="/path/to/context.json"
```

### Manual StatusLine Setup

If `--setup` doesn't work, manually edit `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/context-writer.sh"
  }
}
```

## Uninstallation

```bash
./uninstall.sh
```

Or manually:

```bash
sudo rm /usr/local/bin/claude-context-watch
sudo rm -rf /usr/local/share/claude-context-watch
rm ~/.claude/context-writer.sh
# Optionally remove statusLine from ~/.claude/settings.json
```

## Troubleshooting

### "Waiting for Claude Code..."

1. Ensure StatusLine is configured: `claude-context-watch --setup`
2. Restart Claude Code
3. Send a message to start the session

### StatusLine not showing

1. Check `~/.claude/settings.json` has the statusLine config
2. Ensure `~/.claude/context-writer.sh` exists and is executable
3. Restart Claude Code

### Permission denied

```bash
chmod +x ~/.claude/context-writer.sh
```

## Project Structure

```
claude-context-watch/
├── bin/
│   └── claude-context-watch      # Main TUI monitor
├── lib/
│   ├── context-writer.sh         # StatusLine script
│   └── platform.sh               # Cross-platform utilities
├── install.sh                    # Installation script
├── uninstall.sh                  # Uninstallation script
├── Formula/
│   └── claude-context-watch.rb   # Homebrew formula
└── README.md
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Related

- [Claude Code](https://github.com/anthropics/claude-code) - The official CLI for Claude
