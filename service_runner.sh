#!/bin/bash
# service_runner.sh — wrapper called by the Automator Service.

resolve_script_dir() {
    local source dir
    source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
IMPROVE_TEXT_SCRIPT="$SCRIPT_DIR/improve_text.sh"
LOG_FILE="$HOME/Library/Logs/improveTextAI.log"
if ! { mkdir -p "$(dirname "$LOG_FILE")" && : >> "$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/improveTextAI.log"
    : >> "$LOG_FILE" 2>/dev/null || true
fi

log() {
    { printf '%s service_runner: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; } 2>/dev/null >> "$LOG_FILE" || true
}

notify() {
    /usr/bin/osascript \
        -e 'on run argv' \
        -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
        -e 'end run' \
        "$1" "$2" >/dev/null 2>> "$LOG_FILE" || true
}

play_sound() {
    /usr/bin/afplay "$1" >/dev/null 2>> "$LOG_FILE" &
}

log "launched from $SCRIPT_DIR"

if [ ! -f "$IMPROVE_TEXT_SCRIPT" ]; then
    log "missing helper script at $IMPROVE_TEXT_SCRIPT"
    notify "Cannot find improve_text.sh. Reinstall the moved service." "Improve Text"
    exit 1
fi

# Read selected text from stdin (Automator pipes it in)
INPUT=$(cat)

if [ -z "$INPUT" ]; then
    log "exiting because no input was provided"
    exit 0
fi

# Notify user that processing has started
play_sound /System/Library/Sounds/Morse.aiff
notify "Improving your text..." "Improve Text"

# Improve text
ERROR_FILE=$(mktemp)
IMPROVED=$(printf '%s' "$INPUT" | bash "$IMPROVE_TEXT_SCRIPT" 2> "$ERROR_FILE")
EXIT_CODE=$?
ERROR_MESSAGE=$(tail -1 "$ERROR_FILE" 2>/dev/null || true)
rm -f "$ERROR_FILE"

if [ $EXIT_CODE -ne 0 ] || [ -z "$IMPROVED" ]; then
    [ $EXIT_CODE -ne 0 ] || EXIT_CODE=1
    [ -n "$ERROR_MESSAGE" ] || ERROR_MESSAGE="no improved text was returned"
    log "failed with exit $EXIT_CODE: $ERROR_MESSAGE"
    notify "Something went wrong. See ~/Library/Logs/improveTextAI.log" "Improve Text"
    exit $EXIT_CODE
fi

# Notify user that it's done and text is being replaced
play_sound /System/Library/Sounds/Glass.aiff
notify "Done! Text has been replaced." "Improve Text"
log "completed successfully"

# Output the improved text — Automator will replace the selection with this
printf '%s' "$IMPROVED"
