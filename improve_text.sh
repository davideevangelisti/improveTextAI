#!/bin/bash
# improve_text.sh — calls local Ollama to improve selected text.

set -euo pipefail

TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

cat > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    exit 0
fi

SYSTEM="You are a writing assistant. When given text, you rewrite it to improve clarity, grammar, and style while preserving the original meaning and formatting. You output ONLY the rewritten text — no explanations, no preamble, no markdown headers, no quotes. Never truncate or omit any part of the text."

PAYLOAD=$(python3 - "$TMPFILE" <<'EOF'
import json, sys

system = "You are a writing assistant. Fix grammar, spelling, and punctuation in the given text with minimal changes. Keep the original wording, tone, and sentence structure as close as possible — only change what is clearly wrong or awkward. Do not rephrase, restructure, or improve style unless necessary. Preserve all formatting. Output ONLY the corrected text — no explanations, no preamble, no quotes. Never truncate or omit any part of the text."

with open(sys.argv[1], 'r') as f:
    user = f.read()

payload = {
    "model": "llama3.1:8b",
    "stream": False,
    "options": {
        "num_predict": 8192
    },
    "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user}
    ]
}
print(json.dumps(payload))
EOF
)

RESPONSE=$(curl -s http://localhost:11434/api/chat \
    -H "content-type: application/json" \
    -d "$PAYLOAD")

python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
print(data['message']['content'], end='')
" <<< "$RESPONSE"
