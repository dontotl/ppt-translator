#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
USER_NAME="$(id -un)"
RUNTIME_DIR="${PPT_TRANSLATOR_RUNTIME_DIR:-$HOME/.codex/ppt-translator-runtime}"
INBOX_DIR="${PPT_TRANSLATOR_INBOX_DIR:-$HOME/ppt-translator-inbox}"
LABEL="${PPT_TRANSLATOR_LAUNCH_LABEL:-com.${USER_NAME}.ppt-translator.translate-inbox}"
INTERVAL_SECONDS="${PPT_TRANSLATOR_INTERVAL_SECONDS:-600}"
PROVIDER="${PPT_TRANSLATOR_PROVIDER:-openai}"
SOURCE_LANG="${PPT_TRANSLATOR_SOURCE_LANG:-auto}"
TARGET_LANG="${PPT_TRANSLATOR_TARGET_LANG:-ko}"
MAX_FILE_WORKERS="${PPT_TRANSLATOR_MAX_FILE_WORKERS:-3}"
PLIST_SOURCE="$ROOT_DIR/launchd/com.ppt-translator.translate-inbox.plist"
PLIST_TARGET="$HOME/Library/LaunchAgents/${LABEL}.plist"
RUN_SCRIPT="$RUNTIME_DIR/scripts/run_translate_inbox.sh"
STDOUT_PATH="$RUNTIME_DIR/logs/translate-inbox.stdout.log"
STDERR_PATH="$RUNTIME_DIR/logs/translate-inbox.stderr.log"
PATH_VALUE="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

mkdir -p "$HOME/Library/LaunchAgents"
mkdir -p "$ROOT_DIR/logs" "$ROOT_DIR/.run"
mkdir -p "$HOME/.codex" "$RUNTIME_DIR" "$RUNTIME_DIR/scripts" "$RUNTIME_DIR/.codex/skills" "$INBOX_DIR"

rsync -a "$ROOT_DIR/scripts/" "$RUNTIME_DIR/scripts/"
rsync -a "$ROOT_DIR/.codex/skills/ppt-translator/" "$RUNTIME_DIR/.codex/skills/ppt-translator/"
mkdir -p "$RUNTIME_DIR/logs" "$RUNTIME_DIR/.run"
ln -sfn "$INBOX_DIR" "$RUNTIME_DIR/translate-inbox"

sed \
  -e "s|__LABEL__|$LABEL|g" \
  -e "s|__RUN_SCRIPT__|$RUN_SCRIPT|g" \
  -e "s|__WORKING_DIRECTORY__|$RUNTIME_DIR|g" \
  -e "s|__START_INTERVAL__|$INTERVAL_SECONDS|g" \
  -e "s|__STDOUT_PATH__|$STDOUT_PATH|g" \
  -e "s|__STDERR_PATH__|$STDERR_PATH|g" \
  -e "s|__PATH_VALUE__|$PATH_VALUE|g" \
  -e "s|__PROVIDER__|$PROVIDER|g" \
  -e "s|__SOURCE_LANG__|$SOURCE_LANG|g" \
  -e "s|__TARGET_LANG__|$TARGET_LANG|g" \
  -e "s|__MAX_FILE_WORKERS__|$MAX_FILE_WORKERS|g" \
  "$PLIST_SOURCE" > "$PLIST_TARGET"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" >/dev/null 2>&1 || true
fi

launchctl bootstrap "gui/$(id -u)" "$PLIST_TARGET"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Installed LaunchAgent: $PLIST_TARGET"
echo "Runtime directory: $RUNTIME_DIR"
echo "Inbox directory: $INBOX_DIR"
echo "Provider: $PROVIDER"
echo "Source language: $SOURCE_LANG"
echo "Target language: $TARGET_LANG"
echo "Interval seconds: $INTERVAL_SECONDS"
