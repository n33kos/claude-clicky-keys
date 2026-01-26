#!/bin/bash
# Start looping typing sound in background
# Uses atomic counter to handle parallel commands
# Configuration loaded from .env file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
SOUNDS_DIR="${PROJECT_DIR}/sounds"
COUNTER_FILE="/tmp/claude-clicky-keys.counter"
LOCK_DIR="/tmp/claude-clicky-keys.lock"

# Load configuration
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

# Set defaults if not configured
CLICKY_SOUND_FILE="${CLICKY_SOUND_FILE:-clicking-keys.mp3}"
CLICKY_VOLUME="${CLICKY_VOLUME:-0.5}"
CLICKY_MAX_DURATION="${CLICKY_MAX_DURATION:-60}"

# Resolve sound file path
if [[ "$CLICKY_SOUND_FILE" = /* ]]; then
    # Absolute path
    SOUND_FILE="$CLICKY_SOUND_FILE"
else
    # Relative to sounds directory
    SOUND_FILE="${SOUNDS_DIR}/${CLICKY_SOUND_FILE}"
fi

# Check if sound file exists
if [ ! -f "$SOUND_FILE" ]; then
    echo "Error: Sound file not found: $SOUND_FILE" >&2
    exit 1
fi

# Atomic increment using mkdir lock
while ! mkdir "$LOCK_DIR" 2>/dev/null; do sleep 0.01; done

# Read counter
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE")

# Check for stale counter (counter > 0 but no sound playing)
# This handles the case where a previous session was killed mid-execution
if [ "$COUNT" -gt 0 ]; then
    if ! pgrep -f "afplay.*clicking-keys" > /dev/null 2>&1; then
        # Counter is stale, reset it
        COUNT=0
    fi
fi

# Increment counter
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Release lock
rmdir "$LOCK_DIR"

# Only the first command (counter=1) should start the sound
if [ "$COUNT" -gt 1 ]; then
    exit 0
fi

# Clean up any orphaned processes from previous sessions
pkill -f "afplay.*clicking-keys.mp3" 2>/dev/null || true

# Build afplay arguments
AFPLAY_ARGS=(-v "$CLICKY_VOLUME")
if [ -n "$CLICKY_SPEED" ]; then
    AFPLAY_ARGS+=(-r "$CLICKY_SPEED")
fi

# Start looping sound in background with auto-timeout
# Redirect all output and fully detach from parent
(
    START_TIME=$(date +%s)
    while true; do
        # Check if we've exceeded max duration
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ "$ELAPSED" -ge "$CLICKY_MAX_DURATION" ]; then
            exit 0
        fi
        afplay "${AFPLAY_ARGS[@]}" "$SOUND_FILE" 2>/dev/null
    done
) > /dev/null 2>&1 &

# Detach from parent shell job control
disown
