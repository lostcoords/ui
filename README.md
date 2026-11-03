# lostcoords-ui

Render complete UI components from Rails or standalone ActionView ERB. Helpers include semantic HTML,
accessible attributes and Stimulus wiring. Tailwind v4 supplies the styles. Rails integrates Propshaft
and importmap automatically; standalone applications own their asset build.

```erb
<%= lc_button "Save changes", type: :submit, icon: "check" %>
<%= lc_button_link_to "Projects", projects_path, variant: :secondary %>

<%= lc_card do %>
  <%= lc_field label: "Project name", id: "project-name" do |field| %>
    <%= lc_input name: "project[name]", **field %>
  <% end %>
<% end %>
```

The supported stack is ActionView, ERB, Tailwind and Stimulus. Each host application's lockfile pins
its gem version, so publishing a library update does not upgrade consumers.

## Install

```ruby
gem "lostcoords-ui", "~> 0.4.0"
```

The engine adds its rendering helpers to host views, its JavaScript to the asset paths and its pins to
the importmap. Translations live under `lostcoords.ui.*`.

### Standalone ActionView

```ruby
require "lostcoords/ui/action_view"

class ViewContext < ActionView::Base
  include Lostcoords::Ui::Helpers
end

view = ViewContext.with_empty_template_cache.with_view_paths(Lostcoords::Ui.view_paths)
view.lc_button("Save", icon: "check")
```

For an existing view context, include the helpers and append `Lostcoords::Ui.view_paths` to its
lookup paths after application paths. The loader registers the library's translations without changing
the default locale. If the host has its own locale handling, override private `lc_locale` in the view
context; components do not call the host's `t` helper.

Standalone applications compile Tailwind and register Stimulus controllers through their own asset
pipeline. `Lostcoords::Ui.root` locates the gem's source assets. Rails applications receive automatic
registration; use `require "lostcoords/ui/rails"` explicitly if Rails loads after the components.

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
`lc_button_to` preserves Rails' form, HTTP method and CSRF behavior. Block helpers capture ERB content.
Use `icon: "plus"` for a leading Heroicon or `icon_position: :end` for a trailing one. Custom icons and
spinners use `data-icon="inline-start"` or `data-icon="inline-end"`; buttons adjust that edge's padding.

```erb
<%= lc_button_to "Archive", project_path(@project), method: :delete, variant: :destructive %>
<%= lc_icon_button "Settings", icon: "cog-6-tooth" %>

<%= lc_button class: "w-full", data: { action: "editor#save" }, aria: { busy: true } do %>
  <%= lc_spinner size: :sm %>
  Saving…
<% end %>
```

Use native attributes for application behavior, `class:` to merge additional Tailwind utilities, and
theme tokens to restyle the library. `lc_field` yields the input's `id` and validation attributes so
labels, hints and errors stay connected. Linked cards use `lc_card(href: ...)`; cards containing
buttons or fields remain ordinary containers.

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

The component emits bubbling `ui-copy:copied` (`detail.text`) and `ui-copy:error` (`detail.error`) events
from its wrapper. Listen on an ancestor to connect application behavior. The documentation uses the error
event to reveal clipped source code for manual copying.

Buttons include hover and press feedback. Override `--ui-motion-quick` (140ms), `--ui-motion-control` (180ms),
`--ui-motion-feedback` (160ms), `--ui-press-scale` (0.96) and `--ease-out` in your theme or on a container.
Reduced motion removes control movement and makes copy feedback immediate. Your application owns the
pending, success and failure states of network actions such as saving a form.

[Try the copy button](https://ui.lostcoords.com/components/copy_button.html) ·
[Motion reference](https://ui.lostcoords.com/components/motion.html)

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

The engine stylesheet includes shared text styles and layout defaults. Heading level controls document
structure independently of its visual size. Layout parents own the spacing between children, including fields.
Inline `<code>` elements get a shared monospace style with a theme-aware background. `<pre><code>`
blocks keep their block styling.

```erb
<%= lc_stack gap: :section do %>
  <%= lc_heading "Workspace", level: 1, size: :page %>
  <%= lc_section title: "Members" do %>
    <%= lc_card do %>
      <%= lc_stack gap: :related do %>
        <%= lc_heading "Design team", level: 3, size: :card %>
        <%= lc_text "Three people share this workspace.", tone: :muted %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

Heading sizes are `page`, `section` and `card`. Text sizes are `body`, `small` and `caption`,
with `default`, `muted` and `subtle` tones. Stacks and inline groups accept `tight` (4px), `related`
(8px), `heading` (12px), `content` (16px), `inset` (20px) and `section` (32px) gaps at the default
browser font size. `lc_section` leaves 12px below its heading and 16px between content blocks.
`lc_container` provides `page`, `reading` and `form` widths. Only the page container adds gutters.

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

Override `--ui-reading-size`, `--ui-reading-leading`, `--ui-reading-flow` and `--ui-reading-measure`
to tune a reading context. Use `not-prose` for embedded components.

### Class helpers

Class helpers remain available for custom markup. The application owns its semantics and behavior.
`lc_glass_class` supplies translucent surfaces; `lc_tw` merges utilities with the last class winning.

```erb
<nav class="<%= lc_glass_class(shape: :bar) %>" aria-label="Project navigation">
  <%= link_to "Overview", project_path(@project), class: lc_button_class(variant: :ghost) %>
</nav>
```

Generated by `bin/rails lostcoords:ui:builders`; `bin/lint` checks this list against the style helpers.

<!-- builders -->
- `lc_icon_badge_class(size: :base, extra: nil)` (BadgeHelper)
- `lc_icon_medallion_class(size: :sm, tone: :accent, extra: nil)` (BadgeHelper)
- `lc_avatar_class(size: :base, ink: false, linked: false, extra: nil)` (BadgeHelper)
- `lc_avatar_stack_class(compact: false, extra: nil)` (BadgeHelper)
- `lc_avatar_stack_row_class(extra: nil)` (BadgeHelper)
- `lc_eyebrow_class(extra: nil)` (BadgeHelper)
- `lc_badge_class(tone: :neutral, extra: nil)` (BadgeHelper)
- `lc_status_pill_class(tone: :accent, extra: nil)` (BadgeHelper)
- `lc_pill_class(active: false, ghost: false, size: :base, extra: nil)` (BadgeHelper)
- `lc_pill_row_class(extra: nil)` (BadgeHelper)
- `lc_button_class(variant: :default, size: :base, block: false, extra: nil)` (ButtonHelper)
- `lc_icon_button_class(shape: :square, size: :base, extra: nil)` (ButtonHelper)
- `lc_card_class(interactive: false, dense: false, extra: nil)` (CardHelper)
- `lc_card_surface_class(extra: nil)` (CardHelper)
- `lc_form_card_class(padding: :default, extra: nil)` (CardHelper)
- `lc_dialog_class(kind = :modal, extra: nil)` (DialogHelper)
- `lc_dialog_surface_class(extra: nil)` (DialogHelper)
- `lc_emoji_picker_groups` (EmojiPickerHelper)
- `lc_emoji_picker_count` (EmojiPickerHelper)
- `lc_emoji_picker_version` (EmojiPickerHelper)
- `lc_emoji_picker_search_text(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_search_name(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_search_labels(emoji)` (EmojiPickerHelper)
- `lc_emoji_picker_toneable?(emoji)` (EmojiPickerHelper)
- `lc_spinner_class(size: :base, extra: nil)` (FeedbackHelper)
- `lc_skeleton_class(extra: nil)` (FeedbackHelper)
- `lc_empty_state_class(extra: nil)` (FeedbackHelper)
- `lc_segmented_class(extra: nil)` (FormHelper)
- `lc_segmented_tab_class(active: false, extra: nil)` (FormHelper)
- `lc_input_class(size: :base, extra: nil)` (FormHelper)
- `lc_dropdown_trigger_class(size: :base, extra: nil)` (FormHelper)
- `lc_select_class(size: :base, extra: nil)` (FormHelper)
- `lc_textarea_class(extra: nil)` (FormHelper)
- `lc_field_class(extra: nil)` (FormHelper)
- `lc_field_label_class(extra: nil)` (FormHelper)
- `lc_form_actions_class(extra: nil)` (FormHelper)
- `lc_form_alert_class(extra: nil)` (FormHelper)
- `lc_form_alert_icon(tone: :error)` (FormHelper)
- `lc_glass_class(shape: :bar, thick: false, extra: nil)` (GlassHelper)
- `lc_stack_class(gap: :content, extra: nil)` (LayoutHelper)
- `lc_inline_class(gap: :related, extra: nil)` (LayoutHelper)
- `lc_container_class(size: :page, extra: nil)` (LayoutHelper)
- `lc_section_header_class(extra: nil)` (LayoutHelper)
- `lc_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_option_class(tone: :default, extra: nil)` (MenuHelper)
- `lc_prose_class(extra: nil)` (ReadingHelper)
- `lc_sheet_data(data = {}, detents: "fit")` (SheetHelper)
- `lc_sheet_row_class(extra: nil)` (SheetHelper)
- `lc_sheet_row_label_class(extra: nil)` (SheetHelper)
- `lc_sheet_chip_class(active: false, member: false, extra: nil)` (SheetHelper)
- `lc_sheet_datetime_input_class(extra: nil)` (SheetHelper)
- `lc_sheet_text_input_class(extra: nil)` (SheetHelper)
- `lc_tw(*classes)` (TailwindHelper)
- `lc_heading_class(size: :section, extra: nil)` (TypographyHelper)
- `lc_text_class(size: :body, tone: :default, extra: nil)` (TypographyHelper)
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

The helper migration tool updates Ruby calls, ERB code, and Ruby/ERB Markdown examples to the `lc_`
namespace. Run it in a consumer checkout to preview changes, then add `--write` to apply them.
Review dynamic method names stored in strings separately.

```sh
ruby "$(bundle show lostcoords-ui)/script/migrate_helpers.rb" .
ruby "$(bundle show lostcoords-ui)/script/migrate_helpers.rb" . --write
```

The icon catalog and its MIT license live in `vendor/heroicons`. Regenerate them from the pinned
upstream archive with `ruby bin/update-icons`.
