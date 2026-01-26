#!/bin/bash
# Start looping typing sound in background
# Stores PID in temp file so stop script can kill it
# Configuration loaded from .env file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
SOUNDS_DIR="${PROJECT_DIR}/sounds"
PID_FILE="/tmp/claude-clicky-keys.pid"

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

# Check if already running
if [ -f "$PID_FILE" ]; then
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Already running, exit silently
        exit 0
    fi
fi

# Build afplay arguments
AFPLAY_ARGS=(-v "$CLICKY_VOLUME")
if [ -n "$CLICKY_SPEED" ]; then
    AFPLAY_ARGS+=(-r "$CLICKY_SPEED")
fi

# Start looping sound in background with auto-timeout
(
    START_TIME=$(date +%s)
    while true; do
        # Check if we've exceeded max duration
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ "$ELAPSED" -ge "$CLICKY_MAX_DURATION" ]; then
            # Cleanup and exit
            rm -f "$PID_FILE"
            exit 0
        fi
        afplay "${AFPLAY_ARGS[@]}" "$SOUND_FILE" 2>/dev/null
    done
) &

# Store PID
echo $! > "$PID_FILE"
