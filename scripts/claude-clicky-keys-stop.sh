#!/bin/bash
# Stop the looping typing sound

# Kill all instances of claude-clicky-keys-start.sh
pkill -f "claude-clicky-keys-start.sh" 2>/dev/null || true

# Kill all afplay processes playing clicking-keys.mp3
pkill -f "afplay.*clicking-keys.mp3" 2>/dev/null || true
