---
name: keystone_ui-install
description: Use to hook Keystone UI into a project — adding the gem, running the install generator to wire Tailwind, the Stimulus controllers and the layout's theme attributes, and configuring the palette, the theme mode supplier, registered looks, the breadcrumb trail supplier and extra Tailwind imports and sources.
tools: Bash, Read, Edit
scope: UI — pages, forms, tables, navigation, dashboards
---

This local carries the steps for wiring Keystone UI into a host app. Follow them
in order, exactly as written, and invent none.

## What Keystone UI is

A Rails engine gem that supplies an app's visual layer as `ui_*` view helpers
built on ViewComponent; hook it in before building any screen with those helpers.

## Interface

- `bin/rails generate keystone:install` — sets up the host's Tailwind entry
  point, registers the gem's Stimulus controllers, and adds the theme attributes
  to the layout's `<html>` tag. Safe to re-run.
- `KeystoneUi.configure` — a block yielding the configuration: `accent` and
  `surface` (palette names, `:blue` and `:zinc` unless set),
  `theme_mode_supplier` (a callable that supplies a light, dark, system or
  custom mode),
  `register_look` (a look's CSS file by name), `default_look` and
  `look_supplier` (which registered look a page gets),
  `trail_supplier` (a callable that supplies the breadcrumb trail for form and
  show pages that pass none, and their Back link when they pass none either),
  and the `tailwind_imports` and `tailwind_sources` lists (extra CSS files and
  scan paths added to the Tailwind build).
- `keystone_theme_attributes` — a layout helper placed inside the `<html>` tag.
  It writes `data-theme="light"`, `data-theme="dark"` or `data-theme="custom"`
  for the page's mode, and writes nothing for system so the page follows the
  operating system. The mode is the `keystone_theme` cookie's choice, then the
  configured `theme_mode_supplier`, then light. It also writes
  `data-look="<name>"` for the page's look: the `look_supplier`'s name, then
  `default_look`, each used only when registered. With no look registered it
  writes no `data-look`.

## How to use it

1. Confirm the prerequisites: Ruby >= 3.2 and **tailwindcss-rails v4+** in the
   host app. The gem brings ViewComponent and keystone_ui-styles 0.6.0 or later with it.
   Tailwind does not have to be initialized first, because the generator creates
   the stylesheet if it is missing.

2. Add the gem to the Gemfile and install it:

   ```ruby
   gem "keystone_ui"
   ```

   ```bash
   bundle install
   ```

   If the project sources its own gems from somewhere other than RubyGems (a git
   or path reference), ask the developer which to use rather than choosing.

3. Run the generator:

   ```bash
   bin/rails generate keystone:install
   ```

   It touches three host files:

   - `app/assets/tailwind/application.css` — if absent, it is created holding
     `@import "tailwindcss";` and `@import "./keystone_source.css";`. If present,
     the Keystone import is added on the line after `@import "tailwindcss";`, and
     Keystone lines left by older installs are removed.
   - `app/javascript/controllers/index.js` — appends
     `import { registerControllers } from "keystone_ui/index"` and
     `registerControllers(application)`.
   - `app/views/layouts/application.html.erb` — adds
     `<%= keystone_theme_attributes %>` directly after the first `<html` in the
     file, so the tag reads `<html <%= keystone_theme_attributes %> ...>`. A
     layout that already contains the call is left unchanged.

   Read its output for two warnings:

   - `app/javascript/controllers/index.js not found` — ask the developer where
     the Stimulus application is set up and add those two lines there. Without
     them, dropdowns, modals, file uploads, the column picker, the theme toggle
     and the other interactive components do nothing.
     `registerControllers(application)` also copies `data-theme` and `data-look`
     from each page Turbo renders onto the `<html>` tag. Without it, a Turbo
     visit keeps the theme and look of the first page loaded.
   - `app/views/layouts/application.html.erb not found` — ask the developer which
     layout the app renders and add `<%= keystone_theme_attributes %>` to its
     `<html>` tag. Without it, a saved light or dark choice is not applied when
     the page loads.

   The CSS step only adds the Keystone import if `application.css` contains the
   exact line `@import "tailwindcss";` followed by a line break. If the output
   says nothing about the import and the line is not in the file, add
   `@import "./keystone_source.css";` directly under the Tailwind import by hand.

4. Restart the app (or rebuild assets). On boot the engine writes
   `app/assets/tailwind/keystone_source.css`, which imports the gem's theme and
   component CSS and points Tailwind at the component files. It is written only
   when `application.css` exists **and** contains
   `@import "./keystone_source.css";`, so if the file never appears, that import
   is missing.

5. Keep the generated file out of git. It holds absolute paths to the gem on the
   machine that booted the app, and is rewritten on every boot, which includes
   the dev server, CI and `assets:precompile`. Add to `.gitignore`:

   ```
   app/assets/tailwind/keystone_source.css
   ```

   Only the `@import` line in `application.css` belongs in the repo.

6. Settle the palette. Without configuration the accent scale is blue and the
   surface scale is zinc. To change them statically, add an `@theme` block to
   `application.css` **after** the two imports and override only the shades the
   app uses:

   ```css
   @import "tailwindcss";
   @import "./keystone_source.css";

   @theme {
     --color-accent-500: #6366f1;
     --color-accent-600: #4f46e5;
   }
   ```

   Both scales run 50 through 950. Every component picks the values up with no
   component changes.

   This is a decision to put to the developer: fixed app-wide colors set in CSS,
   or per-user colors generated at runtime by a companion theming gem. Ask which
   the app wants before wiring either.

   To change how components look beyond the palette, write a look file: one CSS
   file holding a `:root` rule, outside any `@layer` block, that sets the
   `--ks-` variables from keystone_ui-styles for corner radius, font, label
   weight, border width, padding and colours. Set each colour's `-dark`
   partner too, or dark pages keep the default colour. Import it after
   Keystone:

   ```css
   @import "tailwindcss";
   @import "./keystone_source.css";
   @import "./look.css";
   ```

   Buttons, panels, cards, alerts, badges, form fields, the modal, the mobile
   action menu, the action menu, the column picker, multi select, copy button, theme toggle,
   checkbox row, radio card, option card, file upload and colour picker read
   these variables. So do the data display components: stat card, chart card,
   card link, CTA banner, feature grid, hero, data table, code, accordion,
   disclosure, calculation, tab switcher, progress, funnel, bucket, pipeline and
   swipe deck.
   So do the navigation components: navbar, nav item, nav dropdown, bottom nav,
   mobile header and settings link. The desktop "Back" link and the breadcrumbs
   on form and show pages use the mobile header's back link variables. The
   keystone_ui-styles README lists every variable and its default.

   To offer several looks and choose one per page, register them by name in
   step 7 rather than importing them here.

7. Write `config/initializers/keystone_ui.rb` only if one of the settings below
   is wanted. Ask the developer about each rather than adding any by default.
   The engine reads the configuration after initializers have run, so this file
   is where the block goes.

   ```ruby
   require "keystone_ui"

   KeystoneUi.configure do |config|
     config.accent = :emerald
     config.surface = :slate
     config.theme_mode_supplier = ->(view) { view.current_user&.theme }
     config.register_look :compact, "/absolute/path/to/compact.css"
     config.default_look = :compact
     config.look_supplier = ->(view) { view.current_user&.look }
     config.trail_supplier = ->(view) { view.breadcrumb_trail }
     config.tailwind_imports << "/absolute/path/to/extra.css"
     config.tailwind_sources << "/absolute/path/to/components/**/*.{erb,rb}"
   end
   ```

   - `accent` and `surface` — set these only when a companion gem or engine
     reads the palette choice. Keystone UI stores the names and changes no color
     from them, because colors come from the CSS custom properties in step 6.
   - `theme_mode_supplier` — a callable that receives the view and returns
     `"light"`, `"dark"`, `"system"`, `"custom"` or `nil`. It supplies the mode
     when the user has not picked one with the theme toggle, since the
     `keystone_theme` cookie that the toggle writes takes precedence. Any other
     return value, or no supplier, falls back to light.
   - A supplied `"custom"` marks the layout's `<html>` tag
     `data-theme="custom"`. The theme toggle does not offer custom, so only a
     supplier sets it. Ask the developer which gem or code supplies custom and
     its colors before returning it.
   - `register_look :name, path` — registers a look file by name and appends it
     to `tailwind_imports`, so `keystone_source.css` imports it. A look offered
     this way scopes its variables to `:root[data-look="<name>"]` instead of
     `:root`, so several can be imported at once.
   - `default_look = :name` — the look a page gets when nothing else chooses one.
   - The app refuses to boot when `default_look` names a look that is not
     registered, when a registered look's file does not exist, or when the file
     sets no `--ks-` variable inside a `:root[data-look="<name>"]` rule. Use an
     absolute path for each look file.
   - `look_supplier` — a callable that receives the view and returns a look
     name for the request. A name that is not registered, or `nil`, leaves the
     page on the default look.
   - `trail_supplier` — a callable that receives the view and returns the
     breadcrumb trail as an array of `[label, href]` pairs, or `nil`. A form or
     show page that passes no trail of its own shows the supplied one on `lg:`
     screens, ending with the page's title, in place of the desktop "Back" link.
     A page that passes no Back link goes back to the trail's last link. A page
     that passes its own trail or Back link keeps it. With no supplier, or a
     `nil` return, the page shows its Back link. Return `nil`, not an empty
     array, for a page with no trail. An empty array replaces the page's Back
     link with breadcrumbs holding only its title, and on a page that passes
     no Back link it raises `KeystoneUi::MissingBackLink`.
   - Every form and show page must end up with a Back link. A page that passes
     no Back link and no trail, and gets no trail from the supplier, raises
     `KeystoneUi::MissingBackLink` naming the page's title when it renders.
     So does a page whose trail's last link has no address.
   - Every link the supplier returns needs both a label and an address. A trail
     with a blank label or address raises `KeystoneUi::IncompleteTrail` naming
     the page's title.
   - Ask the developer which code in the app knows each page's trail before
     writing the callable. If some form or show pages pass no `back_url:`, ask
     where their Back link should come from before enabling the supplier or
     leaving it out.
   - `tailwind_imports` and `tailwind_sources` — lists to append to, never
     assign. Each import becomes an `@import` line and each source becomes an
     `@source` line in `keystone_source.css` on the next boot. They are for
     another gem or engine whose CSS or templates must be in the same Tailwind
     build, and that gem normally appends its own entries. A gem that ships a
     look appends its look file to `tailwind_imports` from its own initializer,
     and `keystone_source.css` imports it after keystone_ui-styles.

## Conventions

- **Verify the install before building anything on it.** Check four things:
  `application.css` holds both imports, `app/assets/tailwind/keystone_source.css`
  exists after a boot, the Stimulus setup calls `registerControllers(application)`,
  and the layout's `<html>` tag contains `<%= keystone_theme_attributes %>`. Then
  load one page that renders a `ui_*` helper and confirm it is styled and that an
  interactive component (a dropdown, a dismissible alert) responds.
- **Importmap is the supported JS path.** For apps configured with importmap the
  gem pins its own controllers, and the charting library they need, on boot, so
  the host pins nothing. If the app bundles JavaScript instead (esbuild, bun,
  webpack), the appended `keystone_ui/index` import has nothing pinned behind
  it. Tell the developer rather than guessing at a bundler configuration.
- **Re-run the generator after upgrading the gem.** It removes superseded install
  lines and reports that each file is already up to date when there is nothing
  to do.
- **New components need no re-run.** Tailwind rescans the gem on each build, so
  components added by a later version are styled on the next boot.
- On boot the engine deletes `app/assets/builds/tailwind/keystone_ui_engine.css`
  if an older install left it there. Do not recreate it.
- Building UI with the helpers, including which helper to use and what keywords
  it takes, is out of scope here and belongs to `keystone_ui-develop`.
