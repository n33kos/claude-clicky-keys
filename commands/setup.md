---
description: Configure clicky-keys audio settings (volume, speed, triggers)
allowed-tools: [Read, Write, Bash, AskUserQuestion]
---

# Clicky Keys Setup

Configure the clicky-keys plugin settings interactively.

## Instructions

1. First, check the platform and audio player availability:
   - Run `uname` to detect macOS vs Linux
   - On macOS: `afplay` is built-in, no action needed
   - On Linux: check for `mpv`, `ffplay`, `paplay`, `aplay` (in that order). If none found, tell the user to install one:
     - Ubuntu/Debian: `sudo apt install mpv`
     - Fedora: `sudo dnf install mpv`
     - Arch: `sudo pacman -S mpv`
   - Report which player will be used

2. Check if the config file exists at `~/.claude/clicky-keys.env` and read its current values if it does.

3. Ask the user to configure their preferences using AskUserQuestion. Ask all questions in a single AskUserQuestion call with multiple questions:

   **Volume** (0.0 to 1.0):
   - Options: "0.1 (Quiet)", "0.3 (Low)", "0.5 (Medium - Recommended)", "0.7 (Loud)"

   **Playback Speed**:
   - Options: "0.8 (Slower)", "1.0 (Normal - Recommended)", "1.2 (Faster)", "1.5 (Fast)"

   **Tool Triggers** (which tools play sound) - use multiSelect: true:
   - Options: "Edit (Recommended)" - when files are edited, "MultiEdit" - when multiple edits in one call, "Write" - when new files are created, "Bash (Recommended)" - when shell commands run, "Task" - when subagents are spawned

   **Auto-stop Duration** (safety timeout in seconds):
   - Options: "30 seconds", "60 seconds (Recommended)", "120 seconds", "300 seconds"

4. Write the configuration to `~/.claude/clicky-keys.env` with this format:

```bash
# Clicky Keys Configuration
# Sound file (relative to plugin sounds/ or absolute path)
CLICKY_SOUND_FILE="clicking-keys.mp3"

# Audio player override (auto-detected if not set)
# macOS: afplay | Linux: mpv, ffplay, paplay, aplay
# CLICKY_PLAYER=""

# Volume (0.0 to 1.0)
CLICKY_VOLUME="<selected_volume>"

# Auto-stop timeout in seconds
CLICKY_MAX_DURATION="<selected_duration>"

# Playback speed (0.5 = half, 1.0 = normal, 2.0 = double)
CLICKY_SPEED="<selected_speed>"

# Delay before stopping sound in seconds (ensures fast operations are audible)
CLICKY_STOP_DELAY="0.4"

# Tools that trigger sound (comma-separated)
# Available: Edit, MultiEdit, Write, Bash, Task
CLICKY_TRIGGERS="<selected_triggers_comma_separated>"

# Mute sounds (true/false) - toggle with /clicky-keys:mute
CLICKY_MUTED="false"
```

5. Ensure the `~/.claude` directory exists before writing the file.

6. Offer to test the sound by running a simple bash command - the hooks will trigger automatically:
   - `sleep 2`
   - If you hear typing sounds during the sleep, the setup is working correctly

7. Confirm the setup is complete and remind the user:
   - Sound will play when Claude uses the selected tools
   - Use `/clicky-keys:mute` to toggle sounds on/off mid-session
