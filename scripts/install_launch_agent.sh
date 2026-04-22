#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$HOME/.codex/ppt-translator-runtime"
INBOX_DIR="$HOME/ppt-translator-inbox"
PLIST_SOURCE="$ROOT_DIR/launchd/com.junghoon.ppt-translator.translate-inbox.plist"
PLIST_TARGET="$HOME/Library/LaunchAgents/com.junghoon.ppt-translator.translate-inbox.plist"
LABEL="com.junghoon.ppt-translator.translate-inbox"

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/.run"
mkdir -p "$HOME/.codex" "$RUNTIME_DIR" "$RUNTIME_DIR/scripts" "$RUNTIME_DIR/.codex/skills" "$INBOX_DIR"

rsync -a "$ROOT_DIR/scripts/" "$RUNTIME_DIR/scripts/"
rsync -a "$ROOT_DIR/.codex/skills/ppt-translator/" "$RUNTIME_DIR/.codex/skills/ppt-translator/"
mkdir -p "$RUNTIME_DIR/logs" "$RUNTIME_DIR/.run"
ln -sfn "$INBOX_DIR" "$RUNTIME_DIR/translate-inbox"

cp "$PLIST_SOURCE" "$PLIST_TARGET"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" >/dev/null 2>&1 || true
fi

launchctl bootstrap "gui/$(id -u)" "$PLIST_TARGET"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Installed LaunchAgent: $PLIST_TARGET"
echo "Runtime directory: $RUNTIME_DIR"
echo "Inbox directory: $INBOX_DIR"
