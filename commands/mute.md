---
description: Toggle clicky-keys sounds on/off
allowed-tools: [Read, Write, Bash]
---

# Toggle Clicky Keys Mute

Toggle the mute state for clicky-keys sounds.

## Instructions

1. Read the current config from `~/.claude/clicky-keys.env`

2. Find the current value of `CLICKY_MUTED` (defaults to "false" if not present)

3. Toggle the value:
   - If currently "true", change to "false"
   - If currently "false" (or not set), change to "true"

4. Update the config file with the new value using sed or by rewriting the file

5. Report the new state to the user:
   - If now muted: "Clicky keys muted. Run `/clicky-keys:mute` again to unmute."
   - If now unmuted: "Clicky keys unmuted. Sounds will play for configured tools."

6. If the config file doesn't exist, create it with default values and CLICKY_MUTED="true"
