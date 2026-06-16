#!/bin/bash
# improve_text.sh — calls Claude API to improve selected text.

set -euo pipefail

LOG_FILE="$HOME/Library/Logs/improveTextAI.log"
if ! { mkdir -p "$(dirname "$LOG_FILE")" && : >> "$LOG_FILE"; } 2>/dev/null; then
    LOG_FILE="${TMPDIR:-/tmp}/improveTextAI.log"
    : >> "$LOG_FILE" 2>/dev/null || true
fi

log() {
    { printf '%s improve_text: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; } 2>/dev/null >> "$LOG_FILE" || true
}

TMPFILE=$(mktemp)
RESPONSE_FILE=$(mktemp)
ERROR_FILE=$(mktemp)

cleanup() {
    rm -f "$TMPFILE" "$RESPONSE_FILE" "$ERROR_FILE"
}
trap cleanup EXIT

cat > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    exit 0
fi

# Load API key
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -f "$HOME/.config/anthropic/api_key" ]; then
    export ANTHROPIC_API_KEY=$(cat "$HOME/.config/anthropic/api_key" | tr -d '[:space:]')
fi

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "ANTHROPIC_API_KEY not set" >&2
    log "ANTHROPIC_API_KEY not set"
    exit 1
fi

PAYLOAD=$(python3 - "$TMPFILE" <<'EOF'
import json, sys

system = "You are a writing assistant. The user will send you text wrapped in <text_to_improve> tags. Edit that text: fix grammar, spelling, and punctuation, and lightly improve phrasing where it sounds unnatural or unclear — but stay close to the original. Keep the author's tone, voice, and structure. Do not rewrite or restructure sentences unless truly necessary. Preserve all formatting. Output ONLY the corrected text, without the XML tags — no explanations, no preamble, no quotes. Never truncate or omit any part of the text."

with open(sys.argv[1], 'r') as f:
    user = "<text_to_improve>\n" + f.read() + "\n</text_to_improve>"

payload = {
    "model": "claude-sonnet-4-6",
    "max_tokens": 8192,
    "system": system,
    "messages": [
        {"role": "user", "content": user}
    ]
}
print(json.dumps(payload))
EOF
)

HTTP_STATUS=$(curl -sS --connect-timeout 10 --max-time 120 \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}" \
    https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$PAYLOAD" 2> "$ERROR_FILE") || {
        ERROR_MESSAGE=$(tr '\n' ' ' < "$ERROR_FILE" | sed 's/[[:space:]]*$//')
        [ -n "$ERROR_MESSAGE" ] || ERROR_MESSAGE="network request failed"
        echo "Anthropic request failed: $ERROR_MESSAGE" >&2
        log "Anthropic request failed: $ERROR_MESSAGE"
        exit 1
    }

case "$HTTP_STATUS" in
    ''|*[!0-9]*) HTTP_STATUS=000 ;;
esac

if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
    ERROR_MESSAGE=$(python3 - "$RESPONSE_FILE" <<'EOF'
import json, sys

try:
    with open(sys.argv[1], "r") as f:
        data = json.load(f)
except Exception:
    print("unexpected API error")
    sys.exit(0)

error = data.get("error", {})
print(error.get("message") or data.get("message") or json.dumps(data))
EOF
)
    echo "Anthropic request failed (HTTP $HTTP_STATUS): $ERROR_MESSAGE" >&2
    log "Anthropic request failed (HTTP $HTTP_STATUS): $ERROR_MESSAGE"
    exit 1
fi

python3 - "$RESPONSE_FILE" <<'EOF'
import json, sys

with open(sys.argv[1], "r") as f:
    data = json.load(f)

parts = []
for item in data.get("content", []):
    if item.get("type") == "text":
        parts.append(item.get("text", ""))

if parts:
    print("".join(parts), end="")
else:
    print("Anthropic response did not include text content", file=sys.stderr)
    sys.exit(1)
EOF
