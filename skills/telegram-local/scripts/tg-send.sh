#!/usr/bin/env bash
# tg-send.sh - Send messages/files via Telegram Local Bot API
# Bypasses 50MB upload limit by using local server
#
# Usage:
#   tg-send.sh -c <chat_id> -m "message"           # Send text message
#   tg-send.sh -c <chat_id> -f /path/to/file       # Send document
#   tg-send.sh -c <chat_id> -f /path/to/file -t photo   # Send as photo
#   tg-send.sh -c <chat_id> -f /path/to/file -t video   # Send as video
#   tg-send.sh -c <chat_id> -f /path/to/file -t audio   # Send as audio
#   tg-send.sh -c <chat_id> -f /path/to/file -m "caption" # File with caption

set -euo pipefail

# Config - override via env vars
TG_LOCAL_API="${TG_LOCAL_API:-http://127.0.0.1:8081}"
TG_BOT_TOKEN="${TG_BOT_TOKEN:-}"

# Parse args
CHAT_ID=""
MESSAGE=""
FILE_PATH=""
FILE_TYPE="document"  # document, photo, video, audio, voice, animation
PARSE_MODE=""
REPLY_TO=""
SILENT=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c, --chat-id ID      Chat ID to send to (required)
  -m, --message TEXT    Text message or caption
  -f, --file PATH       File to send
  -t, --type TYPE       File type: document|photo|video|audio|voice|animation (default: document)
  -p, --parse-mode MODE Parse mode: Markdown|MarkdownV2|HTML
  -r, --reply-to ID     Reply to message ID
  -s, --silent          Send silently (no notification)
  -T, --token TOKEN     Bot token (or set TG_BOT_TOKEN env var)
  -A, --api URL         Local API URL (default: http://127.0.0.1:8081)
  -h, --help            Show this help

Examples:
  $(basename "$0") -c 123456 -m "Hello world"
  $(basename "$0") -c 123456 -f video.mp4 -t video -m "Check this out"
  TG_BOT_TOKEN=xxx $(basename "$0") -c 123456 -f large_file.zip
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--chat-id) CHAT_ID="$2"; shift 2 ;;
        -m|--message) MESSAGE="$2"; shift 2 ;;
        -f|--file) FILE_PATH="$2"; shift 2 ;;
        -t|--type) FILE_TYPE="$2"; shift 2 ;;
        -p|--parse-mode) PARSE_MODE="$2"; shift 2 ;;
        -r|--reply-to) REPLY_TO="$2"; shift 2 ;;
        -s|--silent) SILENT="true"; shift ;;
        -T|--token) TG_BOT_TOKEN="$2"; shift 2 ;;
        -A|--api) TG_LOCAL_API="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Validate
if [[ -z "$CHAT_ID" ]]; then
    echo "Error: --chat-id is required" >&2
    exit 1
fi

if [[ -z "$TG_BOT_TOKEN" ]]; then
    echo "Error: TG_BOT_TOKEN env var or --token is required" >&2
    exit 1
fi

if [[ -z "$MESSAGE" && -z "$FILE_PATH" ]]; then
    echo "Error: --message or --file is required" >&2
    exit 1
fi

API_BASE="${TG_LOCAL_API}/bot${TG_BOT_TOKEN}"

# Build common curl args
build_common_args() {
    local args=()
    args+=(-F "chat_id=$CHAT_ID")
    [[ -n "$PARSE_MODE" ]] && args+=(-F "parse_mode=$PARSE_MODE")
    [[ -n "$REPLY_TO" ]] && args+=(-F "reply_to_message_id=$REPLY_TO")
    [[ -n "$SILENT" ]] && args+=(-F "disable_notification=true")
    echo "${args[@]}"
}

# Send text message
send_message() {
    local args
    args=$(build_common_args)
    curl -s -X POST "$API_BASE/sendMessage" \
        $args \
        -F "text=$MESSAGE"
}

# Send file
send_file() {
    local method field
    case $FILE_TYPE in
        photo) method="sendPhoto"; field="photo" ;;
        video) method="sendVideo"; field="video" ;;
        audio) method="sendAudio"; field="audio" ;;
        voice) method="sendVoice"; field="voice" ;;
        animation) method="sendAnimation"; field="animation" ;;
        *) method="sendDocument"; field="document" ;;
    esac
    
    local args
    args=$(build_common_args)
    
    # Upload via multipart - local server handles large files efficiently
    local cmd="curl -s -X POST \"$API_BASE/$method\" $args -F \"${field}=@${FILE_PATH}\""
    [[ -n "$MESSAGE" ]] && cmd+=" -F \"caption=$MESSAGE\""
    eval "$cmd"
}

# Execute
if [[ -n "$FILE_PATH" ]]; then
    if [[ ! -f "$FILE_PATH" && "$FILE_PATH" != http* ]]; then
        echo "Error: File not found: $FILE_PATH" >&2
        exit 1
    fi
    result=$(send_file)
else
    result=$(send_message)
fi

# Output result
echo "$result"

# Check for errors
if echo "$result" | grep -q '"ok":false'; then
    echo "Error sending message" >&2
    exit 1
fi
