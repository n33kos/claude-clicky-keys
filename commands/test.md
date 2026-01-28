---
description: Test the clicky-keys sound for a few seconds
allowed-tools: [Bash]
---

# Test Clicky Keys Sound

Play the typing sound for a brief moment to verify it works.

## Instructions

1. Run a simple bash command - the hooks will trigger the sound automatically:
   ```bash
   sleep 3
   ```

2. Report whether the sound played successfully. If it didn't play, remind the user:
   - This plugin requires macOS (uses `afplay`)
   - Run `/clicky-keys:setup` to configure volume and other settings
