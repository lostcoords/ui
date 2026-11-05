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
gem "lostcoords-ui", "~> 0.7.0"
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

### Standalone assets

Import `app/assets/tailwind/lostcoords/ui/components.css` from the Bundler-resolved gem root
into your Tailwind build. This entry includes component rules, default tokens and source scanning.
It does not set body styles, heading defaults, global inline-code styles or document corner radii.
Map the library's tokens to your app's theme and keep your Tailwind theme declarations after the import.
The full `ui.css` entry includes those document defaults and remains the Rails default.

Tailwind always ships component rules, used or not, and generates every utility the scanned helpers
mention. For a smaller build, import `core.css` and the opt-in components you render instead of
everything. Each entry carries the rules and scans the sources of its own component only. In Rails,
every Tailwind build writes stable paths for them next to the engine's own import:

```css
/* app/assets/tailwind/application.css, instead of ../builds/tailwind/lostcoords_ui.css */
@import "../builds/tailwind/lostcoords_ui/base.css";
@import "../builds/tailwind/lostcoords_ui/core.css";
@import "../builds/tailwind/lostcoords_ui/components/dialog.css";
@import "../builds/tailwind/lostcoords_ui/components/menu.css";
```

Outside Rails, import the same files from `app/assets/tailwind/lostcoords/ui/` in the gem.
`base.css` holds the document defaults that `ui.css` adds; skip it when the host owns its base styles.
`core.css` holds the tokens, buttons, badges, avatars, cards, alerts, form controls, choices,
toggles, layout, typography and navigation. The opt-in entries are `dialog` (with the phone sheet),
`menu` (menus and popovers), `toast`, `search`, `tooltip`, `collapsible`, `code-block`,
`emoji-picker`, `table` and `prose`. A component whose entry is missing renders unstyled.

Start one Stimulus application in the host, then register the controllers you use:

```javascript
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "lostcoords/ui"

const application = Application.start()
registerControllers(application, { only: ["lc-copy", "lc-collapsible"] })
```

Resolve `lostcoords/ui/*` to the gem's `app/javascript/lostcoords/ui/*` and `@hotwired/stimulus` to
the host's installed package. `registerControllers` imports every controller, so a bundle carries
them all; to bundle only some, import them directly:
`import Dialog from "lostcoords/ui/controllers/lc_dialog_controller"` and
`application.register("lc-dialog", Dialog)`. Build configuration belongs to the host. The entry does not start
Stimulus or register anything on import. Omit `only` to register all library controllers. Register
defaults before application overrides. Repeated calls on the same application preserve later
overrides; unknown controller identifiers raise before registration.

The gem's stylesheets write into the `components` and `modules` layers, so the host declares that layer order.
The theme defines the `dark:` variant with `html[data-theme="dark"]`. `ui.css` carries its own `@source` lines, so Tailwind
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

`lc_table` renders a native table with a shaded header and subtle row dividers. Supply the caption, header cells and body in its block.
Wrap wide tables in an app-owned horizontal scroll region with an accessible name and keyboard focus.
Use `lc_table_class` when an existing table renderer owns the markup.

Cards share one API: `lc_card(padding: :md)`, with `:sm` and `:none` for tighter or custom spacing. Padding sizes set `--lc-inset`, so content inside follows the card.
Inputs keep their `--input` fill inside cards; set `--lc-field-bg` to change it in one context. Cards provide avatar cutouts and a validation border when they contain errors. Fills that are muted on the page switch so they stay visible on the card: choice tiles, alerts, neutral badges and skeletons take the page background (`--lc-tile-bg`), and toggle group and tab tracks take the accent fill (`--lc-track-bg`). Set either variable to apply the same context to your own muted surface.
Add `class: "@container"` when a card owns its width and its children use container queries.
Use `--lc-card-bg`, `--lc-card-border`, `--lc-card-radius` and `--lc-card-shadow` for local appearance overrides.

`lc_badge` handles labels, counts and status. Use `class: "rounded-full"` for a rounded status label.
`lc_icon_badge` handles decorative icon containers, with `shape: :square` or `:circle` and `sm`, `md`, `lg` or `xl` sizes.
Badge, icon badge, Alert and Toast share `neutral`, `primary`, `success`, `warning` and `destructive` tones.

`lc_toggle` renders a pressed button. Use `lc_toggle_group` with `lc_toggle_group_item` for mutually exclusive
choices and a native submitted value; it is a radiogroup of radio buttons to assistive technology. Navigation uses `lc_button_link_to` and `aria-current`, so links keep their native behavior.
`lc_collapsible` expands content through a native `<details>` element. `lc_alert` renders persistent inline feedback;
`lc_toast` adds timed dismissal.

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
<%= lc_form_with model: @project, class: "flex flex-col gap-content" do |form| %>
  <%= form.field :name, hint: "Shown to members" %>
  <%= form.field :email, as: :email_field %>
  <%= form.switch :public %>
  <%= form.submit "Save project" %>
<% end %>
```

A symbol `size:` such as `size: :sm` picks the control height; an integer still sets the HTML
attribute. Pass `builder: Lostcoords::Ui::FormBuilder` to `form_with` directly, or call `lc_field`
with `error: record.errors.full_messages_for(:name)` when you keep your own builder.

`lc_checkbox`, `lc_radio` and `lc_switch` render native inputs with a label and optional hint.
Checkboxes and switches submit an unchecked value like Rails' `check_box`; pass `unchecked_value: nil`
to omit it. `lc_choice_group` groups them in a fieldset with a legend, hint and error.

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
and Down; `activation: :manual` moves focus with the arrows and selects with Enter or Space. Tooltips show on hover and keyboard focus, Escape hides them, and they describe
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

`lc_nav_list` marks the current link with `aria-current="page"`; `compact: true` is the quieter
style for an "On this page" list, and `indent: true` nests a link. `lc_pager` takes `[title, url]`
for each side and `compact: true` for icon buttons. `lc_link` has `inherit`, `muted` and `primary`
tones; `lc_link_class` styles links you render yourself. `lc_skip_link` targets `#main` by default.
Pass `card: true` to `lc_radio` or `lc_checkbox` for selectable tiles; a block adds content, such as a
preview, under the label.

This documentation site is built with these components and two copyable blocks: the application
header and the documentation layout.

`lc_dialog` handles modal content and the mobile sheet layout. Set `detents: "medium large"` or `"large"`
to choose mobile height stops; the default is `"fit"`. Icon buttons, avatar groups, motion and mobile dialogs
appear with their parent component examples.

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
announces the count. Pass `shortcut: nil` to drop the page shortcut, and `id:` when a page has two searches.

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
`label` and `caption`, with `default` and `muted` tones. Pass `trim: true` to trim the text box.
Stacks and inline groups take the spacing names from [Foundations](#foundations). `lc_section` leaves
`heading` below its title and `content` between blocks. `lc_container` provides `page`, `reading` and
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
- `lc_badge_class(tone: :neutral, extra: nil)` (BadgeHelper)
- `lc_toggle_class(active: false, ghost: false, size: :md, extra: nil)` (BadgeHelper)
- `lc_button_class(variant: :primary, size: :md, block: false, extra: nil)` (ButtonHelper)
- `lc_icon_button_class(shape: :square, size: :md, extra: nil)` (ButtonHelper)
- `lc_card_class(interactive: false, padding: :md, extra: nil)` (CardHelper)
- `lc_choice_label_class(card: false, extra: nil)` (ChoiceHelper)
- `lc_checkbox_class(extra: nil)` (ChoiceHelper)
- `lc_radio_class(extra: nil)` (ChoiceHelper)
- `lc_switch_class(extra: nil)` (ChoiceHelper)
- `lc_dialog_class(kind = :modal, extra: nil)` (DialogHelper)
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
- `lc_input_class(size: :md, extra: nil)` (FormHelper)
- `lc_select_class(size: :md, extra: nil)` (FormHelper)
- `lc_textarea_class(extra: nil)` (FormHelper)
- `lc_field_class(extra: nil)` (FormHelper)
- `lc_field_label_class(extra: nil)` (FormHelper)
- `lc_glass_class(shape: :bar, thick: false, extra: nil)` (GlassHelper)
- `lc_stack_class(gap: :content, extra: nil)` (LayoutHelper)
- `lc_inline_class(gap: :related, extra: nil)` (LayoutHelper)
- `lc_container_class(size: :page, extra: nil)` (LayoutHelper)
- `lc_section_header_class(extra: nil)` (LayoutHelper)
- `lc_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_popover_class(align: :end, extra: nil)` (MenuHelper)
- `lc_menu_option_class(tone: :default, extra: nil)` (MenuHelper)
- `lc_link_class(tone: :inherit, extra: nil)` (NavigationHelper)
- `lc_nav_link_class(compact: false, extra: nil)` (NavigationHelper)
- `lc_prose_class(extra: nil)` (ReadingHelper)
- `lc_sheet_data(data = {}, detents: "fit")` (SheetHelper)
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
npx playwright install chromium   # once
bin/browser-test            # every suite in test/browser, headless, against its own docs server
bin/browser-test sheets     # one suite; BASE_URL=https://ui.localhost reuses a running server
```

The icon catalog and its MIT license live in `vendor/heroicons`. Regenerate them from the pinned
upstream archive with `ruby bin/update-icons`.
