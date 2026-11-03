#!/usr/bin/env python3
"""Rename legacy theme colors in authored source. Dry run unless --write is passed."""
import argparse
from pathlib import Path
import re

COLORS = {
    'paper': 'background', 'paper-2': 'surface', 'paper-3': 'surface-hover',
    'ink': 'foreground', 'ink-2': 'muted', 'ink-3': 'muted',
    'ink-on-accent': 'on-primary', 'hairline': 'border',
    'sky': 'primary', 'sky-deep': 'primary', 'sky-soft': 'primary-soft',
    'accent': 'primary', 'leaf': 'success', 'leaf-soft': 'success-soft',
    'gold': 'warning', 'gold-soft': 'warning-soft',
    'berry': 'danger', 'berry-soft': 'danger-soft',
}
NAMES = '|'.join(re.escape(name) for name in sorted(COLORS, key=len, reverse=True))
VARIABLE = re.compile(r'--(color-)?(' + NAMES + r')(?![\w-])')
UTILITY = re.compile(r'\b(bg|text|border|divide|ring|outline|fill|stroke|decoration|shadow|from|via|to|caret|accent)-(' + NAMES + r')(?![\w-])')
OPTIONS = {'accent': 'primary', 'leaf': 'success', 'subtle': 'muted'}
OPTION = re.compile(r':(accent|leaf|subtle)\b|(?<![\w-])(accent|leaf|subtle):(?=\s)')


def migrate(source):
    source = VARIABLE.sub(lambda m: '--' + (m[1] or '') + COLORS[m[2]], source)
    source = UTILITY.sub(lambda m: m[1] + '-' + COLORS[m[2]], source)
    source = OPTION.sub(lambda m: ':' + OPTIONS[m[1]] if m[1] else OPTIONS[m[2]] + ':', source)
    source = re.sub(
        r'(--(?:color-)?(?:primary|primary-soft|muted|danger|danger-soft))\s*:\s*var\(\s*\1\s*\)\s*;?',
        '', source,
    )
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('paths', nargs='+', type=Path)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    paths = set()
    for path in args.paths:
        paths.update(path.rglob('*') if path.is_dir() else [path])
    changed = []
    for path in sorted(paths):
        if path.is_symlink() or not path.is_file() or path.suffix not in {'.css', '.rb', '.erb', '.js', '.md'}:
            continue
        if any(part in {'.git', '.jj', 'node_modules', 'vendor', 'builds', 'tmp', 'log'} for part in path.parts):
            continue
        source = path.read_text()
        updated = migrate(source)
        if source != updated:
            changed.append(str(path))
            if args.write:
                path.write_text(updated)
    print('\n'.join(changed))
    print(f'{len(changed)} files {"updated" if args.write else "would change"}')


if __name__ == '__main__':
    main()
