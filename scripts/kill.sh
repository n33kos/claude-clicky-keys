#!/bin/bash
# Core script: Stop the looping typing sound
# Pure audio control - no counter/lock logic
# Expects: PID as argument or CLICKY_SOUND_FILE env for pkill fallback

# macOS only
[[ "$(uname)" != "Darwin" ]] && exit 0

PID="$1"
CLICKY_SOUND_FILE="${CLICKY_SOUND_FILE:-clicking-keys.mp3}"

# Kill by PID if provided
if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
fi

# Always pkill as fallback/cleanup
pkill -f "afplay.*${CLICKY_SOUND_FILE}" 2>/dev/null || true
