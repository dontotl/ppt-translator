#!/usr/bin/env bash
set -euo pipefail

PLIST_TARGET="$HOME/Library/LaunchAgents/com.junghoon.ppt-translator.translate-inbox.plist"
LABEL="com.junghoon.ppt-translator.translate-inbox"

if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_TARGET" >/dev/null 2>&1 || true
fi

rm -f "$PLIST_TARGET"

echo "Removed LaunchAgent: $PLIST_TARGET"
echo "Runtime files remain at: $HOME/.codex/ppt-translator-runtime"
