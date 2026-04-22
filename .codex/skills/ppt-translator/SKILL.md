---
name: ppt-translator
description: Translate `.ppt` and `.pptx` files while preserving formatting such as fonts, colors, alignment, and tables. Supports OpenAI, Anthropic, DeepSeek, Grok, and Gemini. Use when a user wants a presentation translated without breaking slide layout, especially for CJK to or from English.
license: MIT - see LICENSE.txt
---

# PPT Translator

Translate PowerPoint presentations while preserving layout, fonts, colors, spacing, table styling, and alignment.

## When to Use This Skill

- Translating a single `.ppt` or `.pptx` deck
- Batch translating a directory of presentations
- Preserving formatting during CJK ↔ English translation
- Inspecting extracted or translated XML with `--keep-intermediate`

## Workflow

1. Work from `.codex/skills/ppt-translator/scripts`.
2. Run `./bootstrap.sh` before first use or after dependency changes.
3. Ensure the selected provider API key is available in the shell or `scripts/.env`.
4. Run `./translate_ppt.sh` with an absolute file or directory path.
5. Return the generated `*_translated.pptx` file path to the user.

## Setup

```bash
cd .codex/skills/ppt-translator/scripts
./bootstrap.sh
cp example.env .env
# Edit .env with the provider key(s) you plan to use
```

## Basic Usage

```bash
cd .codex/skills/ppt-translator/scripts

./translate_ppt.sh /path/to/presentation.pptx \
  --provider openai \
  --source-lang ko \
  --target-lang en
```

Directory queues can be processed in parallel at the file level:

```bash
cd .codex/skills/ppt-translator/scripts

./translate_ppt.sh /path/to/folder \
  --provider openai \
  --source-lang auto \
  --target-lang ko \
  --skip-existing-translated \
  --max-file-workers 3
```

## Provider Configuration

- `openai`: `OPENAI_API_KEY`
- `anthropic`: `ANTHROPIC_API_KEY`
- `deepseek`: `DEEPSEEK_API_KEY`
- `grok`: `GROK_API_KEY`
- `gemini`: `GEMINI_API_KEY`

## CLI Reference

- `--provider`: `openai`, `anthropic`, `deepseek`, `grok`, `gemini`
- `--model`: override the provider default
- `--source-lang` and `--target-lang`: ISO 639-1 language codes, with `auto` source detection supported
- `--max-chunk-size`: per-request character cap, default `1000`
- `--max-workers`: slide extraction worker count, default `4`
- `--max-file-workers`: number of presentations to translate in parallel for directory inputs, default `1`
- `--skip-existing-translated`: ignore `*_translated` decks and sources that already have translated output
- `--keep-intermediate`: keep generated XML for debugging

## Output Files

- `{deck}_original.xml`
- `{deck}_translated.xml`
- `{deck}_translated.pptx`

## Design Notes

- Fonts are scaled down during replacement to reduce overflow risk after translation.
- Repeated strings are cached to avoid duplicate model calls.
- Long text is chunked at sentence boundaries before provider requests.

## Troubleshooting

- If the provider key is missing, populate `scripts/.env` or export the variable in the shell.
- If formatting looks off, rerun with `--keep-intermediate` and inspect the XML output.
- If long blocks fail or truncate, lower `--max-chunk-size` or switch providers.
