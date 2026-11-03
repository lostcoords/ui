# lostcoords-ui

Render complete UI components from Rails ERB. Helpers include semantic HTML, accessible attributes and
Stimulus wiring. Tailwind v4 supplies the styles; Propshaft and importmap load the browser modules.

```erb
<%= ui_button "Save changes", type: :submit, icon: "check" %>
<%= ui_button_link_to "Projects", projects_path, variant: :secondary %>

<%= ui_card do %>
  <%= ui_field label: "Project name", id: "project-name" do |field| %>
    <%= ui_input name: "project[name]", **field %>
  <% end %>
<% end %>
```

The Rails adapter is available today. Tokens, semantic HTML and data/ARIA behavior form the shared
foundation; future framework adapters can reuse that foundation. Each host application's lockfile pins
its gem revision, so publishing a library update does not upgrade consumers.

## Install

```ruby
gem "lostcoords-ui", github: "lostcoords/ui"
```

The engine adds its rendering helpers to host views, its JavaScript to the asset paths and its pins to
the importmap. Translations live under `lostcoords.ui.*`.

### Stylesheet

Tailwind CSS v4 is required. Use `tailwindcss-rails` 4.4 or later to compile the component styles and
your app's utilities. Add the gem's entry to `app/assets/tailwind/application.css`:

```css
@layer theme, base, layout, components, modules, utilities;

@import "tailwindcss/theme.css" layer(theme);
@import "tailwindcss/preflight.css" layer(base);
@import "tailwindcss/utilities.css" layer(utilities);

@plugin "@tailwindcss/typography";

@import "../builds/tailwind/lostcoords_ui.css";
```

Tailwind resolves `@import` by path, and Bundler decides where the gem lives. tailwindcss-rails' `tailwindcss:engines`
task, which runs before every `tailwindcss:build` and `tailwindcss:watch` (and so before `assets:precompile`), writes
`app/assets/builds/tailwind/lostcoords_ui.css` with the absolute path to the gem's
`app/assets/tailwind/lostcoords_ui/engine.css`. `app/assets/builds` is already ignored by a Rails app's `.gitignore`
and `.dockerignore`, so there is nothing to commit. The file does not exist until the first Tailwind build, so a lint
that checks imports should skip it.

The gem's stylesheets write into the `components` and `modules` layers, so the host declares that layer order.
The theme defines the `dark:` variant with `html[data-theme="dark"]`. `ui.css` carries its own `@source` lines, so Tailwind
scans the gem's helpers, views and JavaScript wherever the gem is installed.

### Theming

The engine includes a complete light and dark theme, system fonts, shadows, glass effects and motion
settings. Components work without an app-owned token file. To activate dark mode, set
`data-theme="dark"` on `<html>`. Your app controls the switch and saved preference.

To customize the theme, add CSS variable overrides after the engine import:

```css
:root {
  --sky: oklch(52% 0.14 155);
  --sky-deep: oklch(46% 0.14 155);
  --sky-soft: oklch(96% 0.02 155);
}

html[data-theme="dark"] {
  --sky: oklch(75% 0.14 155);
  --sky-deep: oklch(70% 0.14 155);
  --sky-soft: color-mix(in oklab, var(--sky) 18%, var(--paper));
}
```

Override only the values you need. The [theming guide](https://ui.lostcoords.com/theming.html) covers
colors, fonts, corners, shadows and advanced variables. Defaults live in
`app/assets/tailwind/lostcoords/ui/theme.css`. `Lostcoords::Ui::TOKENS` lists the variables in that file
for reference; apps do not have to define them.

### Importmap

The engine pins its modules under the host's own keys, `controllers/*` and `helpers/*`, so
`eagerLoadControllersFrom("controllers", application)` registers the gem's controllers with no extra wiring.
A host file with the same name, such as `app/javascript/controllers/sheet_controller.js`, shadows the gem's.

## Components

[Installation and setup](https://ui.lostcoords.com/installation.html) · [Live examples](https://ui.lostcoords.com). Each example renders the same ERB source shown
in its code panel. The API reference reads signatures from the helper definitions.
[API JSON](https://ui.lostcoords.com/api.json) and [llms.txt](https://ui.lostcoords.com/llms.txt)
include those signatures and the runnable examples.

Buttons use `primary`, `secondary`, `ghost` or `destructive`, with `sm`, `base` or `lg` sizes.
`ui_button_to` preserves Rails' form, HTTP method and CSRF behavior. Block helpers capture ERB content.
Use `icon: "plus"` for a leading Heroicon or `icon_position: :end` for a trailing one. Custom icons and
spinners use `data-icon="inline-start"` or `data-icon="inline-end"`; buttons adjust that edge's padding.

```erb
<%= ui_button_to "Archive", project_path(@project), method: :delete, variant: :destructive %>
<%= ui_icon_button "Settings", icon: "cog-6-tooth" %>

<%= ui_button class: "w-full", data: { action: "editor#save" }, aria: { busy: true } do %>
  <%= ui_spinner size: :sm %>
  Saving…
<% end %>
```

Use native attributes for application behavior, `class:` to merge additional Tailwind utilities, and
theme tokens to restyle the library. `ui_field` yields the input's `id` and validation attributes so
labels, hints and errors stay connected. Linked cards use `ui_card(href: ...)`; cards containing
buttons or fields remain ordinary containers.

## Advanced style composition

### Typography and layout

The engine stylesheet includes shared text styles and layout defaults. Heading level controls document
structure independently of its visual size. Layout parents own the spacing between children, including fields.

```erb
<%= ui_stack gap: :section do %>
  <%= ui_heading "Workspace", level: 1, size: :page %>
  <%= ui_section title: "Members" do %>
    <%= ui_card do %>
      <%= ui_stack gap: :related do %>
        <%= ui_heading "Design team", level: 3, size: :card %>
        <%= ui_text "Three people share this workspace.", tone: :muted %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

Heading sizes are `page`, `section` and `card`. Text sizes are `body`, `small` and `caption`,
with `default`, `muted` and `subtle` tones. Stacks and inline groups accept `tight` (4px), `related`
(8px), `heading` (12px), `content` (16px), `inset` (20px) and `section` (32px) gaps at the default
browser font size. `ui_section` leaves 12px below its heading and 16px between content blocks.
`ui_container` provides `page`, `reading` and `form` widths. Only the page container adds gutters.

Fonts and colours come from the shared theme and your app's overrides. Optional custom properties override the shared defaults:
`--ui-space-section`, `--ui-heading-page-size`, `--ui-heading-page-line-height`, `--ui-page-max`,
`--ui-gutter` and `--ui-reading-measure`. Set them in the host theme or on a container. Japanese headings
inherit `lang="ja"` and use natural letter spacing.

[Browse the foundations examples](https://ui.lostcoords.com/components/foundations.html).

### Reading content

For articles or rendered Markdown, enable Tailwind Typography in the host input:

```css
@plugin "@tailwindcss/typography";
```

The standalone Tailwind CLI used by `tailwindcss-rails` includes this plugin. `ui_prose` supplies the host
theme colours, a 65ch maximum width, 1.75 line height and proportional block spacing. Its block follows
Rails' normal escaping rules; sanitise rendered user content before marking it safe.

```erb
<%= ui_prose do %>
  <h2>Share a workspace</h2>
  <p>Invite your team and keep your work together.</p>
  <div class="not-prose"><%= ui_button "Invite someone" %></div>
<% end %>
```

Override `--ui-reading-size`, `--ui-reading-leading`, `--ui-reading-flow` and `--ui-reading-measure`
to tune a reading context. Use `not-prose` for embedded components.

### Class helpers

Class helpers remain available for custom markup. The application owns its semantics and behavior.
`glass_class` supplies translucent surfaces; `tw` merges utilities with the last class winning.

```erb
<nav class="<%= glass_class(shape: :bar) %>" aria-label="Project navigation">
  <%= link_to "Overview", project_path(@project), class: button_class(variant: :ghost) %>
</nav>
```

Generated by `bin/rails lostcoords:ui:builders`; `bin/lint` checks this list against the style helpers.

<!-- builders -->
- `icon_badge_class(size: :base, extra: nil)` (BadgeHelper)
- `icon_medallion_class(size: :sm, tone: :accent, extra: nil)` (BadgeHelper)
- `avatar_class(size: :base, ink: false, linked: false, extra: nil)` (BadgeHelper)
- `avatar_stack_class(compact: false, extra: nil)` (BadgeHelper)
- `avatar_stack_row_class(extra: nil)` (BadgeHelper)
- `eyebrow_class(extra: nil)` (BadgeHelper)
- `badge_class(tone: :neutral, extra: nil)` (BadgeHelper)
- `status_pill_class(tone: :accent, extra: nil)` (BadgeHelper)
- `pill_class(active: false, ghost: false, size: :base, extra: nil)` (BadgeHelper)
- `pill_row_class(extra: nil)` (BadgeHelper)
- `button_class(variant: :default, size: :base, block: false, extra: nil)` (ButtonHelper)
- `icon_button_class(shape: :square, size: :base, extra: nil)` (ButtonHelper)
- `card_class(interactive: false, dense: false, extra: nil)` (CardHelper)
- `card_surface_class(extra: nil)` (CardHelper)
- `form_card_class(padding: :default, extra: nil)` (CardHelper)
- `dialog_class(kind = :modal, extra: nil)` (DialogHelper)
- `dialog_surface_class(extra: nil)` (DialogHelper)
- `emoji_picker_groups` (EmojiPickerHelper)
- `emoji_picker_count` (EmojiPickerHelper)
- `emoji_picker_version` (EmojiPickerHelper)
- `emoji_picker_search_text(emoji)` (EmojiPickerHelper)
- `emoji_picker_search_name(emoji)` (EmojiPickerHelper)
- `emoji_picker_search_labels(emoji)` (EmojiPickerHelper)
- `emoji_picker_toneable?(emoji)` (EmojiPickerHelper)
- `spinner_class(size: :base, extra: nil)` (FeedbackHelper)
- `skeleton_class(extra: nil)` (FeedbackHelper)
- `empty_state_class(extra: nil)` (FeedbackHelper)
- `segmented_class(extra: nil)` (FormHelper)
- `segmented_tab_class(active: false, extra: nil)` (FormHelper)
- `input_class(size: :base, extra: nil)` (FormHelper)
- `dropdown_trigger_class(size: :base, extra: nil)` (FormHelper)
- `select_class(size: :base, extra: nil)` (FormHelper)
- `textarea_class(extra: nil)` (FormHelper)
- `field_class(extra: nil)` (FormHelper)
- `field_label_class(extra: nil)` (FormHelper)
- `form_actions_class(extra: nil)` (FormHelper)
- `form_alert_class(extra: nil)` (FormHelper)
- `form_alert_icon(tone: :error)` (FormHelper)
- `glass_class(shape: :bar, thick: false, extra: nil)` (GlassHelper)
- `stack_class(gap: :content, extra: nil)` (LayoutHelper)
- `inline_class(gap: :related, extra: nil)` (LayoutHelper)
- `container_class(size: :page, extra: nil)` (LayoutHelper)
- `section_header_class(extra: nil)` (LayoutHelper)
- `popover_class(align: :end, extra: nil)` (MenuHelper)
- `menu_popover_class(align: :end, extra: nil)` (MenuHelper)
- `menu_option_class(tone: :default, extra: nil)` (MenuHelper)
- `prose_class(extra: nil)` (ReadingHelper)
- `sheet_data(data = {}, detents: "fit")` (SheetHelper)
- `sheet_row_class(extra: nil)` (SheetHelper)
- `sheet_row_label_class(extra: nil)` (SheetHelper)
- `sheet_chip_class(active: false, member: false, extra: nil)` (SheetHelper)
- `sheet_datetime_input_class(extra: nil)` (SheetHelper)
- `sheet_text_input_class(extra: nil)` (SheetHelper)
- `tw(*classes)` (TailwindHelper)
- `heading_class(size: :section, extra: nil)` (TypographyHelper)
- `text_class(size: :body, tone: :default, extra: nil)` (TypographyHelper)
<!-- /builders -->

## Blocks

[Browse the blocks](https://ui.lostcoords.com/blocks.html) for complete layouts assembled from the
existing components. Each block has an interactive preview and the ERB, CSS and JavaScript that
render it. Copy the files into your app and adapt the content, routes and actions.

Blocks live in the docs app. They add no rendering helpers or installable block APIs to the gem.

## Docs

The docs app lives in `test/dummy`. Run `parcela up --detach` and open https://ui.localhost.
Parcela starts Rails and the Tailwind watcher. `parcela down` stops this environment.

`bin/rails lostcoords:ui:showcase` exports the home, component pages, blocks, token reference, machine-readable
API and assets to `docs/` for GitHub Pages. CI checks that the export matches the source and that every
public rendering helper has a runnable example.

## Development

```sh
bundle install && npm ci
bin/rails server            # the dummy app in test/dummy
bin/rails tailwindcss:build
bin/test
bin/lint
```
