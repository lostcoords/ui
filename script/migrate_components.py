#!/usr/bin/env python3
"""Rename consolidated component calls in source. Dry run unless --write is passed.

Review layout classes and options after migration; see README.md for the new API.
"""
import argparse
from pathlib import Path
import re

RENAMES = {
    'lc_icon_medallion_class': 'lc_icon_badge_class',
    'lc_medallion': 'lc_icon_badge',
    'lc_status_pill_class': 'lc_badge_class',
    'lc_status_pill': 'lc_badge',
    'lc_form_card_class': 'lc_card_class',
    'lc_form_card': 'lc_card',
    'lc_card_surface_class': 'lc_card_class',
    'lc_card_surface': 'lc_card',
    'lc_form_actions_class': 'lc_inline_class',
    'lc_form_actions': 'lc_inline',
    'lc_pill_row_class': 'lc_inline_class',
    'lc_pill_row': 'lc_inline',
    'lc_pill_class': 'lc_toggle_class',
    'lc_pill': 'lc_toggle',
    'lc_segmented_tab_class': 'lc_toggle_group_item_class',
    'lc_segmented_tab': 'lc_toggle_group_item',
    'lc_segmented_class': 'lc_toggle_group_class',
    'lc_segmented': 'lc_toggle_group',
    'lc_form_alert_class': 'lc_alert_class',
    'lc_form_alert_icon': 'lc_alert_icon',
    'lc_form_alert': 'lc_alert',
    'lc_disclosure': 'lc_collapsible',
    'lc_sheet': 'lc_dialog',
}
NAMES = re.compile(r'\b(' + '|'.join(sorted(RENAMES, key=len, reverse=True)) + r')\b')


def migrate(source, suffix):
    if suffix == '.erb':
        def icon(match):
            args = match[1]
            additions = []
            for key, value in [('shape', ':circle'), ('tone', ':primary'), ('size', ':sm')]:
                if not re.search(r'\b' + key + r':', args):
                    additions.append(f'{key}: {value}')
            return 'lc_icon_badge ' + ', '.join(additions + [args.strip()])
        source = re.sub(r'\blc_medallion\s+([^\n%]+)', icon, source)
        source = re.sub(r'\blc_status_pill\s+([^\n%]+)', lambda m: 'lc_badge ' + m[1].rstrip() + ('' if 'tone:' in m[1] else ', tone: :primary') + ('' if 'class:' in m[1] else ', class: "rounded-full text-sm"') + ' ', source)
        source = re.sub(r'\blc_card_surface\s+do\b', 'lc_card padding: :none do', source)
        source = re.sub(r'\blc_card_surface\s+', 'lc_card padding: :none, ', source)
        source = re.sub(r'\blc_form_actions\s+do\b', 'lc_inline class: "justify-end" do', source)
        source = re.sub(r'\blc_eyebrow\s+([^\n%]+)', lambda m: 'lc_text ' + m[1].rstrip() + ', size: :caption, tone: :muted ', source)
    source = NAMES.sub(lambda m: RENAMES[m[1]], source)
    source = re.sub(r'\btone:\s*:(error|notice|info)\b', lambda m: 'tone: :' + {'error': 'danger', 'notice': 'success', 'info': 'primary'}[m[1]], source)
    source = source.replace('dense: true', 'padding: :compact')
    return source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('paths', nargs='+', type=Path)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    files = set()
    for path in args.paths:
        files.update(path.rglob('*') if path.is_dir() else [path])
    changed = []
    for path in sorted(files):
        if path.is_symlink() or not path.is_file() or path.suffix not in {'.rb', '.erb', '.js', '.md'}:
            continue
        if any(part in {'.git', '.jj', 'node_modules', 'vendor', 'builds', 'tmp', 'log'} for part in path.parts):
            continue
        source = path.read_text()
        updated = migrate(source, path.suffix)
        if source != updated:
            changed.append(str(path))
            if args.write:
                path.write_text(updated)
    print('\n'.join(changed))
    print(f'{len(changed)} files {"updated" if args.write else "would change"}')


if __name__ == '__main__':
    main()
