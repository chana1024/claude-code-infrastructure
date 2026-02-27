#!/usr/bin/env python3
"""
Send status messages for long-running tasks via OpenClaw CLI.

Usage:
    python send_status.py "<message>" "<status_type>" "<step_name>" [--details "<details>"]
"""

import sys
import os
import subprocess
import json
import shutil

STATUS_EMOJIS = {
    "progress": "🔄",
    "success": "✅",
    "error": "❌",
    "warning": "⚠️"
}

def send_status(message: str, status_type: str, step_name: str, details: str = None):
    if status_type not in STATUS_EMOJIS:
        raise ValueError(f"Invalid status_type: {status_type}")
    
    emoji = STATUS_EMOJIS[status_type]
    formatted = f"{emoji} [{step_name}] {message}"
    
    if details:
        formatted += f" ({details})"
    
    # Keep under 140 chars
    if len(formatted) > 140:
        formatted = formatted[:137] + "..."
    
    # Get channel from env, default to discord
    channel = os.environ.get("CLAWDBOT_CHANNEL", "discord")
    target = os.environ.get("DISCORD_TARGET", os.environ.get("DISCORD_CHANNEL", ""))
    
    # If no target, try to get from OpenClaw config
    if not target:
        # Use the current Discord channel from the session
        target = os.environ.get("OPENCLAW_DISCORD_CHANNEL", "1468731474344935650")
    
    # Try OpenClaw CLI
    openclaw_path = shutil.which("openclaw")
    
    if openclaw_path and target:
        try:
            result = subprocess.run(
                ["openclaw", "message", "send", 
                 "--channel", channel,
                 "--target", target,
                 "--message", formatted],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                print(f"Status sent: {formatted}")
                return formatted
            else:
                print(f"CLI failed: {result.stderr}", file=sys.stderr)
        except Exception as e:
            print(f"CLI error: {e}", file=sys.stderr)
    
    # Fallback: just print
    print(formatted)
    return formatted

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: send_status.py <message> <status_type> <step_name>")
        sys.exit(1)
    
    message = sys.argv[1]
    status_type = sys.argv[2]
    step_name = sys.argv[3]
    details = sys.argv[4] if len(sys.argv) > 4 else None
    
    send_status(message, status_type, step_name, details)

def can_encode_emoji(text: str, encoding: str = None) -> bool:
    if encoding is None:
        encoding = sys.stdout.encoding
    try:
        text.encode(encoding)
        return True
    except (UnicodeEncodeError, LookupError):
        return False
