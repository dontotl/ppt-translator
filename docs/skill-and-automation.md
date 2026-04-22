# Skill And Automation Guide

This document explains how the `ppt-translator` skill and the macOS `launchd` automation fit together in this workspace.

## Overview

The setup has two distinct responsibilities:

- The skill translates PowerPoint files while preserving layout and formatting.
- The automation watches an inbox folder and invokes the skill every 10 minutes.

The translator itself lives in:

- `.codex/skills/ppt-translator/`

The automation wrapper lives in:

- `scripts/run_translate_inbox.sh`
- `scripts/install_launch_agent.sh`
- `scripts/uninstall_launch_agent.sh`
- `launchd/com.junghoon.ppt-translator.translate-inbox.plist`

## Skill Layout

Main files inside the skill:

- `.codex/skills/ppt-translator/SKILL.md`
- `.codex/skills/ppt-translator/scripts/translate_ppt.sh`
- `.codex/skills/ppt-translator/scripts/main.py`
- `.codex/skills/ppt-translator/scripts/ppt_translator/`

Important behavior:

- Supports single-file and directory translation.
- Uses `auto -> ko` translation in the current automation setup.
- Can process multiple files in parallel with `--max-file-workers`.
- Cleans up temporary XML files automatically after both success and failure.

## Automation Flow

The macOS scheduler is `launchd`.

Flow:

1. `launchd` runs every 600 seconds.
2. It starts `~/.codex/ppt-translator-runtime/scripts/run_translate_inbox.sh`.
3. That script scans `~/ppt-translator-inbox`.
4. It skips files that already have a sibling `*_translated.pptx`.
5. It calls the mirrored skill runtime to translate pending files.
6. Translated PPTX files are written back into `~/ppt-translator-inbox`.

## Why A Mirrored Runtime Exists

The editable project lives under `Documents`, but macOS background agents can run into privacy restrictions there.

To avoid that:

- The editable source stays in this repository.
- The install script mirrors the runnable files into `~/.codex/ppt-translator-runtime`.
- `launchd` executes the mirrored copy instead of the `Documents` copy.

This keeps the repo easy to edit while letting the background job run reliably.

## Manual Commands

Run the skill directly:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
./translate_ppt.sh "/absolute/path/to/file-or-folder" \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3
```

Run the inbox workflow once:

```bash
~/.codex/ppt-translator-runtime/scripts/run_translate_inbox.sh
```

Install the 10-minute scheduler:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator"
./scripts/install_launch_agent.sh
```

Remove it:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator"
./scripts/uninstall_launch_agent.sh
```

## Files You Usually Edit

- `README.md`
- `docs/skill-and-automation.md`
- `scripts/run_translate_inbox.sh`
- `launchd/com.junghoon.ppt-translator.translate-inbox.plist`
- `.codex/skills/ppt-translator/SKILL.md`
- `.codex/skills/ppt-translator/scripts/ppt_translator/*.py`

## Files You Usually Do Not Commit

- `.codex/skills/ppt-translator/scripts/.env`
- `.codex/skills/ppt-translator/scripts/.venv/`
- `translate-inbox/`
- `logs/`
- runtime output created under `~/.codex/ppt-translator-runtime`
