---
name: easy_flow-install
description: Use to hook easy_flow into a project — copying and running its migrations, mounting the engine for each host, setting the controller it inherits from, declaring hosts with their layouts and access methods, choosing the default step drawing, turning on optional checks, and reaching the admin pages.
tools: Bash, Read, Edit
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer and does not pick.

## What easy_flow is

A Rails engine for flows an admin draws on a canvas and a visitor runs one step at a time. Hook it in when a Rails 8.1.3 or later app needs questionnaires, intake forms or decision paths that admins change without a deploy.

## Interface

- `bin/rails easy_flow:install:migrations` — copies the engine's migrations into the host's `db/migrate`, creating the flow, version and run tables.
- `mount EasyFlow::Engine` — the route that serves one host's visitor pages and admin pages under a path, with the host named in `defaults: { easy_flow_host: "<host>" }`.
- `EasyFlow.base_controller=` — the name, as a string, of the host controller every engine controller inherits from. Defaults to `"ActionController::Base"`.
- `EasyFlow.host` — declares a named host with its visitor layout, admin layout, admin authentication method, visitor authorization method and refusal method.
- `EasyFlow.draws_with` — the partial that draws a visitor's step when the step's type names none. Defaults to the engine's own `easy_flow/steps/choosing`.
- `EasyFlow.check` — turns on an optional flow check: `:unrouted_value`, `:unfollowed_path` or `:dead_end`.
- `/manage/flows` — the admin pages, under each mount path, where flows are listed, created, drawn on the canvas, previewed and published.

## How to use it

1. Confirm the app has Keystone UI installed (`keystone_ui` in the Gemfile). easy_flow's controllers use its helpers and it is not pulled in by easy_flow. If it is missing, stop and hand off to the `keystone_ui-install` local before continuing.
2. Add `gem "easy_flow"` to the host's `Gemfile` and run `bundle install`.
3. Run `bin/rails easy_flow:install:migrations`, then `bin/rails db:migrate`. This writes four migrations into `db/migrate` and updates `db/schema.rb`.
4. Ask the developer which hosts the app needs. A host is one part of the app that owns its own set of flows, and one host never sees another's flows. Ask for each host's name and the path it is served under.
5. Ask the developer which controller the engine should inherit from. Choosing `"ApplicationController"` gives the engine the app's own authentication methods and helpers. Create `config/initializers/easy_flow.rb` and set it on the first line:

   ```ruby
   EasyFlow.base_controller = "ApplicationController"
   ```

6. In the same initializer, declare each host. Every setting is optional. Ask the developer for each value and leave out any they do not want:

   ```ruby
   EasyFlow.host(:console) do |host|
     host.layout = "application"
     host.admin_layout = "admin"
     host.admin_authentication_method = :authenticate_admin!
     host.visitor_authorization_method = :easy_flow_visitor_permitted?
     host.refusal_method = :refuse_flow
   end
   ```

   - `layout` — the visitor layout. Defaults to the engine's bare layout, which loads no stylesheet, so a styled app almost always sets it.
   - `admin_layout` — the admin layout. Defaults to `"application"`. It must call `yield :head` inside `<head>`, or the canvas scripts do not load.
   - `admin_authentication_method` — a method on the base controller, called with no arguments before every admin page. With none set, the admin pages are open to anyone.
   - `visitor_authorization_method` — a method on the base controller, called with the flow, returning true when the visitor may run it. With none set, every visitor is refused.
   - `refusal_method` — a method on the base controller, called with the refusal error when a visitor is refused or a flow is unpublished or withdrawn. With none set, the response is `404 Not Found`.

   Each method named here must exist on the base controller. Ask the developer to point at it or write it. Do not invent its logic.
7. Mount the engine in `config/routes.rb`, once per host. The host name in `defaults` must match a name declared in step 6. When there is more than one mount, give each an `as:` name:

   ```ruby
   mount EasyFlow::Engine => "/flows", defaults: { easy_flow_host: "flows" }
   mount EasyFlow::Engine => "/console", as: :console_flows, defaults: { easy_flow_host: "console" }
   ```

   A mount whose host name is not declared serves no flows, and its admin pages return `404 Not Found`.
8. Ask the developer whether visitors' steps should be drawn with the engine's own partial or with one from the app. For the app's own, create a partial, for example `app/views/steps/_step.html.erb`, which receives the step as the local `step`. Then add to the initializer:

   ```ruby
   EasyFlow.draws_with("steps/step")
   ```

9. Leave `EasyFlow.check` out unless the developer asks for it. The engine already turns on `:unrouted_value`, `:unfollowed_path` and `:dead_end` at boot. Any other name raises `EasyFlow::UnknownCheck` when the app boots.
10. Start the server and open `<mount path>/manage/flows` for each host.

## Conventions

- After install, check that `<mount path>/manage/flows` shows the flow list and that a new flow opens on the canvas. If the canvas is blank, check that the admin layout calls `yield :head`.
- After publishing a flow, check that `<mount path>/<slug>` shows it to a visitor who passes the host's visitor authorization method.
- After upgrading easy_flow, run `bin/rails easy_flow:install:migrations` again and then `bin/rails db:migrate`. Only migrations the app does not already have are copied.
- The initializer runs once at boot, so a change to it needs a server restart.
- Declaring step types, serving a host's flows from the app's own controllers and routes, and reading runs and answers are out of scope here. They belong to the `easy_flow-develop` local.
