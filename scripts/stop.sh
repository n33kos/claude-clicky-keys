#!/bin/bash
# Hook wrapper: Parse stdin, manage counter/locks, stop sound
# All complexity lives here - kill.sh is pure audio control

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOME}/.claude/clicky-keys.env"
TMP_DIR="/tmp/claude-clicky-keys"
COUNTER_FILE="${TMP_DIR}/counter"
PID_FILE="${TMP_DIR}/pid"
LOCK_DIR="${TMP_DIR}/lock"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

CLICKY_SOUND_FILE="${CLICKY_SOUND_FILE:-clicking-keys.mp3}"
CLICKY_STOP_DELAY="${CLICKY_STOP_DELAY:-0.4}"  # Delay before stopping (seconds)

# Read hook input from stdin (with timeout to prevent blocking when called manually)
HOOK_INPUT=$(timeout 0.1 cat 2>/dev/null || true)

# Extract tool name from JSON input
TOOL_NAME=""
if [ -n "$HOOK_INPUT" ]; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Check if this tool would have triggered sound (must match start.sh logic)
CLICKY_TRIGGERS="${CLICKY_TRIGGERS:-Edit,MultiEdit,Write,Bash,Task}"
if [ -n "$TOOL_NAME" ]; then
    if [[ ! ",$CLICKY_TRIGGERS," == *",$TOOL_NAME,"* ]]; then
        exit 0
    fi
fi

# === Counter/Lock Management ===

# Atomic decrement using mkdir lock
while ! mkdir "$LOCK_DIR" 2>/dev/null; do sleep 0.01; done

COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE")
COUNT=$((COUNT - 1))
[ "$COUNT" -lt 0 ] && COUNT=0
echo "$COUNT" > "$COUNTER_FILE"

# Release lock
rmdir "$LOCK_DIR"

# Only stop if counter reached zero
if [ "$COUNT" -gt 0 ]; then
    exit 0
fi

# === Stop Delay ===

# Ensure sound plays for a minimum duration before stopping
if [ -n "$CLICKY_STOP_DELAY" ] && [ "$CLICKY_STOP_DELAY" != "0" ]; then
    sleep "$CLICKY_STOP_DELAY"
fi

# === Stop Sound ===

# Get PID if available
PID=""
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    rm -f "$PID_FILE"
fi

# Call kill.sh with PID
export CLICKY_SOUND_FILE
"${SCRIPT_DIR}/kill.sh" "$PID"

rm -f "$COUNTER_FILE"
