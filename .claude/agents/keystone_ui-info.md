---
name: keystone_ui-info
description: Use to learn what Keystone UI offers — what the component system covers, its layout, color and theme model, and the vocabulary the install and develop locals assume.
tools: Read
scope: UI — pages, forms, tables, navigation, dashboards
---

This local explains Keystone UI and sends you to the local that does the work.
It changes nothing and gives no steps.

## What Keystone UI is

Keystone UI is a Rails engine gem that supplies a host app's visual layer as a
library of view helpers built on ViewComponent. Screens are built from named
pieces — page shells, sections, panels, grids, form fields, data tables,
navigation bars, breadcrumbs, cards, stat tiles, charts, funnels, goal buckets, pipelines,
banners, the calculation behind a figure — instead of hand-written ERB and
Tailwind. Every class the UI renders lives inside the gem, in frozen constants,
so the look is defined in one place.

Reach for it whenever you build or change a screen in an app that has it
installed. It exists to stop UI drift: two pages built from the same helpers
cannot disagree about spacing, color or dark-mode treatment, and a change to a
component updates every page that uses it. It is mobile-first — components ship
separate mobile and desktop treatments (a bottom tab bar and mobile header on
small screens, a full navigation bar from the `lg:` breakpoint up), because
these apps are often viewed in a native webview. The form and show page shells
follow the same split for going back: the mobile header carries the back link on
small screens, and from `lg:` up the shell shows a "Back" link. Given a trail of
earlier pages instead, the shell shows breadcrumbs in place of that link, ending
with the page's own title. A page that passes no trail gets the one the app or
another gem supplies for the request, if any, and a page that passes no back
link goes back to that trail's last link. A trail or back link the page passes
itself always wins. Supplying a trail is set up through the install local.

Every form and show page must end up with a Back link. A page with no back
link, no trail and no supplied trail raises `KeystoneUi::MissingBackLink` when it
renders, and the message names the page's title. A trail with a link missing
its label or its address raises `KeystoneUi::IncompleteTrail`, also naming the
page. That link or those breadcrumbs, and the form page's title, appear at the
top of the page container, inside its width and padding, so a page using either
shell also uses the page container.

## Interface

This local declares no commands. The two working surfaces belong elsewhere:

- **Getting the gem into a host app** — adding it, wiring Tailwind, Stimulus and
  the theme attributes on the layout, setting the palette → **`keystone_ui-install`**.
- **Building UI with it** — which helper renders what, what keywords it takes,
  how helpers nest → **`keystone_ui-develop`**.

## How to use it

One decision: is Keystone UI already set up in the app?

- No, or the setup is out of date → **`keystone_ui-install`**.
- Yes, and you have a screen to build or edit → **`keystone_ui-develop`**. Do not
  hand-write ERB or Tailwind for UI it covers.

Questions about which piece fits a scenario also go to the develop local, which
holds the catalog.

## Conventions

- **Helpers, not classes.** Every piece of UI is a view helper prefixed `ui_`,
  called from ERB. The one layout helper that is not prefixed `ui_` writes the
  theme onto the page's `html` tag, and it belongs to the install local.
  Components live under the `Keystone::Ui` namespace, but a host app does not
  name a component class directly. The one exception is the table column value
  object, which is passed as an argument and renders nothing.
- **Containers take blocks, leaves take keywords.** Helpers that wrap content
  (page shells, sections, panels, grids, forms, tables) yield a block. Helpers
  that render one thing (a button, a badge, a field, a stat, a bucket) are
  configured entirely by keyword arguments. The navigation bar exposes named
  slots instead of a single block.
- **Action menus.** An action menu is an ellipsis button that opens a dropdown
  of actions, shown at every screen size. The mobile action menu is the one
  hidden from `lg:` up. Each action is a label, an address and an HTTP method.
  A plain visit renders as a link. Any other method renders as a button that
  sends that method, so an action that changes data is never a bare link. An
  action can carry a question that Turbo asks before it runs. A delete asks
  "<label> this? This cannot be undone." unless it is given its own question,
  and other actions ask nothing unless given one. A data table puts each row's actions in one action menu at the end of the row,
  and a section can carry an action menu in its header beside its title.
- **Info panels.** A stat card, a radio card and a checkbox row can each carry
  extra text about themselves. Given that text, the piece shows an info button,
  and the text stays hidden until the button is hovered or tapped. A piece
  given no such text shows no button. On a radio card and a checkbox row the
  button sits on the line with the label.
- **Options are symbols, and each component accepts its own set.** Appearance is
  chosen by name — `variant:`, `size:`, `type:`, `padding:`, `spacing:`,
  `max_width:`, `radius:` — on a size scale (`:sm` … `:xl`) or a short list of
  named choices. A button's `variant:` and a badge's `variant:` accept
  different symbols, and the develop local carries the real values. Most
  components raise on a symbol they do not know, so a wrong guess fails at
  render time.
- **Figures are numbers.** Components that measure or compare values, such as
  progress bars, funnels and buckets, do arithmetic on them. Pass a number, not
  a formatted string such as `"9,000"`. A bucket raises on one.
- **A calculation is text.** The calculation behind a figure is the opposite
  case. It is a list of groups, each with an optional title and its lines, and
  each line is a label, the working and the result. They are passed as
  already-formatted text and shown as written. The component does no
  arithmetic, and it is closed by default under a quiet summary row.
- **Semantic color, not literal color.** The themed hue is `accent-*` and the
  themed neutral family is `surface-*`, both CSS custom properties whose
  defaults (blue and zinc) come from the keystone_ui-styles gem. Retheming an
  app changes those values, not the components. Some components still use
  Tailwind's stock `gray-*` and `zinc-*` neutrals, or fixed status colors such
  as green and amber, directly. Changing the defaults belongs to the install
  local.
- **Looks.** A look is one CSS file that sets the `--ks-` variables from
  keystone_ui-styles 0.6.0 or later: corner radius, font, label weight, border
  width, padding and colours. Each colour variable has a `-dark` partner read
  on a dark page. Buttons, panels, cards, alerts, badges, form fields, the
  modal, the action menu, the mobile action menu, the column picker, multi select, copy button,
  theme toggle, checkbox row, radio card, option card, file upload and colour
  picker read these variables. So do the data display components: stat card,
  chart card, card link, CTA banner, feature grid, hero, data table, code,
  accordion, disclosure, calculation, tab switcher, progress, funnel, bucket,
  pipeline and swipe deck. So do the navigation components: navbar, nav item,
  nav dropdown, bottom nav, mobile header, breadcrumbs and settings link. A host imports its
  look after `keystone_source.css`, and a gem ships one through
  `tailwind_imports`, both set up through the install local.
- **Registered looks.** Looks can also be registered by name, and each page
  gets one: the name another gem supplies for the request, then the configured
  default, each used only when registered. The layout's `<html>` tag carries
  `data-look="<name>"`, and a registered look file scopes its variables to
  `:root[data-look="<name>"]`. A host with no registered looks gets no
  `data-look`. Registering and choosing looks is set up through the install
  local.
- **Light, dark, system and custom themes.** Every component has dark-mode
  styling. The theme is chosen in this order: the user's choice stored in a
  cookie, then a mode another gem supplies, then light. System leaves the page
  to follow the operating system. Custom marks the page for a palette another
  gem defines. The theme toggle does not offer it, so a page reaches it when
  another gem supplies it. On a Turbo visit, the page being shown sets the
  theme, so a change to the mode on the server shows up without a full reload.
  Marking the layout with the theme is set up through the install local, and
  placing the toggle on a screen goes through the develop local.
- **Tailwind classes are static strings.** Class names are never interpolated,
  so Tailwind's scanner can find them. Widths and heights that depend on data,
  such as a progress bar or a bucket's fill, are set with an inline style
  instead. The host needs tailwindcss-rails v4+, and the engine tells Tailwind
  at boot where the component files are.
- **Interactivity is Stimulus.** Dropdowns, modals, dismissible alerts, file
  uploads, the color picker, the multi-select, tab switchers, accordions, the
  swipe deck, column pickers, info panels, line charts, clipboard copy
  and the theme toggle ship with the gem as Stimulus controllers registered once
  at install. A host writes no JavaScript to use them. Components that post
  somewhere, such as the column picker and the pipeline, post to endpoints the
  host app owns.
- Ruby >= 3.2. ViewComponent >= 2.0 and < 5.
