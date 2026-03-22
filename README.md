# improveTextAI

Improve selected text with a local LLM via a keyboard shortcut in any macOS app.

- Runs fully **locally** via [Ollama](https://ollama.com) — no data leaves your Mac
- Works in any native macOS app via the **Services menu**
- Works in **Electron apps** (WhatsApp, Slack, VS Code, etc.) via **Raycast**
- Plays a sound when it starts and when it's done
- Conservative rewriting: fixes grammar and spelling, preserves your tone and structure

## Requirements

- macOS
- [Ollama](https://ollama.com) (installed automatically by the install script via Homebrew)
- [Raycast](https://raycast.com) (optional, for global shortcut support in all apps)

## Install

```bash
bash install.sh
```

This installs the macOS Service under `~/Library/Services/`.

Then pull the model:

```bash
ollama pull llama3.1:8b
```

## Raycast (global shortcut)

Add `RaycastScript.sh` as a Script Command in Raycast → Settings → Extensions → Script Commands.

The shortcut is `Ctrl+\`.

> **Note:** Raycast needs Accessibility permission to simulate keystrokes.
> Go to Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen and add Raycast.

## How it works

1. Select any text
2. Press `Ctrl+\` (or right-click → Services → **Improve Text with AI** in native apps)
3. A sound plays while the model works
4. The selected text is replaced with the improved version
