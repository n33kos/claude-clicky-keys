#!/bin/bash
# Uninstall script for Claude Clicky Keys
# Removes hooks from Claude Code settings

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Settings file locations
USER_SETTINGS="$HOME/.claude/settings.json"
PROJECT_SETTINGS=".claude/settings.json"

# Parse arguments
SETTINGS_FILE=""
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --file)
            SETTINGS_FILE="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ "$QUIET" != "true" ]; then
    echo "🎹 Claude Clicky Keys Uninstaller"
    echo "=================================="
    echo ""
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: 'jq' is required but not installed."
    echo "   Install with: brew install jq"
    exit 1
fi

# If no file specified, ask user
if [ -z "$SETTINGS_FILE" ]; then
    # Check which files have our hooks
    HAS_USER_HOOKS=false
    HAS_PROJECT_HOOKS=false

    if [ -f "$USER_SETTINGS" ] && jq -e '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("claude-clicky-keys"))' "$USER_SETTINGS" > /dev/null 2>&1; then
        HAS_USER_HOOKS=true
    fi

    if [ -f "$PROJECT_SETTINGS" ] && jq -e '.hooks.PreToolUse[]?.hooks[]? | select(.command | contains("claude-clicky-keys"))' "$PROJECT_SETTINGS" > /dev/null 2>&1; then
        HAS_PROJECT_HOOKS=true
    fi

    if [ "$HAS_USER_HOOKS" = "false" ] && [ "$HAS_PROJECT_HOOKS" = "false" ]; then
        echo "ℹ️  No Claude Clicky Keys hooks found in either settings file."
        exit 0
    fi

    echo "Found hooks in:"
    [ "$HAS_USER_HOOKS" = "true" ] && echo "  1) User settings (~/.claude/settings.json)"
    [ "$HAS_PROJECT_HOOKS" = "true" ] && echo "  2) Project settings (.claude/settings.json)"
    echo ""

    if [ "$HAS_USER_HOOKS" = "true" ] && [ "$HAS_PROJECT_HOOKS" = "true" ]; then
        read -p "Which would you like to uninstall from? (1, 2, or 'both'): " choice
        case $choice in
            1)
                SETTINGS_FILE="$USER_SETTINGS"
                ;;
            2)
                SETTINGS_FILE="$PROJECT_SETTINGS"
                ;;
            both)
                "$0" --file "$USER_SETTINGS"
                "$0" --file "$PROJECT_SETTINGS"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice. Exiting."
                exit 1
                ;;
        esac
    elif [ "$HAS_USER_HOOKS" = "true" ]; then
        SETTINGS_FILE="$USER_SETTINGS"
    else
        SETTINGS_FILE="$PROJECT_SETTINGS"
    fi
fi

# Check if file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ Settings file not found: $SETTINGS_FILE"
    exit 1
fi

# Remove only the specific command entries that contain "claude-clicky-keys"
# while preserving other commands in the same hook object
TEMP_FILE=$(mktemp)
jq '
  # For each hook type, filter out claude-clicky-keys commands from within each hook object
  # and only keep hook objects that still have remaining commands
  .hooks.PreToolUse = [.hooks.PreToolUse[]? | .hooks = [.hooks[]? | select(.command | contains("claude-clicky-keys") | not)] | select(.hooks | length > 0)] |
  .hooks.PostToolUse = [.hooks.PostToolUse[]? | .hooks = [.hooks[]? | select(.command | contains("claude-clicky-keys") | not)] | select(.hooks | length > 0)] |
  .hooks.PostToolUseFailure = [.hooks.PostToolUseFailure[]? | .hooks = [.hooks[]? | select(.command | contains("claude-clicky-keys") | not)] | select(.hooks | length > 0)] |
  # Clean up empty arrays
  if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end |
  if .hooks.PostToolUse == [] then del(.hooks.PostToolUse) else . end |
  if .hooks.PostToolUseFailure == [] then del(.hooks.PostToolUseFailure) else . end |
  # Clean up empty hooks object
  if .hooks == {} then del(.hooks) else . end
' "$SETTINGS_FILE" > "$TEMP_FILE"

mv "$TEMP_FILE" "$SETTINGS_FILE"

if [ "$QUIET" != "true" ]; then
    echo ""
    echo "✅ Claude Clicky Keys uninstalled from: $SETTINGS_FILE"
    echo ""
    echo "⚠️  Restart Claude Code for changes to take effect."
fi

# Also stop any running typing sounds
"$SCRIPT_DIR/scripts/claude-clicky-keys-stop.sh" 2>/dev/null || true
