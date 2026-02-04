---
name: telegram-local
description: Send large files (>50MB) and messages via Telegram Local Bot API server. Use when needing to bypass Telegram's 50MB upload limit, send files through local API, or when the standard message tool fails for large files.
---

# Telegram Local API

Send messages and files via Telegram's Local Bot API server (bypasses 50MB limit).

## Usage

```bash
export TG_BOT_TOKEN="your_token"

# Text message
scripts/tg-send.sh -c <chat_id> -m "Hello"

# Document (any file, no size limit)
scripts/tg-send.sh -c <chat_id> -f /path/to/large_file.zip

# Photo/Video/Audio with caption
scripts/tg-send.sh -c <chat_id> -f video.mp4 -t video -m "Caption"
```

## Options

| Flag | Description |
|------|-------------|
| `-c` | Chat ID (required) |
| `-m` | Text message or caption |
| `-f` | File path |
| `-t` | Type: `document`/`photo`/`video`/`audio`/`voice`/`animation` |
| `-p` | Parse mode: `Markdown`/`MarkdownV2`/`HTML` |
| `-r` | Reply to message ID |
| `-s` | Silent (no notification) |
| `-A` | API URL (default: `http://127.0.0.1:8081`) |

## Environment

- `TG_BOT_TOKEN` - Bot token (required)
- `TG_LOCAL_API` - API URL (default: `http://127.0.0.1:8081`)

Check `TOOLS.md` for local credentials and chat IDs.
