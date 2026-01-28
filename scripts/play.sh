#!/bin/bash
# Core script: Start looping typing sound in background
# Pure audio control - no counter/lock logic
# Expects environment: SOUND_FILE, CLICKY_VOLUME, CLICKY_SPEED, CLICKY_MAX_DURATION

# macOS only (requires afplay)
[[ "$(uname)" != "Darwin" ]] && exit 0

# Validate required inputs
if [ -z "$SOUND_FILE" ] || [ ! -f "$SOUND_FILE" ]; then
    echo "Error: SOUND_FILE not set or file not found" >&2
    exit 1
fi

# Defaults
CLICKY_VOLUME="${CLICKY_VOLUME:-0.5}"
CLICKY_MAX_DURATION="${CLICKY_MAX_DURATION:-30}"

# Build afplay arguments
AFPLAY_ARGS=(-v "$CLICKY_VOLUME")
if [ -n "$CLICKY_SPEED" ]; then
    AFPLAY_ARGS+=(-r "$CLICKY_SPEED")
fi

# Start looping sound in background with auto-timeout
(
    START_TIME=$(date +%s)
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        if [ "$ELAPSED" -ge "$CLICKY_MAX_DURATION" ]; then
            exit 0
        fi
        afplay "${AFPLAY_ARGS[@]}" "$SOUND_FILE" 2>/dev/null
    done
) > /dev/null 2>&1 &

# Output PID for caller to track
echo $!
disown
