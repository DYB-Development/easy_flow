---
name: easy_flow-install
description: Use to hook easy_flow into a project — copying and running its migrations, mounting the engine for each host, setting the controller it inherits from, declaring hosts with their layouts, access methods, the record that owns their flows and the step types each offers, choosing the default step drawing, setting the file store that keeps files visitors upload, turning on optional checks, giving the app a job queue that moves a run on once the flow its Flow step, or its own step type that starts a flow, started ends, and reaching the admin pages.
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
- `EasyFlow.host` — declares a named host with its visitor layout, admin layout, admin authentication method, visitor authorization method, refusal method, owner method, and the step types its admins can add on the canvas.
- `EasyFlow.draws_with` — the partial that draws a visitor's step when the step's type names none. Defaults to the engine's own `easy_flow/steps/choosing`.
- `EasyFlow.file_store` — the object that keeps a file a visitor uploads at a File upload step and names it again later. Defaults to none, and with none set an uploaded file is refused with `EasyFlow::NoFileStore`.
- `EasyFlow.check` — turns on an optional flow check: `:unrouted_value`, `:unfollowed_path` or `:dead_end`.
- `/manage/flows` — the admin pages, under each mount path, where flows are listed, created, drawn on the canvas, previewed and published.

## How to use it

1. Confirm the app has Keystone UI installed (`keystone_ui` in the Gemfile). easy_flow's controllers use its helpers and it is not pulled in by easy_flow. If it is missing, stop and hand off to the `keystone_ui-install` local before continuing.
2. Read the `keystone_ui` version in the app's `Gemfile.lock`. easy_flow's visitor pages pass each answer's info text to Keystone UI's radio cards and checkbox rows, and easy_flow is built against `keystone_ui` 0.27.0. If the app's version is older, ask the developer whether to run `bundle update keystone_ui` before continuing.
3. Add `gem "easy_flow"` to the host's `Gemfile` and run `bundle install`.
4. Run `bin/rails easy_flow:install:migrations`, then `bin/rails db:migrate`. This writes six migrations into `db/migrate` and updates `db/schema.rb`.
5. Ask the developer which hosts the app needs. A host is one part of the app that owns its own set of flows, and one host never sees another's flows. Ask for each host's name and the path it is served under.
6. Ask the developer which controller the engine should inherit from. Choosing `"ApplicationController"` gives the engine the app's own authentication methods and helpers. Create `config/initializers/easy_flow.rb` and set it on the first line:

   ```ruby
   EasyFlow.base_controller = "ApplicationController"
   ```

7. In the same initializer, declare each host. Every setting is optional. Ask the developer for each value and leave out any they do not want:

   ```ruby
   EasyFlow.host(:console) do |host|
     host.layout = "application"
     host.admin_layout = "admin"
     host.admin_authentication_method = :authenticate_admin!
     host.visitor_authorization_method = :easy_flow_visitor_permitted?
     host.refusal_method = :refuse_flow
     host.owner_method = :current_account
     host.offers = %i[question checklist file_upload condition switch compare flow_step]
   end
   ```

   - `layout` — the visitor layout. Defaults to the engine's bare layout, which loads no stylesheet, so a styled app almost always sets it.
   - `admin_layout` — the admin layout. Defaults to `"application"`. It must call `yield :head` inside `<head>`, or the canvas scripts do not load. It must also show `flash[:notice]` and `flash[:alert]`, since the flow list does not show them itself and removing a flow reports its result only there.
   - `admin_authentication_method` — a method on the base controller, called with no arguments before every admin page. With none set, the admin pages are open to anyone.
   - `visitor_authorization_method` — a method on the base controller, called with the flow, returning true when the visitor may run it. With none set, every visitor is refused.
   - `refusal_method` — a method on the base controller, called with the refusal error when a visitor is refused or a flow is unpublished or withdrawn. With none set, the response is `404 Not Found`.
   - `owner_method` — a method on the base controller, called with no arguments, returning the record whose flows the current request works with, such as the signed-in account. When set, the admin pages list, create and edit only that record's flows, a visitor runs only that record's flows, and two records may each hold a flow with the same slug. With none set, every flow in the host is shared by everyone who reaches it. Ask the developer whether each host's flows belong to one record or are shared.
   - `offers` — the step types this host's admins can add from the canvas palette, as a list of step type names. With none set, every registered step type is offered. The engine's own names are `question`, `checklist`, `file_upload`, `condition`, `switch`, `compare` and `flow_step`, `file_upload` being the File upload step, which needs the file store from step 10, and `flow_step` being the Flow step, which names one of the same host's flows. A step type the app declares is named by the id it was declared with, or after its class when it is a step class, so `Steps::Notify` is `notify`. The End step is offered whether it is listed or not, and the Start step is never offered. Ask the developer which step types each host should offer.

   Each method named here must exist on the base controller. Ask the developer to point at it or write it. Do not invent its logic.
8. Mount the engine in `config/routes.rb`, once per host. The host name in `defaults` must match a name declared in step 7. When there is more than one mount, give each an `as:` name:

   ```ruby
   mount EasyFlow::Engine => "/flows", defaults: { easy_flow_host: "flows" }
   mount EasyFlow::Engine => "/console", as: :console_flows, defaults: { easy_flow_host: "console" }
   ```

   A mount whose host name is not declared serves no flows, and its admin pages return `404 Not Found`.
9. Ask the developer whether visitors' steps should be drawn with the engine's own partial or with one from the app. The engine's own draws a question as one radio card per answer, each with its hint and an info button when the answer has info text. For the app's own, create a partial, for example `app/views/steps/_step.html.erb`, and add to the initializer:

   ```ruby
   EasyFlow.draws_with("steps/step")
   ```

   - The partial receives the step as the local `step`. `step.text` is the question, and `step.choices` lists its answers, each with a `value`, `label`, `hint` and `info`.
   - It is rendered inside the engine's form, so it draws only the fields.
   - The visitor's answer must be submitted as `answers[<%= step.id %>]`. Always build the field name from `step.id` and never from a fixed id. When a flow loops back and asks a question again, `step.id` names that visit, so each visit's answer is stored apart.
   - It replaces the engine's drawing of every step whose type names no partial, so it draws each answer's hint and info itself or they are not shown.
   - It is not used for a checklist step. A checklist is always drawn by the engine as one checkbox per answer, each with an info button when the answer has info text, and the visitor may tick several.
   - It is not used for a File upload step. A File upload step is always drawn by the engine as one file field.
10. Ask the developer whether any host will offer the File upload step, and if so, where the app keeps uploaded files. The engine keeps no file itself and has no default store. Ask the developer to point at the app's store or write one. Do not pick a storage service for them. Set it in the initializer:

    ```ruby
    EasyFlow.file_store = UploadedFiles.new
    ```

    - The store answers `keep(file)`, called with the uploaded file, which responds to `original_filename`. It keeps the file and returns a string reference to it, and that reference is what the run records as the step's answer.
    - When several files are sent for one step, `keep` is called once for each file, and the run records the list of references it returned, in the order the files were sent.
    - The store answers `name_of(reference)`, called with a reference `keep` returned. It returns the name the visitor's completion page shows for that answer. When it returns nothing, the page shows the reference itself.
    - With no store set, a visitor who submits a file at any step of a stored run gets the app's error page, raised as `EasyFlow::NoFileStore`.
11. Leave `EasyFlow.check` out unless the developer asks for it. The engine already turns on `:unrouted_value`, `:unfollowed_path` and `:dead_end` at boot. Any other name raises `EasyFlow::UnknownCheck` when the app boots.
12. Check that the app loads Active Job (`require "rails/all"` or `require "active_job/railtie"` in `config/application.rb`) and has a queue adapter that runs jobs from the `default` queue. When a run started by a Flow step, or by a step type of the app's own that starts another flow, ends, the engine records its output in the run it was started from and queues a job on `default` that moves that run on. If no adapter runs that queue, the run that holds the step stays at it. If `config.active_job.queue_adapter` is not set for an environment, ask the developer which adapter to use there.
13. Start the server and open `<mount path>/manage/flows` for each host.

## Conventions

- After install, check that `<mount path>/manage/flows` shows the flow list and that a new flow opens on the canvas. If the canvas is blank, check that the admin layout calls `yield :head`.
- After publishing a flow, check that `<mount path>/<slug>` shows it to a visitor who passes the host's visitor authorization method.
- After publishing a flow with a question or a checklist whose answer has info text, check that the visitor's page shows an info button on that answer. If it does not, compare the app's `keystone_ui` version with the one in step 2.
- After install, check that an End step selected on the canvas shows an output setting. An admin fills it in on each End step, and it needs no migration and no setting in the initializer.
- After publishing a flow with a checklist, check that a visitor can tick several answers and go on, and that a checklist marked required refuses to go on with nothing ticked.
- After upgrading easy_flow, run `bin/rails easy_flow:install:migrations` again and then `bin/rails db:migrate`. Only migrations the app does not already have are copied.
- After setting a host's `owner_method`, check that two different owners each see only their own flows on `<mount path>/manage/flows`.
- After install, check that a Flow step placed on the canvas offers the host's flows by title as its flow setting. With a host's `owner_method` set, it offers only that owner's flows. It needs no setting in the initializer.
- After choosing a flow on a Flow step, check that its canvas card reads "Runs a flow", that clicking the card opens the chosen flow's canvas under the same mount path, and that its Settings button opens the step's settings instead.
- After opening a chosen flow's canvas from a Flow step's card, check that its header shows a "Back to" button naming the flow it was opened from, by title or by slug when it has no title, and that the button opens that flow's canvas. A canvas opened from the flow list shows no such button.
- After install, check that a Flow step with no flow chosen, or whose chosen flow has been deleted, shows "missing flow" in red on its canvas card, and that saving a version or publishing is refused until it is fixed. This check is always on and is not turned on with `EasyFlow.check`.
- After install, check that a Flow step whose chosen flow exists but whose version is not set, does not exist, or was never published or has been retired or withdrawn shows "unrunnable version" in red on its canvas card, and that saving a version or publishing is refused until it names a live or superseded version. This check is always on and is not turned on with `EasyFlow.check`.
- After install, check that a Flow step whose chosen flow is the flow it sits in, or whose chosen flow leads back to it through the Flow steps of other flows, shows "circular" in red on its canvas card, and that saving a version or publishing is refused until it is fixed. This check is always on and is not turned on with `EasyFlow.check`.
- When a stored run reaches a Flow step, the engine starts a run of the chosen flow and records the run it was started from. That record needs the migration that adds a parent run to the runs table, so an app upgrading from a version without it runs `bin/rails easy_flow:install:migrations` and `bin/rails db:migrate` before publishing a flow with a Flow step.
- After publishing a flow with a Flow step, check that when a visitor finishes the chosen flow, the run that holds the Flow step moves on along the connection named after the output that flow ended with. If it stays at the Flow step, check the queue adapter from step 12.
- When a chosen flow ends at an End step with no output filled in, the engine records nothing at the Flow step, and the job queued on `default` fails with `EasyFlow::InnerFlowError` naming the Flow step. The run that holds the Flow step stays at it. Check that the queue adapter from step 12 keeps or reports failed jobs, and that every End step of a flow chosen on a Flow step has an output.
- When a run reaches a Flow step whose chosen version was retired or withdrawn after the flow was published, the engine raises `EasyFlow::InnerFlowError` naming the Flow step and starts no run. The engine does not turn this error into a refusal, so the visitor gets the app's error page. Check that the app's error reporting captures it.
- After install, check that removing a flow from `<mount path>/manage/flows` shows "Flow removed." and takes the flow off the list. Removing a flow deletes its versions and its runs, and needs no setting in the initializer.
- After publishing a flow with a Flow step, check that while a run of it is stopped at that Flow step, removing the chosen flow is refused and the flow list shows "This flow cannot be removed while" followed by the waiting flow's title, or its slug when it has no title, and "waits on one of its runs". If no message is shown, check that the admin layout shows `flash[:alert]`.
- A step type of the app's own that starts another flow is treated as a Flow step by every check above: the "missing flow", "unrunnable version" and "circular" flags, the refusal to remove a flow a waiting run depends on, and the job on `default`. It runs the flow and version its own settings name, or the ones its declaration works out from its other settings, and needs no setting in the initializer beyond being listed in a host's `offers` when that host sets `offers`.
- After setting `EasyFlow.file_store`, publish a flow with a File upload step whose "What this keeps of a run" detail is "Every answer as it is given", upload a file as a visitor, and check that the completion page shows the name the store gives it.
- A File upload step takes a file only in a flow that keeps every answer as it is given. In a flow that keeps nothing or keeps the run only once it finishes, the visitor is told "A file can only be uploaded in a flow that saves its runs." and cannot go on with a file chosen.
- A File upload step's "Accepted file types" setting is a comma-separated list of extensions, such as `.pdf, .png`. A file of another kind is refused with a message naming the accepted kinds and is never passed to the file store.
- After setting a host's `offers`, check that the canvas palette on that host's `<mount path>/manage/flows` lists only those step types and End.
- Taking a step type off a host's `offers` removes it from the palette only. Steps of that type already in the host's flows stay in them and keep running.
- The initializer runs once at boot, so a change to it needs a server restart.
- Declaring step types, including settings kept on the app's own records, serving a host's flows from the app's own controllers and routes, and reading runs, answers and the output a flow ended with are out of scope here. They belong to the `easy_flow-develop` local.
