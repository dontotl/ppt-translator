#!/usr/bin/env bash
set -euo pipefail

USER_NAME="$(id -un)"
LABEL="${PPT_TRANSLATOR_LAUNCH_LABEL:-com.${USER_NAME}.ppt-translator.translate-inbox}"
PLIST_TARGET="$HOME/Library/LaunchAgents/${LABEL}.plist"
RUNTIME_DIR="${PPT_TRANSLATOR_RUNTIME_DIR:-$HOME/.codex/ppt-translator-runtime}"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" >/dev/null 2>&1 || true
fi

rm -f "$PLIST_TARGET"

echo "Removed LaunchAgent: $PLIST_TARGET"
echo "Runtime files remain at: $RUNTIME_DIR"
