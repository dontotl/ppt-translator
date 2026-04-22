"""Command line interface for the PPT translator."""
from __future__ import annotations

import argparse
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Sequence

from .providers import ProviderConfigurationError, create_provider, list_providers
from .translation import TranslationService
from .pipeline import process_ppt_file
from .utils import clean_path, iter_presentation_files


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Translate PowerPoint decks using modern LLM providers.")
    parser.add_argument("path", help="Path to a PPT/PPTX file or a directory containing presentations.")
    parser.add_argument("--source-lang", default="zh", help="Source language code (default: zh).")
    parser.add_argument("--target-lang", default="en", help="Target language code (default: en).")
    parser.add_argument(
        "--provider",
        default="openai",
        choices=list_providers(),
        help="Model provider to use for translation.",
    )
    parser.add_argument("--model", help="Optional model override for the chosen provider.")
    parser.add_argument(
        "--max-chunk-size",
        type=int,
        default=1000,
        help="Maximum characters per translation request.",
    )
    parser.add_argument(
        "--max-workers",
        type=int,
        default=4,
        help="Number of worker threads used while reading slides.",
    )
    parser.add_argument(
        "--max-file-workers",
        type=int,
        default=1,
        help="Number of presentations to translate in parallel when the path is a directory.",
    )
    parser.add_argument(
        "--skip-existing-translated",
        action="store_true",
        help="Skip files that are already translated or already have a sibling translated output.",
    )
    parser.add_argument(
        "--keep-intermediate",
        action="store_true",
        help="Keep intermediate XML files instead of deleting them.",
    )
    return parser


def build_translation_service(
    provider_name: str,
    *,
    model: str | None,
    max_chunk_size: int,
) -> TranslationService:
    """Create a translation service instance for one presentation worker."""
    provider = create_provider(provider_name, model=model)
    return TranslationService(provider, max_chunk_size=max_chunk_size)


def is_translated_output(path: Path) -> bool:
    """Return whether *path* looks like a generated translated deck."""
    return path.stem.endswith("_translated")


def translated_output_path(path: Path) -> Path:
    """Return the output path used for the translated presentation."""
    return path.parent / f"{path.stem}_translated{path.suffix}"


def select_files(files: list[Path], *, skip_existing_translated: bool) -> list[Path]:
    """Filter and sort candidate files for deterministic processing."""
    selected = sorted(files)
    if not skip_existing_translated:
        return selected
    return [
        path
        for path in selected
        if not is_translated_output(path) and not translated_output_path(path).exists()
    ]


def process_file(
    ppt_file: Path,
    *,
    provider_name: str,
    model: str | None,
    max_chunk_size: int,
    source_lang: str,
    target_lang: str,
    max_workers: int,
    keep_intermediate: bool,
) -> Path | None:
    """Translate a single presentation file."""
    translator = build_translation_service(
        provider_name,
        model=model,
        max_chunk_size=max_chunk_size,
    )
    return process_ppt_file(
        ppt_file,
        translator=translator,
        source_lang=source_lang,
        target_lang=target_lang,
        max_workers=max_workers,
        cleanup=not keep_intermediate,
    )


def run_cli(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    target_path = Path(clean_path(args.path)).expanduser().resolve()

    try:
        build_translation_service(
            args.provider,
            model=args.model,
            max_chunk_size=args.max_chunk_size,
        )
    except ProviderConfigurationError as exc:
        parser.error(str(exc))
    except ValueError as exc:
        parser.error(str(exc))

    files = select_files(
        list(iter_presentation_files(target_path)),
        skip_existing_translated=args.skip_existing_translated,
    )
    if not files:
        print("No PowerPoint files were found at the provided location.")
        return 1

    exit_code = 0
    file_workers = max(1, args.max_file_workers)

    if file_workers == 1 or len(files) == 1:
        for ppt_file in files:
            try:
                result = process_file(
                    ppt_file,
                    provider_name=args.provider,
                    model=args.model,
                    max_chunk_size=args.max_chunk_size,
                    source_lang=args.source_lang,
                    target_lang=args.target_lang,
                    max_workers=args.max_workers,
                    keep_intermediate=args.keep_intermediate,
                )
                if result is None:
                    exit_code = 1
            except Exception as exc:  # pragma: no cover - CLI logging
                print(f"Error processing {ppt_file}: {exc}")
                exit_code = 1
        return exit_code

    worker_count = min(file_workers, len(files))
    print(f"Processing {len(files)} presentation(s) with {worker_count} parallel file worker(s).")
    with ThreadPoolExecutor(max_workers=worker_count) as executor:
        future_to_file = {
            executor.submit(
                process_file,
                ppt_file,
                provider_name=args.provider,
                model=args.model,
                max_chunk_size=args.max_chunk_size,
                source_lang=args.source_lang,
                target_lang=args.target_lang,
                max_workers=args.max_workers,
                keep_intermediate=args.keep_intermediate,
            ): ppt_file
            for ppt_file in files
        }
        for future in as_completed(future_to_file):
            ppt_file = future_to_file[future]
            try:
                result = future.result()
                if result is None:
                    exit_code = 1
            except Exception as exc:  # pragma: no cover - CLI logging
                print(f"Error processing {ppt_file}: {exc}")
                exit_code = 1
    return exit_code


def main() -> None:
    sys.exit(run_cli())
