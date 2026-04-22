#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX_DIR="$ROOT_DIR/translate-inbox"
SKILL_SCRIPTS_DIR="$ROOT_DIR/.codex/skills/ppt-translator/scripts"
TRANSLATE_SCRIPT="$SKILL_SCRIPTS_DIR/translate_ppt.sh"
STATE_DIR="$ROOT_DIR/.run"
LOCK_DIR="$STATE_DIR/translate-inbox.lock"
LOG_DIR="$ROOT_DIR/logs"

mkdir -p "$STATE_DIR" "$LOG_DIR"

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log() {
  printf "[%s] %s\n" "$(timestamp)" "$*"
}

if [ ! -d "$INBOX_DIR" ]; then
  log "Inbox directory not found: $INBOX_DIR"
  exit 0
fi

if [ ! -x "$TRANSLATE_SCRIPT" ]; then
  log "Translator script not found or not executable: $TRANSLATE_SCRIPT"
  exit 1
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Another translation run is already in progress."
  exit 0
fi

cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

trap cleanup EXIT

pending_files=()
while IFS= read -r -d '' file; do
  base_name="$(basename "$file")"
  stem="${base_name%.*}"
  extension=".${base_name##*.}"
  if [[ "$stem" == *_translated ]]; then
    continue
  fi
  translated_path="$(dirname "$file")/${stem}_translated${extension}"
  if [ -f "$translated_path" ]; then
    continue
  fi
  pending_files+=("$file")
done < <(find -L "$INBOX_DIR" -type f \( -iname "*.ppt" -o -iname "*.pptx" \) -print0)

if [ "${#pending_files[@]}" -eq 0 ]; then
  log "No pending presentations found."
  exit 0
fi

log "Found ${#pending_files[@]} pending presentation(s)."
for file in "${pending_files[@]}"; do
  log "Pending: $file"
done

cd "$SKILL_SCRIPTS_DIR"
"$TRANSLATE_SCRIPT" \
  "$INBOX_DIR" \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3

log "Translation run completed."
