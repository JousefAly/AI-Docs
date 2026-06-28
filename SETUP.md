# Claude Code PreCompact Hook — Setup Guide

Saves the full conversation to a readable Markdown file before Claude compacts the context.

## Files in this repo

| File | Purpose |
|------|---------|
| `save_compact.ps1` | Hook script — reads the transcript and writes the `.md` export |
| `SETUP.md` | This guide |

Output files are written here too (one subfolder per session ID), but you don't need to commit those.

---

## Setup on a new machine

### 1. Place the script

Copy `save_compact.ps1` to `D:\ClaudeCompactedDiscussions\` (or any path — just update step 2 to match).

### 2. Register the hook in Claude Code global settings

Open (or create) `%USERPROFILE%\.claude\settings.json` and add the `hooks` block, merging with any existing settings:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NonInteractive -File \"D:\\ClaudeCompactedDiscussions\\save_compact.ps1\"",
            "shell": "powershell",
            "timeout": 30,
            "statusMessage": "Saving session before compacting..."
          }
        ]
      }
    ]
  }
}
```

### 3. Verify

Run `/compact` in any Claude Code session. You should see:

> `PreCompact [powershell ...] completed successfully`

A file like `compact-2026-06-28_17-45-00-your-first-message-here.md` will appear under `D:\ClaudeCompactedDiscussions\<session-id>\`.

---

## What the export contains

- Session ID, timestamp, trigger type
- All human messages and assistant text (tool calls and thinking blocks are skipped)
- Filename derived from the first line of your first message, truncated to 60 chars
