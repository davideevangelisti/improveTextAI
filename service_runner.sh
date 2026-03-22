#!/bin/bash
# service_runner.sh — wrapper called by the Automator Service.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start Ollama if not already running
if ! curl -s http://localhost:11434 > /dev/null 2>&1; then
    /usr/local/bin/ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

# Read selected text from stdin (Automator pipes it in)
INPUT=$(cat)

if [ -z "$INPUT" ]; then
    exit 0
fi

# Notify user that processing has started
afplay /System/Library/Sounds/Morse.aiff &
osascript -e 'display notification "Improving your text..." with title "✍️ Improve Text"'

# Improve text
IMPROVED=$(echo "$INPUT" | bash "$SCRIPT_DIR/improve_text.sh")
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    osascript -e 'display notification "Something went wrong. Is Ollama running?" with title "Improve Text"'
    exit $EXIT_CODE
fi

# Notify user that it's done and text is being replaced
afplay /System/Library/Sounds/Glass.aiff &
osascript -e 'display notification "Done! Text has been replaced." with title "✅ Improve Text"'

# Output the improved text — Automator will replace the selection with this
echo "$IMPROVED"
