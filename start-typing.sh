#!/bin/bash
# Start looping typing sound in background
# Stores PID in temp file so stop script can kill it
# Auto-kills after MAX_DURATION seconds as safety measure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND_FILE="${SCRIPT_DIR}/sounds/keyboard-typing.aiff"
PID_FILE="/tmp/claude-clicky-keys.pid"
MAX_DURATION=60  # Safety timeout in seconds

# Check if already running
if [ -f "$PID_FILE" ]; then
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Already running, exit silently
        exit 0
    fi
fi

# Check if sound file exists
if [ ! -f "$SOUND_FILE" ]; then
    # Fallback to Tink sound
    SOUND_FILE="/System/Library/Sounds/Tink.aiff"
fi

# Start looping sound in background with auto-timeout
(
    START_TIME=$(date +%s)
    while true; do
        # Check if we've exceeded max duration
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ $ELAPSED -ge $MAX_DURATION ]; then
            # Cleanup and exit
            rm -f "$PID_FILE"
            exit 0
        fi
        afplay "$SOUND_FILE" 2>/dev/null
    done
) &

# Store PID
echo $! > "$PID_FILE"
