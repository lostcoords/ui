# Standalone ActionView integration

## Scope

One gem for Rails or standalone ActionView, ERB, Tailwind v4 and Stimulus.
WariWari and davafons.com validate the integration. Shirabe adoption and Svelte support remain deferred.

## Boundaries

| Owner | Responsibility |
| --- | --- |
| ActionView layer | `lc_*` rendering helpers, partials, icons and translations without a Rails application |
| Rails engine | Automatic helper registration, optional asset paths and importmap pins |
| JavaScript entry | `registerControllers(application, { only })`; host owns application startup and overrides |
| Component stylesheet | Component rules, token defaults and source scanning |
| Full stylesheet | Component styles plus document defaults, global focus, typography and corner treatment |
| davafons.com | Bundler resolution, ignored CSS import, Bun resolution, theme mapping and one Stimulus application |

The gem does not run a build tool or contain a Bun adapter. Both consumers use the same helpers,
styles and controllers. The site does not copy library source or rewrite its JavaScript imports.
Library module identifiers remain compatible with Rails importmaps and host controller overrides.

## Integration

`Lostcoords::Ui::Helpers` and `Lostcoords::Ui.view_paths` are installed in the site's existing
ViewContext. Private `lc_locale` delegates to its per-view locale. The library does not call the
site's translation helper or change its locale defaults.

The site imports `components.css` through an ignored file generated from Bundler's selected gem.
Its own theme declarations and token mapping retain the existing palette and fonts. Rails keeps
the full `ui.css` entry through the Tailwind engine convention.

The site's Bun resolver maps `lostcoords/ui`, the library's internal module identifiers and Stimulus
to canonical files. Resolution of internal identifiers is scoped to library importers. Module
registration validates the selection before changing the application and does not repeat defaults
when called again after host overrides.

Code-copy controls, newsletter buttons, health cards, native tables, inputs, selects and date controls
use the rendering helpers. Language and health navigation use segmented class builders with native
links. Health filters keep their existing state owner and use the same segmented styles.

The site renders shared card and control classes into each chart root's data attributes. Its chart
code uses those classes when constructing figures and controls. Chart data, plotting, table filtering,
localization and scroll containers remain site concerns. The gem has no chart adapter or table DSL.
`lc_table` supplies native table markup, shaded headers, subtle row dividers and hover feedback; callers supply
captions, headers and content. Each app owns its surface colors.

## Verification

- Standalone bundle excludes Rails, Railties, ActionPack and the Heroicons Ruby gem.
- Component-only CSS compiles without document body, inline-code or typography-reset rules.
- Browser checks compare the site's colors, fonts and inline-code styles with its original CSS.
- Chart ranges, carousel, date changes, marker search, group/status filters and details are checked on
  the real health page at desktop, 390px and 320px widths, including localized navigation.
- Copy success, error, Japanese feedback, reduced motion and Turbo restoration are checked in a
  temporary verification page. Desktop and mobile screenshots verify the actual site and components.
- Explicit registration is checked through fingerprinted Rails importmap assets, including selection,
  unknown identifiers, complete defaults and repeated registration.
- The gem suite, Rails showcase export, site rendering tests, lint and existing site tests remain gates.

## Remaining delivery

Prepare the gem release containing the asset entries and verify the site against the published
package with the local override disabled. Keep local development on the sibling checkout and the
committed lockfile on the released gem. Publish or deploy the site only when authorized.
