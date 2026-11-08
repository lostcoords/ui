# lostcoords-ui

Render complete UI components from Rails views. Helpers include semantic HTML, accessible attributes and
Stimulus wiring. Tailwind v4 supplies the styles. The Rails engine integrates Propshaft, importmap and
`tailwindcss-rails`.

```erb
<%= lc_button "Save changes", type: :submit, icon: "check" %>
<%= lc_button_link_to "Projects", projects_path, variant: :secondary %>

<%= lc_card do %>
  <%= lc_field label: "Project name", id: "project-name" do |field| %>
    <%= lc_input name: "project[name]", **field %>
  <% end %>
<% end %>
```

The supported stack is Rails 8 or later with ERB, Tailwind and Stimulus. Each host application's
lockfile pins its gem version, so publishing a library update does not upgrade consumers.

## Install

```ruby
gem "lostcoords-ui", "~> 0.9.1"
```

The engine adds its rendering helpers to host views, its views and translations to the host's lookup
paths, its JavaScript to the asset paths and its pins to the importmap. Translations live under
`lostcoords.ui.*`; a host locale file overrides any of them.

### Stylesheets

Import the engine's stylesheet after your Tailwind imports. `tailwindcss-rails` generates this path from
the installed gem on every build:

```css
/* app/assets/tailwind/application.css */
@import "../builds/tailwind/lostcoords_ui.css";
```

Tailwind always ships component rules, used or not, and generates every utility the scanned helpers
mention. For a smaller build, import `core.css` and the opt-in components you render instead of
everything. Each entry carries the rules and scans the sources of its own component only. Every
Tailwind build writes stable paths for them next to the engine's own import:

```css
/* app/assets/tailwind/application.css, instead of ../builds/tailwind/lostcoords_ui.css */
@import "../builds/tailwind/lostcoords_ui/base.css";
@import "../builds/tailwind/lostcoords_ui/core.css";
@import "../builds/tailwind/lostcoords_ui/components/dialog.css";
@import "../builds/tailwind/lostcoords_ui/components/menu.css";
```

`base.css` holds the document defaults: body styles, heading defaults, global inline-code styles and
document corner radii. Skip it when the host owns its base styles, map the library's tokens to your
app's theme and keep your Tailwind theme declarations after the imports.
`core.css` holds the tokens, buttons, badges, avatars, cards, alerts, form controls, choices,
toggles, layout, typography and navigation. The opt-in entries are `dialog` (with the phone sheet),
`menu` (menus and popovers), `toast`, `search`, `tooltip`, `collapsible`, `code-block`,
`emoji-picker`, `table`, `prose` and `shell` (`lc_app_header`, `lc_docs_shell` and `lc_dock`; the dock's action
menu also needs `menu`). A component whose entry is missing renders unstyled.

The gem's stylesheets write into the `components` and `modules` layers, so the host declares that layer order.
The theme defines the `dark:` variant with `html[data-theme="dark"]`. Each entry carries its own `@source` lines, so Tailwind
scans the gem's helpers, views and JavaScript wherever the gem is installed.

### Theming

Colors use [shadcn/ui](https://ui.shadcn.com/docs/theming) names, so a shadcn or tweakcn theme drops in.
Set `data-theme="dark"` on `<html>` for dark mode; your app owns the switch and saved preference.
Override any of these after the engine import:

```css
:root {
  --primary: oklch(46% 0.14 155);
  --radius: 0.625rem;      /* every corner scales from this */
  --lc-density: 0.875;     /* semantic spacing and control heights */
}

html[data-theme="dark"] {
  --primary: oklch(75% 0.14 155);
}
```

| Setting | Default | Drives |
| --- | --- | --- |
| `--background` `--foreground` | white, near black | page and body text |
| `--card` `--card-foreground` | light gray | cards |
| `--card-input` `--card-secondary` | `--input`, `--secondary` | fields and secondary buttons inside cards and list rows; set them when `--card` matches either fill |
| `--popover` `--popover-foreground` | page background | menus, popovers, dialogs |
| `--primary` `--primary-foreground` | near black, white | primary actions, links, selection, focus |
| `--secondary` `--secondary-foreground` | gray | secondary buttons |
| `--muted` `--muted-foreground` | light gray, mid gray | subtle fills; secondary text, hints, placeholders |
| `--accent` `--accent-foreground` | gray | hovered rows and menu items, inline code |
| `--destructive` `--success` `--warning` | | status; soft fills such as `bg-success-soft` are generated |
| `--border` `--input` `--ring` | | dividers, input fills, focus ring |
| `--radius` | `0.5rem` | `rounded-sm` to `rounded-3xl` and `rounded-pill`; the default keeps Tailwind's own sizes |
| `--lc-density` | `1` | the semantic spacing and control heights below |
| `--lc-inset` | `1.25rem` | padding of cards, dialogs and popovers |
| `--font-sans` `--font-display` `--font-mono` | system | font families |
| `--font-eyebrow` | `var(--font-mono)` | eyebrow text; Japanese eyebrows use `--font-sans` |

Defaults live in `app/assets/tailwind/lostcoords/ui/theme.css`. `Lostcoords::Ui::TOKENS` lists the
public colors and fonts. Library-internal settings use the `--lc-` prefix.

### Foundations

Components never set outer margin. Layout helpers own the space between things, and components pad
themselves from `--lc-inset`. Every token is a Tailwind utility:

| Spacing | Default | Use |
| --- | --- | --- |
| `tight` | 4px | icon and label |
| `related` | 8px | label and control, button groups |
| `heading` | 12px | a heading and its content |
| `content` | 16px | blocks and fields |
| `inset` | `--lc-inset` | container padding and the gaps between its blocks |
| `section` | 32px | sections on a page |

Use them as `gap-related`, `p-inset`, `py-section` and so on. Setting `--lc-inset` on an element
changes the padding of every card or dialog inside it.

| Type role | Size / line height | Use |
| --- | --- | --- |
| `text-display` | 36 / 40px, bold | hero |
| `text-title` | 30 / 36px, bold | page title |
| `text-heading` | 20 / 28px, bold | section title |
| `text-subheading` | 18 / 24px, semibold | card and dialog titles |
| `text-body` | 16 / 24px | text |
| `text-small` | 14 / 20px | hints and secondary text |
| `text-label` | 14 / 20px, medium | labels, buttons, menu items |
| `text-caption` | 12 / 16px | metadata, table headers |
| `text-eyebrow` | 12 / 16px, medium, uppercase | kickers and column labels |

Each role sets size, line height, tracking and weight together. `lc-trim` trims the space above the
capital letters and below the baseline where the browser supports `text-box`.

Buttons, inputs, selects, toggles and icon buttons share heights: `h-control-sm` (32px),
`h-control-md` (40px) and `h-control-lg` (48px). On touch screens the small and medium sizes grow to
at least 40 and 44px. Containers use `max-w-page`, `max-w-reading` and `max-w-form`, and the page
container pads with `px-gutter`.

### Importmap

The engine pins its modules under `lostcoords/ui/*`. Controllers are also pinned under the host's
`controllers/*` key with an `lc_` prefix, so Rails' controller loading registers them as `lc-dialog`,
`lc-menu`, `lc-copy` and so on. Load them lazily, so a page downloads only the controllers it uses,
the first time their `data-controller` appears:

```javascript
// app/javascript/controllers/index.js
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
import { application } from "controllers/application"

lazyLoadControllersFrom("controllers", application)
```

`eagerLoadControllersFrom` also works and downloads all of them on every page. A host file with the
same name, such as `app/javascript/controllers/lc_dialog_controller.js`, replaces the gem's.

To register controllers by hand instead, import `registerControllers` from the `lostcoords/ui` pin:

```javascript
import { registerControllers } from "lostcoords/ui"

registerControllers(application, { only: ["lc-copy", "lc-collapsible"] })
```

Omit `only` to register every library controller. Unknown identifiers raise before anything is
registered, and repeated calls on the same application keep later overrides, so register defaults
before application overrides.

## Changes in 0.9.1

Nothing needs an edit:

- **Opening a dialog, sheet or menu no longer shifts the page.** The scroll lock pins the body at the width
  it had before locking, so the page keeps its width when the scrollbar disappears.

## Changes in 0.9.0

The gem is Rails-only. It loads through its Rails engine, and the standalone ActionView mode is gone:

- **`require "lostcoords/ui/action_view"` and `require "lostcoords/ui/rails"` are removed.** Use
  `require "lostcoords/ui"`, or let Bundler require the gem. Both load the engine.
- **`Lostcoords::Ui.view_paths`, `Lostcoords::Ui.load_translations!` and `Lostcoords::Ui.root` are removed.**
  The engine adds the gem's views and translations to the host's lookup paths. Use
  `Lostcoords::Ui::Engine.root` to locate the gem's files.
- **Components no longer call a private `lc_locale`.** They translate with `I18n.locale`. Set the locale
  through Rails, for example with `I18n.with_locale` in a controller `around_action`.
- **The gem depends on `railties` instead of `activesupport`.** An app outside Rails moves to a Rails
  application and the engine's asset setup above.

Rails apps that load the gem through Bundler need no edits.

New components and options:

- **`lc_toc` is an "On this page" list that follows the reader.** It marks the section scrolled to with
  `aria-current="location"` and slides an indicator to it. Pass links with `toc.link "Usage", "#usage"`, or
  rendered HTML with `lc_toc(headings: html)` to list its `h2` and `h3` that carry an id.
- **Headings and sections can link to themselves.** `lc_heading "Usage", id: "usage", anchor: true` and
  `lc_section title: "Usage", id: "usage", anchor: true` wrap the title in a link with a `#` mark on hover.
  `anchor: "section-id"` links a heading to an element around it. `lc_prose(anchors: true)` does the same for
  rendered Markdown, whose headings Kiln gives ids.
- **Anchored targets clear sticky chrome.** `.lc-anchor-target` sets a scroll margin of `--lc-sticky-offset`,
  which `lc_app_header` sets to `5rem` while it renders. Override the property if your header is taller.
- **`lc_app_header`, `lc_docs_shell` and `lc_dock` move from the Blocks examples into the gem**, in the new
  `shell` stylesheet entry, with the `lc-app-header` and `lc-dock` controllers. `lc_app_header` yields
  `header.brand`, `header.nav` and `header.actions`. `lc_docs_shell(navigation:, contents:)` lays out a sidebar,
  the page and an `lc_toc`. `lc_dock` yields `dock.nav` and `dock.menu`, reserves its height at the end of the
  page and hides while the on-screen keyboard is open. If you copied the Application header, Documentation
  layout or Mobile navigation block, you can replace the copy with the helper and delete its stylesheet and
  controller.

## Changes in 0.8.2

Nothing needs an edit. New options, and one change you may see:

- **`lc_emoji_picker` takes `picker_class:`, `trigger_class:` and `popover_class:`.** The gem leaves the desktop
  popover unpainted so the host can match its own floating surfaces; until now that meant rendering the
  `lostcoords/ui/components/emoji_picker` partial directly. Pass the classes to the helper instead.
- **A dialog slides to a new width.** `.lc-dialog` transitions `inline-size`, so a dialog that widens, such as
  one opening a side panel, animates instead of jumping. A host that restated the dialog's `transition` only to
  add `inline-size` can delete that rule.
- **`lc-scroll-keeper` keeps a scroll container's position.** Put `data-controller="lc-scroll-keeper"` on a
  sidebar that every page renders again; it restores its scroll across Turbo visits and reloads.
- **`lc_nav_list` keeps the server's current link after a back visit.** Before: a page restored from Turbo's
  cache showed the link clicked before leaving as current. After: it shows the one the server marked.

## Changes in 0.8.1

Nothing needs an edit, but these look different:

- **A secondary destructive button has a soft destructive fill.** Before: `variant: :secondary, tone: :destructive`
  kept the neutral secondary fill with destructive ink. After: it fills with the same soft destructive mix a
  destructive ghost button shows on hover, so the tones read solid, soft, then ink only.
- **Toggles style `aria-checked`.** An `lc_toggle_class` element with `aria-checked="true"` now looks pressed, so
  toggle pills can be the radios of a `variant: :pills` toggle group.
- **A toggle's fill follows `--lc-field-bg`.** Before: `lc_toggle` always filled with `--input`. After: it reads
  `--lc-field-bg` like fields and the select trigger, so on a card or list row it takes `--card-input`.
- **The emoji picker's skin-tone menu opens downward.** Before: it opened above its toggle, which sits in the
  picker's top row, so it escaped the picker. After: it opens below the toggle, inside the picker.
- **A card's destructive edge ignores its closed menus.** Before: a destructive option in a menu or popover
  inside a card (a row's "Remove") tinted the card's edge. After: only the card's own controls and invalid
  fields do.

## Upgrading from 0.7

Everything else in 0.8 is additive. These changes need edits in an app built on 0.7:

- **A named `lc_toggle_group` renders native radios.** Before: `lc_toggle_group(name:)` rendered radio
  buttons, a hidden input and the `lc-selection` controller. After: each item is a `label` around an
  `input type=radio` with that name, so listen for the inputs' `change` instead of `lc-selection:change`, and
  mark the selected item with `checked:` or the group's `value:` instead of `selected:`. A group without
  `name:` keeps the radio buttons and `lc-selection:change`; it no longer has an `input` target.
- **`lc_sheet_data` is gone.** Before: `tag.dialog data: lc_sheet_data({ controller: "picker" }, detents: "large")`.
  After: `lc_sheet tag: :dialog, detents: "large", data: { controller: "picker" }`. `lc_sheet` also renders
  non-dialog sheets, so drop any hand-written `data-controller="lc-sheet"` and handle element too.
- **The `lc-confirm-dialog` controller is gone.** Before: a pre-rendered confirm `<dialog>` wired to
  `lc-confirm-dialog`. After: render `lc_confirm_sheet` once in the layout and put `data-turbo-confirm` on
  the form, with `data-turbo-confirm-description`, `data-turbo-confirm-accept` and
  `data-turbo-confirm-tone` for its description, label and tone.
- **A modal `lc_dialog` is 32rem wide on desktop.** Before: `min(92vw, 31rem)`. After: `size: :md`,
  `min(32rem, 100vw - 2rem)`. Pass `size: :sm` (24rem) for a narrower dialog, or set `--lc-dialog-width`.
- **`lc_dialog` puts your content in a body slot.** Before: the block rendered straight after the header
  inside `[data-slot=dialog-content]`. After: it renders inside `[data-slot=dialog-body]`, which scrolls on
  desktop, and the close button sits in `[data-slot=dialog-actions]`. Update CSS that selects children of
  `dialog-content`.
- **A swiped-away popover sheet hides itself.** Before: `lc-sheet:dismiss` only notified listeners on a
  non-dialog sheet. After: an open `[popover]` sheet hides unless a listener calls `preventDefault()`.
- **An unpadded `lc_card` no longer gaps its children.** Before: `lc_card(padding: :none)` stacked its
  children `--lc-inset` apart. After: they meet edge to edge, as rows and empty states in an unpadded card
  expect. Pass `class: "gap-inset"` to keep the old spacing.
- **`lc_text(size: :label)` is semibold.** Before: weight 500. After: 600, the same as a field label, so
  one label role serves both. Add `class: "font-medium"` where the lighter weight was intended.

## Components

[Installation and setup](https://ui.lostcoords.com/installation.html) · [Live examples](https://ui.lostcoords.com). Each example renders the same ERB source shown
in its code panel. The API reference reads signatures from the helper definitions.
[API JSON](https://ui.lostcoords.com/api.json) and [llms.txt](https://ui.lostcoords.com/llms.txt)
include those signatures and the runnable examples.

Buttons use `primary`, `secondary`, `outline`, `ghost`, `glass` or `destructive`, with `sm`, `md` or `lg` sizes.
Primary, secondary and destructive buttons have visible filled surfaces. Ghost buttons and the
`lc_icon_button` toolbar action are transparent at rest and show their full shape on hover.
Primary, secondary and destructive buttons are flat. Secondary buttons use a soft neutral fill distinct from page and card backgrounds.
Outline buttons have a transparent fill and a visible edge. Glass buttons use the shared translucent material, rim and shadow for floating controls.
The default light theme uses white pages and softly shaded cards, with no visible card borders or resting shadows.
Popover triggers accept `trigger_variant` using the same button variants.
Button hover and press fills mix 94% of the base background with 6% of its foreground in OKLab.
Ghost and icon buttons stay transparent at rest and use the secondary base for that calculation.
Apps can override `--secondary` for the neutral base, or `--lc-button-bg` and `--lc-button-ink` on individual buttons.
Inputs use `--input` and `--lc-input-hover`.
`lc_button_to` preserves Rails' form, HTTP method and CSRF behavior. `lc_icon_button_link_to` and `lc_icon_button_to` are the link and form versions of `lc_icon_button`; a block replaces its icon with custom content. Icon buttons take `lc_button`'s `variant:` and `tone:` too; the default `:ghost` is the quiet toolbar look. `block: true` makes any button full width. Block helpers capture ERB content.
Use `icon: "plus"` for a leading Heroicon or `icon_position: :end` for a trailing one. Custom icons and
spinners use `data-icon="inline-start"` or `data-icon="inline-end"`; buttons adjust that edge's padding.
`lc_button(expanded_icon: "x-mark")` swaps its content for that icon while `aria-expanded` is true, for a trigger
that closes what it opened; the content stays as the accessible name.
`lc_button(as: :span)` renders the look without a control, for a decorative button inside a larger target such as
a file drop zone's label; give it `aria: { hidden: true }` when the target already names the action.
`tone: :destructive` recolours any variant for destructive actions and keeps its emphasis: a ghost or
outline button takes destructive ink, a secondary button a soft destructive fill (the ghost button's hover),
and a primary button becomes the filled `variant: :destructive` surface.
`lc_select_trigger` is a button that looks like `lc_select`, for buttons that open a menu or picker. Its label
starts at the inline start and its chevron sits at the inline end and turns while `aria-expanded` is true.
`lc_split_button` is one pill with two targets: a primary action, a link with `href:`, and a square toggle
named by `menu_label:` that opens a menu of the block's `lc_menu_option` items. The toggle draws a divider
from its ink and keeps its pressed fill while open. It takes the button's `variant:`, `tone:`, `size:` and
`icon:`; `action:`, `toggle:` and `menu:` add attributes to those parts.

```erb
<%= lc_button_to "Archive", project_path(@project), method: :delete, variant: :destructive %>
<%= lc_button_to "Revoke", api_key_path(@key), method: :delete, variant: :ghost, tone: :destructive %>
<%= lc_select_trigger "All members", aria: { haspopup: "menu", expanded: false } %>
<%= lc_split_button "Add expense", id: "add-menu", href: new_expense_path, icon: "plus", menu_label: "More ways to add" do %>
  <%= lc_menu_option "Import a CSV", icon: "arrow-down-tray" %>
<% end %>
<%= lc_icon_button "Settings", icon: "cog-6-tooth" %>
<%= lc_icon_button_link_to "Back", projects_path, icon: "chevron-left" %>
<%= lc_icon_button_to "Delete", attachment_path(@attachment), icon: "trash", method: :delete %>
<%= lc_icon_button "Account" do %><%= lc_avatar current_user.initials %><% end %>

<%= lc_button block: true, data: { action: "editor#save" }, aria: { busy: true } do %>
  <%= lc_spinner size: :sm %>
  Saving…
<% end %>
```

Use native attributes for application behavior, `class:` to merge additional Tailwind utilities, and
theme tokens to restyle the library. `popover: true` renders `popover="auto"`, as a bare `popover`
attribute does. `lc_field` yields the input's `id` and validation attributes so
labels, hints and errors stay connected. Linked cards use `lc_card(href: ...)`; cards containing
buttons or fields remain ordinary containers.

`lc_table` renders a native table with a shaded header and subtle row dividers. Supply the caption, header cells and body in its block.
Wrap wide tables in an app-owned horizontal scroll region with an accessible name and keyboard focus.
Use `lc_table_class` when an existing table renderer owns the markup.

Cards share one API: `lc_card(padding: :md)`, with `:sm` and `:none` for tighter or custom spacing. Padding sizes set `--lc-inset`, so content inside follows the card.
Fields and secondary buttons inside cards take `--card-input` and `--card-secondary`, which default to the page fills; set them in the theme when `--card` equals `--input` or `--secondary`, or set `--lc-field-bg` to change fields in one context. Cards provide avatar cutouts and a validation border when they contain errors. Fills that are muted on the page switch so they stay visible on the card: choice tiles, alerts, neutral badges and skeletons take the page background (`--lc-tile-bg`), and toggle group and tab tracks take the accent fill (`--lc-track-bg`). Set either variable to apply the same context to your own muted surface.
Add `class: "@container"` when a card owns its width and its children use container queries.
Use `--lc-card-bg`, `--lc-card-border`, `--lc-card-radius` and `--lc-card-shadow` for local appearance overrides.

`lc_badge` handles labels, counts and status. Pass `shape: :pill` for a fully rounded label such as "You" or an error count.
`lc_icon_badge` handles decorative icon containers: pass `icon:` for a library icon, or content or a block for an emoji. It takes `shape: :square`, `:circle` or `:plain` (no tile and a larger glyph, as at the start of a list row) and `sm` (26px), `md` (40px), `lg` (48px) or `xl` (56px) sizes.
`lc_avatar` sizes are `xs` (20px), `sm` (26px), `md` (32px), `lg` (48px), `xl` (96px) and `xxl` (112px).
Between them, both take a step on the spacing scale, as in `size-7`: `lc_avatar` takes `7` (28px) and `11` (44px),
`lc_icon_badge` takes `6` (24px), `7` (28px) and `11` (44px).
Pass `as: :button` when the avatar is itself the control, such as a colour picker's trigger. `lc_avatar_stack`
takes `row:` attributes for the inner row that overlaps the avatars, such as a controller target.
Initials and icons scale with the size, including a size set through `--lc-avatar-size` or `--lc-icon-badge-size`;
set `--lc-avatar-font-scale` or `--lc-icon-badge-font-scale` to change the share, or the `-font-size` variable to pin it.
Badge, icon badge, Alert and Toast share `neutral`, `primary`, `success`, `warning` and `destructive` tones.

`lc_toggle` renders a button that flips its own `aria-pressed`; set `aria-pressed` or `aria-expanded` yourself
and it leaves the state to your controller. `href:` renders a link marked `aria-current` when active, and `name:`
with `value:` a label around a visually hidden native radio, styled by `:checked`.
`lc_toggle_group` with `lc_toggle_group_item` holds mutually exclusive choices, and the group decides what its items are.
With `name:` they are native radios in labels, which bring their own arrows, submitted value and reset; items take
`value:` and `checked:`, and the group's `value:` checks the matching item. With `as: :nav` they are links in a
labelled `nav`; items take `href:` and `current:`. Otherwise they are radio buttons whose selection lives in the
`lc-selection` controller, which dispatches `lc-selection:change`; items take `value:` and `selected:`. An item
given another kind's arguments raises. `variant: :pills` lays any of them out as wrapping toggle pills, sized by `size:`, instead of a segmented track.

```erb
<%= lc_toggle_group label: "Period", as: :nav do %>
  <%= lc_toggle_group_item "Month", href: stats_path(period: :month), current: true %>
  <%= lc_toggle_group_item "Year", href: stats_path(period: :year) %>
<% end %>
<%= lc_toggle_group label: "Billing", name: "billing", value: "monthly" do %>
  <%= lc_toggle_group_item "Monthly", value: "monthly" %>
  <%= lc_toggle_group_item "Annual", value: "annual" %>
<% end %>
<%= lc_toggle "Food", aria: { pressed: false }, data: { value: "food" } %>
```

`lc_collapsible` expands content through a native `<details>` element. `lc_alert` renders persistent inline feedback;
`lc_toast` adds timed dismissal.

```erb
<%= lc_collapsible card: false, indicator: :chevron, summary_class: "rounded-2xl px-3 hover:bg-accent" do |collapsible| %>
  <% collapsible.summary do %><span class="me-auto">Language</span><span>English</span><% end %>
  …
<% end %>
```

The `summary` part replaces `title:` with your own markup and takes attributes for the `<summary>`.
`card: false` drops the card surface, `summary_class:` adds classes to the summary, `button: { variant:, tone:, size: }`
makes the summary look like that `lc_button` without the native marker, and `indicator:` is `:marker` (native),
`:chevron` (turns as it opens) or `:none`.

```erb
<%= lc_list_section "Security", id: "security", footnote: "Keep one way to sign in." do %>
  <%= lc_list_group do %>
    <%= lc_list_row "Email", subtitle: "ada@example.com", icon: "envelope" do %>
      <%= lc_button "Change", variant: :secondary, size: :sm %>
    <% end %>
    <%= lc_list_row "Alerts", tag: :label do %><%= check_box_tag :alerts, class: lc_switch_class %><% end %>
  <% end %>
<% end %>
```

`lc_list_group` draws grouped settings rows: each row is its own card-coloured panel, 2px apart, and
only the group's ends round. Rows are card surfaces, so fields and buttons in them follow
`--card-input` and `--card-secondary`. `lc_list_row` with a title lays out `icon:` (a name, or your own
markup such as a logo), the title, `subtitle:` and the block as trailing content; `tag:` makes it a
`label`, `li`, `details` or `a` (`href:`). Without a title the block is the whole row, and
`padded: false` leaves the padding to content such as an `lc_list_item` button or summary, which lays
out the same icon, title and subtitle inside your own element. `lc_list_section` adds the heading and
footnote; with an `id:`, the heading labels the section. Put a form around `lc_list_group` inside it
when the rows save together.

`lc_list_field` is a form row in the same group: a label column, then the block as the control. In a
narrow row the label folds to its `icon:`, and the text stays the accessible name. `id:` makes the label
a `<label>` for that control; `tag: :fieldset` names a group of controls, such as chips, with a legend.
`tag: :span, surface: false` draws the row inside another element, such as a collapsible's summary.
`lc_input(plain: true)` drops the field's fill, border, padding and height so the text sits in the row,
which tints while that input has focus. Toggles take `--lc-field-bg` like fields, so on a card or list
row they use `--card-input`.

```erb
<%= lc_list_group do %>
  <%= lc_list_field "Description", icon: "pencil", id: "description" do %>
    <%= lc_input plain: true, id: "description", name: "description" %>
  <% end %>
  <%= lc_list_field "Paid by", icon: "user", tag: :fieldset do %>
    <div class="flex flex-wrap gap-related"><%= lc_toggle "Ada", size: :sm, aria: { pressed: true } %></div>
  <% end %>
<% end %>
```

### Parts and slots

Compound components yield a builder, so their parts are scoped and discoverable. A card stacks its
parts with the same gap it pads with:

```erb
<%= lc_card do |card| %>
  <%= card.header title: "Members", description: "People in this workspace" do %>
    <%= lc_button "Invite", size: :sm %>
  <% end %>
  <%= card.content do %>…<% end %>
  <%= card.footer do %><%= lc_button "Save" %><% end %>
<% end %>

<%= lc_alert "Your card was declined.", title: "Payment failed" do |alert| %>
  <%= alert.actions do %><%= lc_button "Update payment", size: :sm %><% end %>
<% end %>

<%= lc_dialog id: "new-project", title: "Create project", description: "Projects group pages." do |dialog| %>
  …
  <%= dialog.footer do %><%= dialog.close %><%= lc_button "Create" %><% end %>
<% end %>
```

Every component root and part carries `data-slot`, plus `data-variant`, `data-size` or `data-tone`
where they apply, so a context can restyle parts without matching utility classes:
`[data-slot=card-footer] { justify-content: start }`.

### Forms

`lc_form_with` is `form_with` with `Lostcoords::Ui::FormBuilder`. Standard helpers keep their Rails
signatures and render library controls; `field` adds the label, hint and the attribute's errors, and
sets `aria-invalid` on the control. Rails' `field_with_errors` wrapper does not affect the layout.

```erb
<%= lc_form_with model: @project, gap: :content do |form| %>
  <%= form.field :name, hint: "Shown to members" %>
  <%= form.field :email, as: :email_field %>
  <%= form.switch :public %>
  <%= form.submit "Save project" %>
<% end %>
```

`gap:` makes the form a stack and `card: true` (with `padding:`) makes the form the card, so neither
needs a wrapper element. Nested `fields_for` builders render library controls too, and
`form.check_box :x, role: "switch"` draws a switch inside a label row you build yourself.
`form.submit` and `form.button` take `lc_button`'s `variant:`, `tone:`, `size:` and `block:`.

A symbol `size:` such as `size: :sm` picks the control height; an integer still sets the HTML
attribute. `form.field … size: :sm` (or `lc_field size: :sm`) is the compact field for dense forms,
with a caption label. Pass `builder: Lostcoords::Ui::FormBuilder` to `form_with` directly, or call `lc_field`
with `error: record.errors.full_messages_for(:name)` when you keep your own builder.

`lc_checkbox`, `lc_radio` and `lc_switch` render native inputs with a label and optional hint.
Checkboxes and switches submit an unchecked value like Rails' `check_box`; pass `unchecked_value: nil`
to omit it. A `nil` label renders the bare input, for a row selector the row labels; give it
`aria: { label: }`. `lc_choice_group` groups them in a fieldset with a legend, hint and error.

`lc_fieldset(legend:, id: nil, hint: nil, error: nil, size: :md)` names a group of controls that no single
label can, such as toggles, a picker or several inputs; with an `id`, its hint and error describe the fieldset,
and `size: :sm` matches a compact `lc_field`. `lc_choice_group` is `lc_fieldset` with its choices stacked.
Text that labels something other than one control, such as a list, uses `lc_text size: :label`, the field label's role.

### Navigation and overlays

```erb
<%= lc_breadcrumb [ [ "Projects", projects_path ], @project.name ] %>

<%= lc_tabs id: "project-tabs", label: "Project" do |tabs| %>
  <% tabs.panel "Overview" do %>…<% end %>
  <% tabs.panel "Activity", value: :activity do %>…<% end %>
<% end %>

<%= lc_tooltip "Copy a link", id: "copy-tip" do |tip| %>
  <%= lc_icon_button "Copy link", icon: "link", **tip %>
<% end %>

<%= lc_description_list do |list| %>
  <%= list.item "Owner", @project.owner.name %>
  <%= list.item("Plan") { lc_badge @project.plan } %>
<% end %>
```

Tabs follow the ARIA tabs pattern with arrow key, Home and End navigation, and dispatch
`lc-tabs:change`. `orientation: :vertical` stacks the tabs beside their panels and moves with Arrow Up
and Down; `activation: :manual` moves focus with the arrows and selects with Enter or Space; `list:` adds attributes to the tab list. Tooltips show on hover and keyboard focus, Escape hides them, and they describe
their trigger, in the top layer; keep essential information visible. Description lists stack on phones and use two
columns from `sm`.

```erb
<%= lc_skip_link %>

<%= lc_nav_list label: "Settings" do |nav| %>
  <%= nav.group "Workspace" do %>
    <%= nav.link "General", settings_path, current: current_page?(settings_path) %>
    <%= nav.link "Members", members_path %>
  <% end %>
<% end %>

<%= lc_pager previous: [ "Install", install_path ], next: [ "Theming", theming_path ] %>

Read the <%= lc_link "guide", guide_path %>.
```

```erb
<%= lc_nav_list label: "Project", layout: :responsive, indicator: true do |nav| %>
  <%= nav.link "Overview", project_path(@project), icon: "document-text", current: true %>
  <%= nav.link "Activity", project_activity_path(@project), icon: "clock" %>
<% end %>
```

`lc_nav_list` marks the current link with `aria-current="page"`. Its default `layout: :column` is a
sidebar, where `compact: true` is the quieter style for an "On this page" list and `indent: true`
nests a link. `layout: :row` lays links in a line, `:dock` stacks each icon above its label in equal
cells for a phone's bottom bar, and `:responsive` is a dock below `sm` and a row from `sm`; position a
dock yourself, such as `fixed bottom-0`. `indicator: true` slides one fill to the current link, and
after a Turbo visit the new list starts the fill where the last one left it. Set `--lc-nav-indicator`
(or `--lc-nav-dock-indicator` for a dock, such as one on glass) to change the fill, and pass `layout:` to `lc_nav_link_class` for links you render yourself. `lc_pager` takes `[title, url]`
for each side and `compact: true` for icon buttons. `lc_link` has `inherit`, `muted` and `primary`
tones; `lc_link_class` styles links you render yourself. `lc_skip_link` targets `#main` by default.
Pass `card: true` to `lc_radio` or `lc_checkbox` for selectable tiles; a block adds content, such as a
preview, under the label.

A sidebar that scrolls on its own starts at the top on every page. Put `data-controller="lc-scroll-keeper"`
on the scroll container to keep its position across Turbo visits and reloads. Containers with the same
`data-lc-scroll-keeper-key-value` share one position for the browser tab. Without a saved position,
it scrolls the `aria-current="page"` link into view.

Page chrome lives in the `shell` stylesheet entry. `lc_app_header` is a sticky glass header,
`lc_docs_shell` lays out a documentation page, and `lc_toc` lists the page's sections and marks the one
the reader has scrolled to. This documentation site is built with them.

```erb
<%= lc_app_header do |header| %>
  <%= header.brand root_path, label: "Acme home" do %><%= image_tag "logo.svg", alt: "" %> Acme<% end %>
  <%= header.nav class: "max-sm:hidden" do |nav| %>
    <%= nav.link "Guides", guides_path, current: true %>
  <% end %>
  <%= header.actions do %><%= lc_icon_button "Search", icon: "magnifying-glass", size: :sm %><% end %>
<% end %>

<% contents = lc_toc do |toc| %>
  <%= toc.link "Usage", "#usage" %>
  <%= toc.link "Sizes", "#sizes", indent: true %>
<% end %>
<%= lc_docs_shell navigation: render("guides/sidebar"), contents: do %>
  <%= lc_section title: "Usage", id: "usage", anchor: true do %>…<% end %>
<% end %>
```

For rendered Markdown, such as a Kiln `.md` view, pass the HTML to both: `lc_prose(anchors: true) { html }`
links its headings, and `lc_toc(headings: html)` lists them. On phones, `lc_dock` floats `dock.nav` and a
`dock.menu` of quick actions at the bottom of the screen; render it last, since it reserves its height there.

```erb
<%= lc_menu id: "member-actions", label: "Actions for #{member.name}", trigger: :icon do %>
  <%= lc_menu_option "Rename", icon: "pencil" %>
  <%= lc_menu_option "Euro", hint: "EUR", leading: tag.span("€"), checked: true %>
  <%= lc_menu_option "Remove", icon: "trash", href: member_path(member), method: :delete, tone: :destructive %>
<% end %>
```

Menu options take a leading `icon:` or other rendered `leading:` content, which is hidden from
assistive technology so the label stays the name. Leading visuals share one column across the menu, so
labels line up with and without them. `hint:` adds a secondary line. `checked: true` or `false` makes
a `menuitemradio` with a check mark. `checkbox: true` makes a `menuitemcheckbox` that flips its
`aria-checked` on click, dispatches `lc-menu:check` with `{ checked }`, and leaves the menu open.
`method:` renders a `button_to` form and passes `params:` and `form:` on.
`lc_menu_group(label, id:)` wraps options in a `role="group"` labelled by an eyebrow heading; its
options stay on the menu's columns.
`lc_menu` and `lc_popover` take `trigger: false` to render only the panel, named by `label:` (or
`title:`), when an ancestor hosts the `lc-menu` or `lc-popover` controller and wires its own
`trigger` targets. With `click->lc-popover#toggleFromRow` on that host, a click anywhere on it that
misses a control opens the panel; mark other regions `data-lc-menu-ignore`.
`lc_menu` and `lc_popover` take `trigger: :icon` with `icon:` for a quiet icon button named by `label:`,
or rendered content such as an avatar for a custom trigger. `trigger_attributes:` adds attributes such as `class:` or `title:` to either.
For any other trigger, call the yielded part's `trigger` with a block. It receives the attributes that
wire an element as the trigger (its id, `aria-haspopup`, `aria-expanded`, `aria-controls` and the
Stimulus target and action), merged with any passed to `trigger`, and the element it renders replaces
the default button:

```erb
<%= lc_menu id: "member-filter", label: "Member" do |menu| %>
  <% menu.trigger(class: "min-w-44") { |attrs| lc_select_trigger "All members", **attrs } %>
  <%= lc_menu_option "Alex" %>
<% end %>
```
The icon trigger is muted at rest, with full ink and a slightly larger icon on hover, focus and while open.
`wrapper_attributes:` styles the element that holds the trigger and panel, an `inline-flex` box by default,
for example `class: "flex min-w-0"` when the trigger fills a grid cell. A `data: { controller: }` there joins the panel's own.

`lc_dialog` handles modal content and the mobile sheet layout. Set `detents: "medium large"` or `"large"`
to choose mobile height stops; the default is `"fit"`. Icon buttons, avatar groups, motion and mobile dialogs
appear with their parent component examples.

`size:` sets the desktop width: `:sm` (24rem), `:md` (32rem, the modal default), `:lg` (40rem) or `:xl`
(64rem). Content marked `data-dialog-size="xl"` (any size) switches the dialog to that size while it is in
the dialog, for a step that needs more room. The size sets `--lc-dialog-width`, so content can size itself
with `calc(var(--lc-dialog-width) - 2px)`. On desktop the header stays put and the body scrolls; an anchored
dialog stops 1rem above the viewport's bottom edge. `dialog.actions` adds content to the header, before the
close button. `dialog.trigger { |attrs| … }` renders your own element as the trigger, like `menu.trigger`:
splat `**attrs` into it to wire it to open the dialog. Pass `trigger: false` when a controller of your own opens the dialog: only the `<dialog>` renders,
and `close_action:` (default `"lc-dialog#close"`) and `close_label:` wire the close buttons to it. `data:`
and `aria:` reach the `<dialog>`; `title_attributes:` and `description_attributes:` reach the heading and
description, for a controller that rewrites them.

```erb
<div data-controller="import">
  <button type="button" data-action="import#open">Import</button>
  <%= lc_dialog id: "import", title: "Import", trigger: false, size: :lg, close_action: "import#close",
        data: { import_target: "dialog" } do |dialog| %>
    …
  <% end %>
</div>
```

`lc_confirm_sheet` replaces the browser's confirm for `data-turbo-confirm`. Render it once in the layout
and hand Turbo the gem's function:

```js
import { confirm } from "lostcoords/ui/helpers/confirm"
Turbo.config.forms.confirm = confirm
```

The sheet shows the message as its title, Cancel and a confirm button. The submitter, then the form, can
add `data-turbo-confirm-description` (a line under the title) and `data-turbo-confirm-accept` (the confirm
button's label; without it a short submitter label is used). The confirm button is destructive when either
has `data-turbo-confirm-tone="destructive"`, or the submitter is an `lc_button_to` with
`variant: :destructive` or an `lc_menu_option` with `tone: :destructive`. Confirming from an `lc_menu` opens
the sheet beside the menu on desktop. `ask(message, { description, accept, destructive, anchor })` from the
same module opens it from your own code and resolves to `true` or `false`.

`lc_sheet` renders any other phone sheet, with the `lc-sheet` controller wired. `tag: :dialog` makes a
modal `<dialog>` sheet, which is what `lc_dialog` and `lc_confirm_sheet` render; with `size:` it gets
`lc_dialog`'s frame and width without its header, for content that brings its own. The default `tag: :div`
shows while it is `:popover-open` or carries `[data-open]`, so a native `[popover]` and a FloatingPanel
picker both work; a div you toggle yourself sets `data-open` and removes it to slide out. From `sm` up
the div keeps your frame, or `anchored: true` makes it a popover under its trigger inside a positioned
ancestor. `detents:` takes the same stops as `lc_dialog`, and `handle: true` adds a grab strip above the
content. A swipe down dispatches `lc-sheet:dismiss`; unless a listener cancels it, an open popover then
hides.

```erb
<button type="button" popovertarget="filters">Filters</button>
<%= lc_sheet id: "filters", popover: "auto", class: "sm:w-80 sm:rounded-3xl sm:bg-popover",
      data: { action: "lc-sheet:dismiss->filters#reset" } do %>…<% end %>
```

`lc-popover-shell` gives a native `[popover]` menu the same enter and exit as FloatingPanel panels. Set
`--lc-popover-from` to change the closed pose and an `origin-*` utility for where it grows from.

### Search

`lc_search` renders a search trigger, a pill with the ⌘K hint that shrinks to an icon on phones, and
the full-screen search it opens. Attributes go to the trigger, which is what sits in your layout.
Build results from `lc_search_group` and `lc_search_result`.

```erb
<%= lc_search label: "Search", src: search_path %>

<%# app/views/searches/show.html.erb, rendered without a layout for lc_search's requests %>
<%= lc_search_group "Projects" do %>
  <% @projects.each do |project| %>
    <%= lc_search_result project.name, project_path(project), detail: project.client, icon: "folder" %>
  <% end %>
<% end %>
```

With `src:`, each pause in typing requests `src` with the query in `param` (`q` by default) and shows
the HTML the server answers; that endpoint is yours, as a Turbo Frame's would be. Without
JavaScript the field submits the same GET, so a full search page still works. Without `src:`, the
rows rendered in the block are filtered in the browser by their text and `keywords:`. To search
another way, handle `lc-search:query`, call `preventDefault()` and fill `event.detail.results` with
the same helpers' markup, cloned from a `<template>`; the docs search does this with MiniSearch.

The block also renders what shows before anything is typed. Arrow keys move through the results,
Enter opens the first one, and choosing a result or pressing Escape closes search and returns focus.
Groups without a visible result hide, a query with none shows the empty note, and a status region
announces the count. `empty:` sets that note, with `%{query}` standing for the query, and `prompt:`
adds a note for when nothing is typed and there is nothing to show. While `src` is answering, the
panel is `aria-busy` and both notes wait, so they never flash before the results arrive. Pass `shortcut: nil` to drop the page shortcut, and `id:` when a page has two searches.

### Keyboard

Every interactive component works from the keyboard without extra code:

| Component | Keys |
|---|---|
| Menu | Arrow Down or Up on the button opens on the first or last item. Arrows move and wrap, Home and End jump, a letter jumps to the next item that starts with it, Enter or Space activates, Escape closes and returns focus. |
| Tabs | Arrows along the tab list's orientation, Home and End. Automatic tabs select on focus; manual tabs on Enter or Space. |
| Toggle group | One Tab stop. All four arrows move and select, wrapping, as native radios do; Left and Right follow the text direction. |
| Emoji picker | Arrow Down from the search enters the grid, arrows move through it by row, Arrow Up from the top row returns to the search, and Enter in the search picks the best match. The grid is one Tab stop. |
| Dialogs, sheets, popovers, menus, tooltips | Escape closes the topmost one and returns focus to what opened it; an open tooltip closes before the menu or dialog around it. Escape in a search field with text clears it first. |

Page-wide shortcuts focus a field or press a button. Merge `lc_shortcut_data` into the element's data and
show the keys with `lc_kbd`:

```erb
<%= lc_input type: :search, name: "q", aria: { label: "Search" }, data: lc_shortcut_data("mod+k") %>
<%= lc_button data: lc_shortcut_data("n", action: "projects#new") do %>
  New project <%= lc_kbd "n", aria: { hidden: true } %>
<% end %>
```

Keys are joined with `+`: `mod` is ⌘ on Apple platforms and Ctrl elsewhere, and `ctrl`, `alt`, `shift`
and `meta` name the others. Separate alternatives with spaces. The element announces its keys through
`aria-keyshortcuts`. Shortcuts without `mod`, `ctrl` or `alt` don't fire while typing in a field, only
shortcuts inside an open modal dialog respond, and when two visible elements share keys the first wins
and the console warns. `lc_kbd` renders the Ctrl form and switches to Apple symbols once JavaScript runs.

Custom widgets can use the same navigation: `navigate(event, items, { orientation, wrap, typeahead })`
from `lostcoords/ui/helpers/roving_focus` handles vertical, horizontal and grid layouts, right-to-left
text, Home and End, and typeahead; `rove(items, current)` keeps a single Tab stop.

### Layers

Overlays never need a z-index. Dialogs and sheets open as modal `<dialog>` elements; menus,
popovers, pickers and tooltips move into the browser's top layer while they are open; toasts go in
`lc_toast_region`, which does the same. The top layer paints above every z-index, `overflow` clip
and stacking context on the page, so a sticky header, a `transform` or a glass `backdrop-filter`
can't cover them. A modal dialog makes the rest of the page inert, so while one is open the toast
region moves inside it and back when it closes. The region is the live region that announces its
toasts; destructive toasts are alerts. Where the Popover API is missing overlays stay in place,
ordered by `--lc-z-popover`, `--lc-z-overlay` and `--lc-z-toast`.

```erb
<%# In the layout, once %>
<%= lc_toast_region id: "toasts" do %>
  <% flash.each do |type, message| %><%= lc_toast message, tone: type == "alert" ? :destructive : :success %><% end %>
<% end %>

<%# From a controller or job %>
<%= turbo_stream.append "toasts" do %><%= lc_toast "Project saved." %><% end %>
```

The region sits at the bottom-end corner. `placement:` takes `:bottom_end`, `:bottom_center`,
`:top_end` or `:top_center`, and `mobile_placement:` takes the same values below `sm`, as in
`lc_toast_region id: "toasts", placement: :bottom_center, mobile_placement: :top_center`. The region
keeps clear of the safe area; set `--lc-toast-offset` to move it further from the edges, or
`--lc-toast-offset-top` and `--lc-toast-offset-bottom` for one edge, such as below a sticky header.

While a modal dialog or sheet is open the page behind it can't scroll: the body is pinned with
`position: fixed` and marked `data-modal-scroll-lock="true"`, so `window.scrollY` reads 0 until it
closes. Scroll-driven chrome, such as a header that fills in once the page scrolls, should keep its
state while that attribute is set; the body's `--lc-scroll-lock-y` holds the real offset.

Two in-page layers remain: `z-sticky` keeps app chrome such as a sticky header above content, and
`z-raised` lifts an element over its neighbours. Put `isolate` on the main content area, so any z-index
inside it stays below the chrome. Tailwind drops a `z-*` class it can't resolve without a warning, so
use these two names, a number or `z-(--a-defined-variable)`.

## Copy feedback and motion

```erb
<%= lc_copy_button value: "https://example.com/invite" %>
<%= lc_copy_button "Copy invite link", value: invite_url, copied_label: "Link copied" %>
<%= lc_copy_button "Copy link", value: invite_url, icon_only: true, variant: :ghost %>
<%= lc_copy_button "Copy code", source: "code-snippet", reset_after: 2500 %>
```

Pass exactly one of `value:` (literal text) or `source:` (an element ID). The source is read at click time:
inputs and textareas use their current value; other elements use their text content. Text is copied as supplied,
including whitespace. Clipboard access requires HTTPS or localhost and browser permission.

After a successful copy, the button transitions to a check and "Copied", then resets after `reset_after:`
milliseconds (2000 by default). Failure shows a retry icon and label with an accessible explanation.
The button reserves space for all labels, preserves focus, and announces the outcome through a live region.
Default labels are translated in English, Japanese and Spanish. Use `label` (the first argument),
`copied_label:` and `error_label:` to customize visible text, and `aria: { label: ... }` for a contextual name.
Normal button variants, sizes, classes, disabled state and attributes are supported.

The component emits bubbling `lc-copy:copied` (`detail.text`) and `lc-copy:error` (`detail.error`) events
from its wrapper. Listen on an ancestor to connect application behavior.

```erb
<%= lc_code_block "puts 'Hello'", id: "ruby-example", language: :ruby %>
<%= lc_code_block source, id: "file-example", language: :ruby, title: "app/helpers/greeting_helper.rb" %>
<%= lc_code_block source, id: "long-example", language: :ruby, max_lines: 5 %>
```

Code blocks escape plain source, preserve whitespace, and include a floating icon-only copy button.
The copy control appears on hover or keyboard focus and stays visible on touch devices and during copy feedback.
Snippets have no header by default; use `title:` for a compact filename or heading. `language:` sets code metadata
without adding a visible label. Snippets longer
than `max_lines:` (10 by default) can expand and collapse; use `max_lines: nil` to show all lines.
Copy failures expand clipped source for manual selection. Labels are translated in English, Japanese and Spanish.
An optional block receives the raw source and can return highlighted markup from the app's syntax highlighter.
For selective JavaScript registration, include both `lc-code-block` and `lc-copy`.

Buttons include hover and press feedback. Override `--lc-motion-quick` (140ms), `--lc-motion-control` (180ms),
`--lc-motion-feedback` (160ms), `--lc-press-scale` (0.96) and `--lc-ease-out` in your theme or on a container.
Reduced motion removes control movement and makes copy feedback immediate. Your application owns the
pending, success and failure states of network actions such as saving a form.

[Try the copy button](https://ui.lostcoords.com/components/copy_button.html) ·
[Motion reference](https://ui.lostcoords.com/components/foundations.html#motion)

### Icons

`lc_icon` renders Heroicons v2.2.0 SVGs. Variants are `outline` (the default), `solid`, `mini` and `micro`.
Pass SVG attributes through `options:` and existing path attributes through `path_options:`.

```erb
<%= lc_icon "check", options: { class: "size-5" } %>
<%= lc_icon "check", variant: :mini, options: {
  class: "size-4", role: "img", aria: { label: "Complete", hidden: false }
} %>
```

## Advanced style composition

### Typography and layout

Heading level controls document structure independently of its visual size. Layout parents own the
spacing between children, including fields. Inline `<code>` elements get a shared monospace style;
`<pre><code>` blocks keep their block styling.

```erb
<%= lc_stack gap: :section do %>
  <%= lc_heading "Workspace", level: 1, size: :title %>
  <%= lc_section title: "Members" do %>
    <%= lc_card do %>
      <%= lc_stack gap: :related do %>
        <%= lc_heading "Design team", level: 3, size: :subheading %>
        <%= lc_text "Three people share this workspace.", tone: :muted %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

Heading sizes are `display`, `title`, `heading` and `subheading`. Text sizes are `body`, `small`,
`label`, `caption` and `eyebrow`, with `default` and `muted` tones. `lc_text_class(size: :eyebrow, tone: :muted)`
styles a kicker or footer column label; under `lang="ja"` it keeps natural case and letter spacing. Pass `trim: true` to trim the text box.
Stacks and inline groups take the spacing names from [Foundations](#foundations). `lc_stack`, `lc_inline`,
`lc_text` and `lc_card` take `as:` to render a meaningful element, such as `lc_stack(as: :ul)`, `lc_text(as: :span)` or
`lc_card(as: :section)`. `lc_section` leaves
`heading` below its title and `content` between blocks. `lc_section_header` is that heading row on its own,
for a heading that needs more than a title, such as a lede under it. `lc_container` provides `page`, `reading` and
`form` widths; only the page container adds gutters. Japanese headings inherit `lang="ja"` and use
natural letter spacing.

[Browse the foundations examples](https://ui.lostcoords.com/components/foundations.html).

### Reading content

For articles or rendered Markdown, enable Tailwind Typography in the host input:

```css
@plugin "@tailwindcss/typography";
```

The standalone Tailwind CLI used by `tailwindcss-rails` includes this plugin. `lc_prose` supplies the host
theme colours, a 65ch maximum width, 1.75 line height and proportional block spacing. Its block follows
Rails' normal escaping rules; sanitise rendered user content before marking it safe.

```erb
<%= lc_prose do %>
  <h2>Share a workspace</h2>
  <p>Invite your team and keep your work together.</p>
  <div class="not-prose"><%= lc_button "Invite someone" %></div>
<% end %>
```

Override `--lc-reading-size`, `--lc-reading-leading`, `--lc-reading-flow` and `--lc-reading-measure`
to tune a reading context. Use `not-prose` for embedded components.

### Class helpers

Class helpers remain available for custom markup. The application owns its semantics and behavior.
`lc_glass_class` supplies translucent surfaces; `lc_tw` merges utilities with the last class winning.
`lc_glass(shape:, thick:, as:)` renders the surface as an element, such as `lc_glass as: :label` around a search field.

```erb
<nav class="<%= lc_glass_class(shape: :bar) %>" aria-label="Project navigation">
  <%= link_to "Overview", project_path(@project), class: lc_button_class(variant: :ghost) %>
</nav>
```

Generated by `bin/rails lostcoords:ui:builders`; `bin/lint` checks this list against the style helpers.

<!-- builders -->
- `lc_icon_badge_class(size: :md, shape: :square, tone: :neutral, extra: nil)` (BadgeHelper)
- `lc_avatar_class(size: :md, ink: false, linked: false, extra: nil)` (BadgeHelper)
- `lc_avatar_stack_class(compact: false, extra: nil)` (BadgeHelper)
- `lc_avatar_stack_row_class(extra: nil)` (BadgeHelper)
- `lc_badge_class(tone: :neutral, shape: :rounded, extra: nil)` (BadgeHelper)
- `lc_toggle_class(active: false, ghost: false, size: :md, extra: nil)` (BadgeHelper)
- `lc_button_class(variant: :primary, tone: :default, size: :md, block: false, extra: nil)` (ButtonHelper)
- `lc_select_trigger_class(size: :md, block: false, extra: nil)` (ButtonHelper)
- `lc_icon_button_class(shape: :square, size: :md, variant: :ghost, tone: :default, extra: nil)` (ButtonHelper)
- `lc_card_class(interactive: false, padding: :md, extra: nil)` (CardHelper)
- `lc_choice_label_class(card: false, extra: nil)` (ChoiceHelper)
- `lc_checkbox_class(extra: nil)` (ChoiceHelper)
- `lc_radio_class(extra: nil)` (ChoiceHelper)
- `lc_switch_class(extra: nil)` (ChoiceHelper)
- `lc_dialog_class(kind = :modal, size: nil, extra: nil)` (DialogHelper)
- `lc_emoji_picker_groups` (EmojiPickerHelper)
- `lc_emoji_picker_count` (EmojiPickerHelper)
- `lc_emoji_picker_version` (EmojiPickerHelper)
- `lc_emoji_picker_search_text(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_search_name(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_search_labels(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_toneable?(emoji)` (EmojiPickerHelper)
- `lc_alert_class(extra: nil)` (FeedbackHelper)
- `lc_alert_icon(tone: :destructive)` (FeedbackHelper)
- `lc_spinner_class(size: :md, extra: nil)` (FeedbackHelper)
- `lc_skeleton_class(extra: nil)` (FeedbackHelper)
- `lc_empty_state_class(extra: nil)` (FeedbackHelper)
- `lc_toggle_group_class(extra: nil)` (FormHelper)
- `lc_toggle_group_item_class(active: false, extra: nil)` (FormHelper)
- `lc_input_class(size: :md, plain: false, extra: nil)` (FormHelper)
- `lc_select_class(size: :md, extra: nil)` (FormHelper)
- `lc_textarea_class(extra: nil)` (FormHelper)
- `lc_field_class(size: :md, extra: nil)` (FormHelper)
- `lc_field_label_class(size: :md, extra: nil)` (FormHelper)
- `lc_glass_class(shape: :bar, thick: false, extra: nil)` (GlassHelper)
- `lc_stack_class(gap: :content, extra: nil)` (LayoutHelper)
- `lc_inline_class(gap: :related, extra: nil)` (LayoutHelper)
- `lc_container_class(size: :page, extra: nil)` (LayoutHelper)
- `lc_section_header_class(extra: nil)` (LayoutHelper)
- `lc_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_option_class(tone: :default, extra: nil)` (MenuHelper)
- `lc_link_class(tone: :inherit, extra: nil)` (NavigationHelper)
- `lc_nav_link_class(compact: false, layout: :column, extra: nil)` (NavigationHelper)
- `lc_prose_class(extra: nil)` (ReadingHelper)
- `lc_table_class(extra: nil)` (TableHelper)
- `lc_tw(*classes)` (TailwindHelper)
- `lc_heading_class(size: :heading, trim: false, extra: nil)` (TypographyHelper)
- `lc_text_class(size: :body, tone: :default, trim: false, extra: nil)` (TypographyHelper)
- `lc_kbd_class(extra: nil)` (TypographyHelper)
- `lc_shortcut_data(keys, data = {})` (TypographyHelper)
<!-- /builders -->

## Blocks

[Browse the blocks](https://ui.lostcoords.com/blocks.html) for complete layouts assembled from the
existing components. Each block has an interactive preview and the ERB, CSS and JavaScript that
render it. Copy the files into your app and adapt the content, routes and actions.

Blocks live in the docs app. They add no rendering helpers or installable block APIs to the gem.

## Docs

The docs app lives in `test/dummy`. Run `parcela up --detach` and open https://ui.localhost.
Parcela starts Rails (with live reload through Hotwire Spark) and the Tailwind watcher.
`parcela down` stops this environment.

`bin/rails kiln:build` exports every docs route to `docs/` for GitHub Pages with
[Kiln](https://github.com/davafons/kiln): pages, blocks, the token reference, the machine-readable API and
assets. Param sources for the component and block pages live in `test/dummy/config/kiln.rb`, and a route
without one fails the build. `bin/rails kiln:serve` serves the export the way GitHub Pages does. CI runs
`bin/rails kiln:build` and fails when `docs/` changes, and checks that every public rendering helper has a
runnable example.

## Development

```sh
bundle install && npm ci
bin/rails server            # the dummy app in test/dummy
bin/rails tailwindcss:build
bin/test
bin/lint
npx playwright install chromium   # once
bin/browser-test            # every suite in test/browser, headless, against its own docs server
bin/browser-test sheets     # one suite; BASE_URL=https://ui.localhost reuses a running server
```

The icon catalog and its MIT license live in `vendor/heroicons`. Regenerate them from the pinned
upstream archive with `ruby bin/update-icons`.
