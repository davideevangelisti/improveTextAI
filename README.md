# Right Click to Improve

Improve selected text with a local LLM directly from the right-click menu (or a keyboard shortcut) in any macOS app.

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

Copy `raycast/improve-text.sh` to your Raycast Scripts directory and add that folder in Raycast → Settings → Extensions → Script Commands.

The default shortcut is `⌘⇧I`.

## How it works

1. Select any text
2. Right-click → Services → **Improve Text with AI** (or press `⌘⇧I` with Raycast)
3. A sound plays while the model works
4. The selected text is replaced with the improved version
