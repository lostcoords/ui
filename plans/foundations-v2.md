# Foundations v2 and namespacing

- [x] Declare spacing, type, control, container and radius tokens in `theme.css`.
- [x] Move every component onto the tokens and remove the `var()` fallbacks from helpers.
- [x] Rename colors to shadcn names; `--card` and `--secondary` follow `--muted` and `--accent` unless set.
- [x] Prefix classes, custom properties, Stimulus identifiers and JS pins with `lc`.
- [x] Remove app-specific leftovers: sheet row and chip helpers, `pill-3d`, unused z-index slots and easings.
- [x] Ship `script/migrate_0_5.rb` and the README upgrade table.
- [x] Run tests, lint, browser checks and the docs export.

References: shadcn/ui, Radix Themes, Primer, Braid, Every Layout, RubyUI, shadcn-rails, Basecoat, Polaris ViewComponents.

## Rules

- Components never set outer margin. Layout helpers own the space between things.
- Components own their inner padding through `--lc-inset`. A card, dialog or popover pads with `p-inset` and separates its blocks with `gap-inset`.
- Every token is declared once in `theme.css`. Helpers use utilities such as `gap-related` or `text-heading`, not `var()` fallbacks.
- Type roles set size, line height, tracking and weight together.
- Controls share heights: `h-control-sm|md|lg`.
- The library owns the `lc-` prefix: CSS classes, custom properties (`--lc-*`), Stimulus identifiers (`lc-*`) and JS module pins (`lostcoords/ui/*`). Theme colors use shadcn names, so shadcn themes work.

## Knobs

| Knob | Default | Drives |
|---|---|---|
| shadcn colors | neutral | `--background --foreground --card --popover --primary --secondary --muted --accent --destructive --border --input --ring`, each with `-foreground` where shadcn defines one, plus `--success --warning` |
| `--radius` | `0.5rem` (Tailwind's own scale) | `rounded-sm` … `rounded-3xl`, `rounded-pill` |
| `--lc-density` | `1` | semantic spacing and control heights |
| `--lc-inset` | `1.25rem × density` | card, dialog, popover padding |
| `--font-sans --font-display --font-mono` | system | families |

## Spacing (`gap-*`, `p-*`, `m-*` …)

| Token | Value | Use |
|---|---|---|
| `tight` | 4px | icon and label, badge stacks |
| `related` | 8px | label and control, button groups |
| `heading` | 12px | heading and its content |
| `content` | 16px | blocks and fields |
| `inset` | `--lc-inset` | container padding and the gaps between its blocks |
| `section` | 32px | sections on a page |

## Type roles (`text-*`)

| Role | Size / line height | Weight | Use |
|---|---|---|---|
| `display` | 2.25 / 2.5rem | 700 | hero |
| `title` | 1.875 / 2.25rem | 700 | page title |
| `heading` | 1.25 / 1.75rem | 700 | section title |
| `subheading` | 1.125 / 1.5rem | 650 | card and dialog titles |
| `body` | 1 / 1.5rem | 400 | text |
| `small` | 0.875 / 1.25rem | 400 | hints and secondary text |
| `label` | 0.875 / 1.25rem | 500 | labels, buttons, menu items |
| `caption` | 0.75 / 1rem | 400 | metadata, table headers |

## Controls

| Size | Height (fine / coarse pointer) | Inline padding | Text |
|---|---|---|---|
| `sm` | 32 / 40px | 12px | `label` |
| `md` | 40 / 44px | 16px | `label` |
| `lg` | 48 / 48px | 20px | `body` |

Inputs keep 16px text so iOS does not zoom.

## Done in 0.5

- [x] Yielded parts for card, field, dialog and alert.
- [x] `Lostcoords::Ui::FormBuilder` and `lc_form_with`.
- [x] `data-slot`, `data-variant`, `data-size` and `data-tone` attributes.
- [x] Tabs, tooltip, checkbox, radio, switch, breadcrumb and description list.
- [x] Nav list, pager, skip link, link and choice cards; tooltip Escape.
- [x] The docs site uses the library throughout, with application header and documentation layout blocks.
- [x] Inputs keep the `--input` fill inside cards.

## Later

- An eject generator.
- A stronger input edge if the 1.3:1 fill proves too faint (an option, not a default yet).
