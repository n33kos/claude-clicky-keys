#!/bin/bash
# Install script for Claude Clicky Keys
# Adds hooks to Claude Code settings

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_SCRIPT="${SCRIPT_DIR}/start-typing.sh"
STOP_SCRIPT="${SCRIPT_DIR}/stop-typing.sh"

# Settings file locations
USER_SETTINGS="$HOME/.claude/settings.json"
PROJECT_SETTINGS=".claude/settings.json"

echo "🎹 Claude Clicky Keys Installer"
echo "================================"
echo ""

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: 'jq' is required but not installed."
    echo "   Install with: brew install jq"
    exit 1
fi

# Check if scripts exist and are executable
if [ ! -x "$START_SCRIPT" ] || [ ! -x "$STOP_SCRIPT" ]; then
    echo "Making scripts executable..."
    chmod +x "$START_SCRIPT" "$STOP_SCRIPT"
fi

# Ask where to install
echo "Where would you like to install the hooks?"
echo ""
echo "1) User settings (~/.claude/settings.json)"
echo "   Applies to ALL Claude Code sessions"
echo ""
echo "2) Project settings (.claude/settings.json)"
echo "   Only applies to the current project"
echo ""
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        SETTINGS_FILE="$USER_SETTINGS"
        ;;
    2)
        SETTINGS_FILE="$PROJECT_SETTINGS"
        mkdir -p "$(dirname "$SETTINGS_FILE")"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

# Create settings file if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "{}" > "$SETTINGS_FILE"
    echo "Created new settings file: $SETTINGS_FILE"
fi

# Check if hooks already exist
if jq -e '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("claude-clicky-keys"))' "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo ""
    echo "⚠️  Claude Clicky Keys hooks are already installed in this settings file."
    read -p "Would you like to reinstall? (y/n): " reinstall
    if [ "$reinstall" != "y" ]; then
        echo "Exiting without changes."
        exit 0
    fi
    # Remove existing hooks first
    "$SCRIPT_DIR/uninstall.sh" --file "$SETTINGS_FILE" --quiet
fi

# Build the hooks JSON
HOOKS_JSON=$(cat <<EOF
{
  "PreToolUse": [
    {
      "matcher": "Edit|Write|Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${START_SCRIPT}"
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Edit|Write|Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${STOP_SCRIPT}"
        }
      ]
    }
  ],
  "PostToolUseFailure": [
    {
      "matcher": "Edit|Write|Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${STOP_SCRIPT}"
        }
      ]
    }
  ]
}
EOF
)

# Merge hooks into settings
TEMP_FILE=$(mktemp)
if jq -e '.hooks' "$SETTINGS_FILE" > /dev/null 2>&1; then
    # Hooks already exist, merge
    jq --argjson newhooks "$HOOKS_JSON" '
      .hooks.PreToolUse = (.hooks.PreToolUse // []) + $newhooks.PreToolUse |
      .hooks.PostToolUse = (.hooks.PostToolUse // []) + $newhooks.PostToolUse |
      .hooks.PostToolUseFailure = (.hooks.PostToolUseFailure // []) + $newhooks.PostToolUseFailure
    ' "$SETTINGS_FILE" > "$TEMP_FILE"
else
    # No hooks yet, add new hooks object
    jq --argjson newhooks "$HOOKS_JSON" '.hooks = $newhooks' "$SETTINGS_FILE" > "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$SETTINGS_FILE"

echo ""
echo "✅ Claude Clicky Keys installed successfully!"
echo ""
echo "📁 Hooks added to: $SETTINGS_FILE"
echo "🔊 Sound file location: ${SCRIPT_DIR}/sounds/keyboard-typing.aiff"
echo ""
echo "⚠️  IMPORTANT: Restart Claude Code for hooks to take effect."
echo ""
echo "To add a custom typing sound, place an audio file at:"
echo "   ${SCRIPT_DIR}/sounds/keyboard-typing.aiff"
echo ""
echo "To uninstall, run: ${SCRIPT_DIR}/uninstall.sh"
