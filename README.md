# PPT Translator Workspace

This workspace wraps the `ppt-translator` skill with a local inbox folder and a macOS `launchd` job so new decks can be translated to Korean automatically.

Because macOS background agents often cannot access files under `Documents` without additional privacy permissions, the installed `launchd` runtime is mirrored under `~/.codex/ppt-translator-runtime` and watches a user-facing inbox at `~/ppt-translator-inbox`.

## Components

There are two layers in this setup:

1. `ppt-translator` skill
   - The actual translation toolchain.
   - Lives under `.codex/skills/ppt-translator/`.
   - Knows how to read `.ppt/.pptx`, call the model provider, and rebuild a translated `.pptx`.

2. `launchd` automation
   - The macOS scheduler around the skill.
   - Runs every 10 minutes.
   - Scans the inbox folder and invokes the skill only for files that do not already have translated output.

In short: `launchd` is the scheduler, and `ppt-translator` is the translator.

For a more implementation-focused walkthrough, see [docs/skill-and-automation.md](/Users/junghoon/Documents/New%20project/ppt-translator/docs/skill-and-automation.md).

## Paths

- Workspace root: `/Users/junghoon/Documents/New project/ppt-translator`
- User inbox folder: `/Users/junghoon/ppt-translator-inbox`
- Runtime mirror: `/Users/junghoon/.codex/ppt-translator-runtime`
- Translator entrypoint: `/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts/translate_ppt.sh`
- Skill instructions: `/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/SKILL.md`
- Skill `.env`: `/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts/.env`
- LaunchAgent plist template: `/Users/junghoon/Documents/New project/ppt-translator/launchd/com.junghoon.ppt-translator.translate-inbox.plist`
- LaunchAgent installed path: `~/Library/LaunchAgents/com.junghoon.ppt-translator.translate-inbox.plist`

## What It Does

- Scans `~/ppt-translator-inbox` every 10 minutes.
- Skips files already ending in `_translated.ppt` or `_translated.pptx`.
- Skips source decks that already have a sibling `{stem}_translated.pptx`.
- Runs the translator with:
  - provider: `openai`
  - source language: `auto`
  - target language: `ko`
  - file parallelism: `--max-file-workers 3`
- Uses a lock directory so overlapping runs do not pile up.
- Writes runtime logs into `logs/`.

## How The Skill Is Used

You can use the skill in two ways.

### 1. Direct manual use

This is the normal “translate this file now” workflow.

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"

./translate_ppt.sh "/absolute/path/to/file.pptx" \
  --provider openai \
  --source-lang auto \
  --target-lang ko
```

For a whole folder:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"

./translate_ppt.sh "/absolute/path/to/folder" \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3
```

### 2. Automatic inbox use

This is the background workflow.

- You put `.ppt` or `.pptx` files into `~/ppt-translator-inbox`.
- `launchd` wakes up every 10 minutes.
- It runs `run_translate_inbox.sh`.
- That script calls the skill's `translate_ppt.sh`.
- The skill generates `{stem}_translated.pptx` next to the source deck.

## Setup From Scratch

Follow this once on a new machine or after resetting the workspace.

### 1. Bootstrap the skill

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
./bootstrap.sh
```

### 2. Configure the provider key

If `.env` does not exist yet:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
cp example.env .env
```

Then edit:

- `/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts/.env`

Required for the current setup:

- `OPENAI_API_KEY=...`

### 3. Install the 10-minute macOS automation

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator"
./scripts/install_launch_agent.sh
```

### 4. Put files into the inbox

Put source files here:

- `/Users/junghoon/ppt-translator-inbox`

Translated files will be created in the same folder.

## Required Setup

1. Ensure the virtual environment is bootstrapped:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
./bootstrap.sh
```

2. Ensure the API key is present:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
grep '^OPENAI_API_KEY=' .env
```

## Install The LaunchAgent

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator"
./scripts/install_launch_agent.sh
```

This installs and starts:

- label: `com.junghoon.ppt-translator.translate-inbox`
- interval: every 600 seconds
- runtime: `~/.codex/ppt-translator-runtime`
- inbox: `~/ppt-translator-inbox`

## How Both Pieces Work Together

The control flow is:

1. `launchd` starts `/Users/junghoon/.codex/ppt-translator-runtime/scripts/run_translate_inbox.sh`
2. `run_translate_inbox.sh` scans `~/ppt-translator-inbox`
3. If pending files exist, it calls the copied skill runtime under `~/.codex/ppt-translator-runtime/.codex/skills/ppt-translator/scripts/translate_ppt.sh`
4. `translate_ppt.sh` loads `.env`, starts the Python CLI, and runs the translator
5. The translator generates Korean output and cleans up temporary XML on failure

The workspace copy remains the source of truth that you edit.
The runtime copy under `~/.codex/ppt-translator-runtime` is the background-safe mirror used by `launchd`.

## Stop Or Remove It

To unload and remove the macOS agent:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator"
./scripts/uninstall_launch_agent.sh
```

## Logs

- stdout: `/Users/junghoon/.codex/ppt-translator-runtime/logs/translate-inbox.stdout.log`
- stderr: `/Users/junghoon/.codex/ppt-translator-runtime/logs/translate-inbox.stderr.log`

Useful checks:

```bash
tail -f "/Users/junghoon/.codex/ppt-translator-runtime/logs/translate-inbox.stdout.log"
tail -f "/Users/junghoon/.codex/ppt-translator-runtime/logs/translate-inbox.stderr.log"
launchctl print "gui/$(id -u)/com.junghoon.ppt-translator.translate-inbox"
```

## Manual Run

To test the same workflow without waiting for the next 10-minute window:

```bash
~/.codex/ppt-translator-runtime/scripts/run_translate_inbox.sh
```

To test the skill directly without the scheduler:

```bash
cd "/Users/junghoon/Documents/New project/ppt-translator/.codex/skills/ppt-translator/scripts"
./translate_ppt.sh "/Users/junghoon/ppt-translator-inbox" \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3
```

## Notes

- `launchd` is used here because app heartbeat automation could not reach the translation API from its sandboxed network environment.
- The installed LaunchAgent does not run directly from `Documents`; it runs from the mirrored runtime under `~/.codex/ppt-translator-runtime` to avoid macOS privacy restrictions on background jobs.
- This workspace also had an app cron automation before switching to `launchd`; keep `launchd` as the single active scheduler to avoid duplicate runs.
- Successful and failed translation runs both clean up XML intermediates automatically.
