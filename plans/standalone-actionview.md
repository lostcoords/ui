# Shared ActionView components with optional Rails integration

Status: standalone rendering and the lc_ helper API are implemented.
Explicit JavaScript registration, component-only CSS, and site-owned Bun integration remain planned.

## Outcome

Use the same ERB components, variants, Stimulus behavior, and motion in WariWari,
Shirabe, and davafons.com. Rails applications receive automatic integration;
standalone ActionView applications receive explicit rendering and asset APIs.

Keep one gem and one component implementation focused on Rails/ActionView, ERB,
Tailwind, and Stimulus. Supporting standalone ActionView does not change that
product scope. Svelte is the only currently anticipated future framework adapter;
it is deferred, with no adapter API or universal component runtime built now.

The first delivery is a real davafons.com integration. Completion requires more
than successful loading: rendered markup, compiled styles, icons, translated
labels, JavaScript behavior, and navigation cleanup must work together.

## Consumer integration

| Consumer | Observed integration | Constraint |
| --- | --- | --- |
| lostcoords-ui showcase | Rails engine, Propshaft, importmap, Tailwind engine entry | Preserve the current installation and generated documentation |
| WariWari | Git-sourced gem, importmap, Stimulus; app helpers extend variant maps; controllers subclass FloatingPanel and CatalogPicker | Preserve controller identifiers, helper overrides, and existing helper import keys |
| Shirabe | Rails, Propshaft, importmap, Stimulus, Heroicons; no lostcoords-ui dependency in the inspected Gemfile | Treat adoption as future validation, not an existing passing integration |
| davafons.com | Standalone ActionView 8.1, custom ViewContext and LookupContext, Tailwind v4, Bun bundling, Turbo | No Rails boot, no Propshaft or importmap dependency; resolve the installed gem through Bundler |

The site's checked-in package.json and application.js do not currently install or
start Stimulus. Its integration therefore adds Stimulus and starts one application.
Existing plain-JavaScript components can continue alongside it.

The site constructs its own LookupContext, so configuring class-level view paths
alone would not install the library's partials. It also defines a custom t helper
and Tailwind tokens such as --color-ink and --color-accent. These are concrete
integration constraints, not reasons to redesign its application.

## Consumer usage first

Proposed standalone Ruby setup:

```ruby
# Gemfile
gem "lostcoords-ui", github: "lostcoords/ui", require: "lostcoords/ui/action_view"

# Explicitly require this in the site's bootstrap; bundle exec alone does not
# execute the Gemfile's require option.
require "lostcoords/ui/action_view"

# Existing ViewContext
class ViewContext < ActionView::Base
  include Lostcoords::Ui::Helpers

  # Existing application helpers remain included here.

  # In the existing initializer, preserve application paths before gem paths.
  # lookup_context ||= ActionView::LookupContext.new(
  #   [Config::Paths::VIEWS.to_s, *Lostcoords::Ui.view_paths], {}, []
  # )

  private

  def lc_locale = locale
end

# Once during the site's existing Ruby bootstrap:
Lostcoords::Ui.load_translations!
```

Existing templates use the same lc_button, lc_input, lc_card, lc_disclosure, and
lc_copy_button APIs. No standalone-specific component names.

Bun integration belongs in davafons.com. Its existing SiteBuilder resolves
Lostcoords::Ui.root through Bundler and owns any generated CSS import or Bun module
resolver. For example, the site can write an ignored CSS entry importing the gem's
component stylesheet, and resolve library helper imports to their shipped files
while resolving @hotwired/stimulus from the site's node_modules.

The gem exposes source assets and a proposed explicit registerControllers entry.
It does not contain Assets.prepare, a Bun configuration, or a source-export API.
The site starts its one Stimulus application and registers the library controllers
it actually uses. Exact build wiring is implemented and verified in the site.

Rails applications retain their existing Gemfile setup, controller IDs, importmap
pins, and default stylesheet behavior. All library helper names and extension
hooks use lc_; consumers migrate their callers with the helper migration tool. An explicit
lostcoords/ui/rails entry is also available when Rails loads after the core.

## Ownership and module boundaries

| Module | Owns | Must not own |
| --- | --- | --- |
| Resources | Gem root, partial paths, locale paths, emoji data, stylesheet and JavaScript paths | Rails engine lookup or application filesystem conventions |
| ActionView layer | Helper loading, HTML semantics, escaping, variants, partial rendering, component translation and icon hooks | Rails boot, asset compilation, Stimulus startup |
| Styles | Component appearance, token defaults, motion, attribute-based state styling | Application theme preference, application page layout |
| Browser modules | Component interaction and browser effects; Stimulus lifecycle today | Propshaft configuration, importmap registration, Bun configuration |
| Rails integration | Helper registration, reloading, asset paths, optional importmap integration, Rails request-aware helpers | A second component implementation |
| Site build integration | Resolving gem assets, Bun module resolution, generated CSS imports, package installation, public output hashing | Changes to component behavior or copies of maintained library source |
| Host application | Theme overrides, application actions, build pipeline, navigation, data endpoints | Copies of maintained library source |

Proposed new files, retaining existing helpers, partials, CSS, and controllers:

```text
lib/lostcoords/ui.rb                  # compatible top-level loader
lib/lostcoords/ui/action_view.rb      # explicit standalone loader
lib/lostcoords/ui/rails.rb            # explicit Rails loader
lib/lostcoords/ui/resources.rb        # paths independent of Engine.root
lib/lostcoords/ui/helpers.rb          # one helper composition and load order
lib/lostcoords/ui/icons.rb            # standalone trusted-SVG rendering
lib/lostcoords/ui/engine.rb           # Rails registration only
app/assets/tailwind/lostcoords/ui/components.css
app/assets/tailwind/lostcoords/ui/base.css
app/javascript/lostcoords/ui/index.js # explicit controller registration
test/standalone/                      # separate entry; no Rails test_helper
```

The rendering API exposes Lostcoords::Ui.root, Lostcoords::Ui.view_paths,
Lostcoords::Ui.load_translations!, and Lostcoords::Ui::Helpers. The host explicitly
includes Helpers and installs the view paths in its existing lookup context.

## Loading, dependencies, translations, and icons

The standalone loader explicitly loads ActionView, required ActiveSupport
extensions, the helper composition, and component dependencies. It never requires
the Rails entry, importmap-rails, or Heroicons' Rails entry point. Helpers must load
deterministically without Zeitwerk; retain one authoritative composition rather
than separate helper lists for each consumer. Change emoji paths to Resources.

The top-level loader loads the ActionView layer and registers Rails integration
only when Rails::Engine is already available. The explicit Rails loader handles
other load orders. Keep Rails autoloading of helper constants consistent with the
explicit composition and verify reloading does not create duplicate modules.

Replace the mandatory full-rails dependency with the ActionView and ActiveSupport
dependencies actually used. Move importmap-rails to host integration and the
development Gemfile. Rails integration checks whether importmap is configured
before adding pins; a standalone process never loads it. Rails remains a
development/test dependency for the showcase.

The gem ships upstream Heroicons v2.2.0 as a generated SVG catalog with its MIT license.
The checksum-pinned bin/update-icons imports the optimized outline, solid, mini,
and micro sets directly from upstream.

Use public lc_icon(name, variant: :outline, options: {}, path_options: {}) for all
icons. It renders trusted catalog SVG with escaped caller attributes, validates
names and variants. Applications configure sizes through arguments or their own
lc_icon wrapper.

Introduce private lc_t and lc_locale hooks. lc_t calls I18n with the
lostcoords.ui namespace and explicit lc_locale; it never calls the host's t.
Default lc_locale to I18n.locale. The site overrides that hook to its existing
per-view locale. load_translations! inserts library locale paths before host paths
once, before the first render, without changing the application's default locale
or available locales. Application overrides win. Both Rails and standalone use
this same translation path.

Keep request-aware features such as lc_button_to in Rails integration with their
existing form, method, and CSRF semantics. Do not emulate server actions on the
static site. Ordinary ActionView form fields and builders are not inherently
Rails-only; classify other helpers by their real dependencies.

## CSS and theme integration

Keep the existing Ruby class builders and variant extension hooks in this delivery,
renamed consistently with lc_.
Converting all components to semantic classes or a generated recipe format is a
separate migration that the two ActionView consumers do not require.

Split component styling from document styling:

- components.css contains component rules, required Tailwind mappings, motion and
  default tokens, plus source declarations that scan gem helpers, views, and JS.
- base.css contains document-wide body, heading, and element defaults. Move global
  focus and motion behavior with care; components must retain accessible focus
  and reduced-motion behavior when base.css is absent.
- ui.css remains the existing full entry, importing components.css and base.css.
  engine.css continues to reach it through tailwindcss-rails' engine convention.

The site imports components.css through its generated bridge. It keeps its own
Tailwind @theme declarations after that import and supplies a small host-owned
mapping from library variables such as --paper, --ink, and --sky to its existing
--color-canvas, --color-ink, and --color-accent values. Check actual generated CSS
for collisions and self-referential variables. A different stylesheet order is
not acceptable if it silently changes existing text-ink or font-mono utilities.

Keep the current token names initially. Do not introduce a token rename, multiple
scoped theme engines, or precompiled CSS distribution in this delivery. Apps
already compile Tailwind; gem source scanning remains part of that build.

## JavaScript delivery and compatibility

Keep Stimulus as the supported component lifecycle. Keep the existing helpers/*
and controllers/* module identifiers in source and in the Rails importmap so
WariWari imports and host-file shadowing keep working. Propshaft fingerprints JS
filenames but does not generally rewrite relative ESM imports. Switching source
imports to relative paths alone would therefore risk production asset failures.

The site's Bun configuration resolves those library-owned module identifiers to
the gem's source files and @hotwired/stimulus to the site's installed package.
Keep that resolver in davafons.com; do not rewrite component source or add a Bun
adapter to the gem. Verify every shared service has one module identity per
consumer; duplicate dismiss stacks or scroll-lock coordinators are a failure.

index.js exports registerControllers(application, { only } = {}). It imports
controllers statically, never starts Stimulus, and never auto-registers on import.
Unknown requested IDs fail clearly. Repeating registration on the same application
must not replace host overrides. Register library defaults before app overrides;
test the completeness of the registry against shipped controller files.

Any generated import entry belongs to the site's ignored build inputs. It is
regenerated from the Bundler-resolved gem path before the site's asset build.
Absolute Bundler paths must not enter committed files or final public assets.
The library does not invoke Bun, Tailwind, or npm and does not export source
copies into consumer repositories.

Existing controller inheritance, targets, values, and method extension points stay
intact. Existing Turbo cleanup remains available because both real consumer
stacks use Turbo. Do not extract all behavior into new state machines now.
Where an existing browser-only module attaches document listeners on import,
make setup lazy and cleanup explicit when that module is touched; verify browser
imports and navigation first. A blanket SSR-safe-import promise is deferred.

## Implementation sequence and acceptance checks

Each unit ends with a demonstrable result. Run existing repository checks as
required by the changed files; the checks below describe additional behavior.

| Unit | Responsibility and likely files | Required evidence |
| --- | --- | --- |
| 1. Explicit rendering layer | Gem loaders, Resources, helper composition, emoji paths; independent standalone test entry | Public standalone loader renders button, input, and card with escaped content; also render a partial-backed disclosure and use emoji data; Rails::Engine and Rails::Application remain undefined |
| 2. Complete rendering dependencies | Icon and translation hooks, gemspec, development Gemfile, Rails facade | Icon-bearing and localized copy buttons work through the supported loader; site-like custom t is not invoked; repeated locale registration is harmless; all four bundled icon variants render safely; standalone bundle resolves without rails, railties, importmap-rails, or heroicons |
| 3. Explicit controller registration | Static registration entry and Rails asset tests in the gem | Only requested controllers register; registry covers shipped controllers; production Rails imports resolve to fingerprinted assets and each shared service has one module identity |
| 4. Component-only stylesheet | components.css, base.css, ui.css, stylesheet and theming checks | Both full and component-only entries compile; component-only controls retain focus and reduced motion; a fixture using site tokens keeps its existing body, text, accent, and fonts |
| 5. Real site adoption | davafons.com Gemfile and lock, package.json and lock, ViewContext, SiteBuilder asset step, theme mapping, selected templates | Clean build through the existing pipeline; render real button/input/card/disclosure/copy examples during integration, adopt only useful components in permanent pages; translated copy labels, navigation and clipboard behavior verified in the browser |
| 6. Consumer and documentation verification | README setup, standalone fixture instructions, Rails showcase/export, WariWari compatibility checks | Existing Rails registration, overrides, menu/dialog behavior, unit tests, lint, and export checks pass; site styles and non-library scripts still work after Turbo visits |

Standalone checks run as fresh subprocesses without test/test_helper.rb, which
boots the dummy Rails application. Include a minimal dependency fixture to prove
the removal of mandatory full Rails, not merely the absence of require calls in
the development bundle. The committed minimal bundle excludes Rails and Railties.

Keep browser assertions focused on observable behavior: menu Escape and focus,
disclosure open/close, copied/error status, and cleanup across navigation. Test
reduced motion and interrupted transitions for any changed animated component.
Do not add implementation-mirroring tests or claim visual proof from markup alone.

Use the gem's pinned source as the site integration input. A sibling checkout path
can be used during development, but permanent committed setup must not require
that checkout. No publishing, pushing, deployment, or broad site redesign belongs
to this plan's implementation units without the applicable authorization.

## Deferred boundaries and remaining decisions

A future Svelte adapter can reuse the CSS token and state conventions. Reusing
interaction logic will still require extraction from Stimulus, and sharing Ruby
variant recipes will require semantic CSS or a generated neutral recipe format.
This plan preserves those options; it does not claim that they are implemented.

Before changing JavaScript extension points, inventory the actual WariWari callers
and verify them against the resulting asset URLs. Before shipping the standalone
icon renderer, verify upstream provenance, missing-icon behavior, all supported
variants, and safe caller attributes.

The first permanent site adoption should replace an existing useful control.
The site's code-copy control is a candidate, but its current placement and visual
treatment should drive the integration. Do not commit a demonstration page as a
product feature just to satisfy the acceptance checks.

Next implementation step: add explicit controller registration in the gem, then
implement Bun asset resolution and Tailwind integration in davafons.com.
