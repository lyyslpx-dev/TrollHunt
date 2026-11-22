#!/usr/bin/env python3
"""Prepare the iOS export preset for an unsigned CI build.

The iOS exporter can emit an Xcode project without building an IPA when
application/export_project_only=true. The workflow sets that option here
instead of relying on every developer's local export_presets.cfg.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

PRESET_HEADER = re.compile(r"^\[preset\.(\d+)\]\s*$")
OPTIONS_HEADER = re.compile(r"^\[preset\.(\d+)\.options\]\s*$")
NAME_LINE = re.compile(r'^name\s*=\s*"(.*)"\s*$')
EXPORT_ONLY_LINE = re.compile(r"^application/export_project_only\s*=")
ENCRYPT_PCK_LINE = re.compile(r"^encrypt_pck\s*=\s*true\s*$", re.IGNORECASE)
ENCRYPT_DIR_LINE = re.compile(r"^encrypt_directory\s*=\s*true\s*$", re.IGNORECASE)


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def preset_indices(lines: list[str]) -> list[int]:
    indices = set()
    for line in lines:
        match = PRESET_HEADER.match(line.strip())
        if match:
            indices.add(int(match.group(1)))
    return sorted(indices)


def block_range(lines: list[str], index: int) -> tuple[int, int]:
    start = None
    for number, line in enumerate(lines):
        match = PRESET_HEADER.match(line.strip())
        if match and int(match.group(1)) == index:
            start = number
            break
    if start is None:
        fail(f"[preset.{index}] is missing")

    end = len(lines)
    for number in range(start + 1, len(lines)):
        if PRESET_HEADER.match(lines[number].strip()):
            end = number
            break
    return start, end


def find_preset(lines: list[str], name: str) -> tuple[int, int, int]:
    available: list[str] = []
    for index in preset_indices(lines):
        start, end = block_range(lines, index)
        preset_name = ""
        for line in lines[start:end]:
            match = NAME_LINE.match(line.strip())
            if match:
                preset_name = match.group(1)
                break
        if preset_name:
            available.append(f"{index}={preset_name!r}")
        if preset_name == name:
            return index, start, end

    names = ", ".join(available) if available else "none"
    fail(f'No export preset named "{name}" was found (available: {names})')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="export_presets.cfg")
    parser.add_argument("--preset-name", default="iOS")
    args = parser.parse_args()

    path = Path(args.config)
    if not path.is_file():
        fail(f"{path} does not exist")

    lines = path.read_text(encoding="utf-8").splitlines()
    index, start, end = find_preset(lines, args.preset_name)

    options_start = None
    for number in range(start, end):
        match = OPTIONS_HEADER.match(lines[number].strip())
        if match and int(match.group(1)) == index:
            options_start = number
            break
    if options_start is None:
        fail(f"[preset.{index}.options] is missing for preset {args.preset_name!r}")

    for line in lines[start:end]:
        stripped = line.strip()
        if ENCRYPT_PCK_LINE.match(stripped):
            fail("encrypt_pck=true is not allowed; PCK encryption must stay off")
        if ENCRYPT_DIR_LINE.match(stripped):
            fail("encrypt_directory=true is not allowed; PCK encryption must stay off")

    changed = False
    for number in range(options_start + 1, end):
        if EXPORT_ONLY_LINE.match(lines[number].strip()):
            if lines[number].strip() != "application/export_project_only=true":
                lines[number] = "application/export_project_only=true"
                changed = True
            break
    else:
        lines.insert(options_start + 1, "application/export_project_only=true")
        changed = True

    if changed:
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f'Preset "{args.preset_name}" (preset.{index}) is configured for Xcode-project-only export.')


if __name__ == "__main__":
    main()
