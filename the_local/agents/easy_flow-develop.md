---
name: easy_flow-develop
description: Use PROACTIVELY for adding a step type to easy_flow flows (a step that asks the visitor something, takes several answers at once, computes a value from earlier answers, picks the next branch, or holds the visitor until something outside the flow has happened), showing a step differently depending on the visitor's stored run, branching on what a visitor ticked on a checklist, moving a paused run on once what it waits for has happened, refusing a blank or invalid answer to a step with a message, offering an admin a step setting whose options are read from the app's own records, letting an admin pick another flow of the same host in a step's settings, letting an admin edit a value stored on one of the app's own records from a step's settings on the canvas, serving a host's flows from the app's own controller and routes, starting a visitor's run on a published version of a flow other than the live one, acting when a visitor finishes a flow, acting on the output a visitor's flow ended with, finding the run of another flow that a Flow step started and the run that started it, sending a visitor back to the run that started a flow once that flow ends, and reading a run's recorded answers and question labels, including every answer ticked on a checklist and every visit's answer when a flow loops back to a question already asked — MUST BE USED instead of hand-rolling questionnaire steps, checkbox lists, branching logic, number comparisons, hard-coded setting options, copying a record's value into a flow and back, answer validation, polling or "come back later" pages, flow controllers or answer lookups.
tools: Read, Write, Edit, Grep
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer and does not pick.

## What easy_flow is

A Rails engine for flows an admin draws on a canvas and a visitor runs one step at a time. Each step is an instance of a step type. The engine ships eight: start (`:start`), end (`:terminal`, whose one setting is the output an admin writes for a flow that ends there), question (`:question`, a question with a list of answers of which the visitor picks one, which the admin can mark required so a blank answer is refused), checklist (`:checklist`, a question with a list of answers of which the visitor ticks any number, which the admin can mark required so a visitor who ticks nothing is refused), three that pick a branch from an earlier answer with no code — condition (`:condition`, is or is not a chosen value), switch (`:switch`, follows the connection labelled with the answer) and compare (`:compare`, reads the answer as a number and checks it by more than, less than, at least or at most against an amount) — and Flow (`:flow_step`, names another flow of the same host and the number of one of its versions, with one connection for each different output that version's End steps write). When a stored run stops at a Flow step, a run of the named flow is started on the named version, and the first run waits on the Flow step. When the second run ends, its output is recorded in the first run at the Flow step, and the first run moves on along the connection labelled with that output. On a question and on a checklist the admin can give each answer info, a longer explanation the visitor opens with an info button beside that answer. An admin may connect a step back to an earlier one, so a flow can ask the same question more than once, and each visit's answer is kept. Before writing a step type to ask for one answer or several, or to branch on an answer or a number, ask the developer whether an admin placing one of the built-in types on the canvas is enough. None of condition, switch or compare reads a checklist's answer, so branching on what a visitor ticked takes a step type of the app's own that defines `route`. Use this local when the app needs a step type of its own, needs a host's flows on its own pages with its own behaviour when a visitor finishes, or needs to read what a visitor answered. It assumes easy_flow is already installed and a host is declared; if not, hand off to `easy_flow-install` first.

## Interface

- `EasyFlow::Step` — a module a class includes to declare a step type with class-level words, registered with `.register`.
- `EasyFlow.step` — declares and registers a step type in one call from a block of the same words, for a type small enough not to need its own class.
- `EasyFlow::FlowsController` — the visitor controller; the app subclasses it to serve one host's flows from its own routes and to change what happens at the start, on each step and at the finish.
- `hosted_by` — class method on a `FlowsController` subclass naming the host whose flows it serves.
- `routed_by` — class method on a `FlowsController` subclass naming the prefix of the app's own route names that the controller redirects and links to.
- `EasyFlow::Run` — the stored record of one visitor's pass through a flow, started with `EasyFlow::Run.start` on the live version or a chosen published one and pinned to that version, moved on past a waiting step with `advance`, read for the output its flow ended with by `output`, and linked to the runs its Flow steps started by `inner_runs` and to the run that started it by `parent_run`.
- `EasyFlow::QuestionRunner` — reads a flow document: its steps, the next step for a set of answers, the answers on the path taken, and a question's text and an answer's label.

## How to use it

### Declare a step type

1. Ask the developer what the step does, and which of these it is:
   - It asks the visitor for input — declare `awaits_input`.
   - It computes a value from earlier answers with no visitor input — define `process`.
   - It only picks which connection to follow — define `route`.
   - It holds the visitor until something outside the flow has happened, such as a payment arriving or a reviewer approving — declare `waits_until`.
   A type may both `process` and `route`. A type that does none of the four is passed through without stopping when a visitor reaches it.
2. Create the class in the app, for example `app/models/flow_steps/rating.rb`. The class name, underscored, is the type's id (`Rating` becomes `:rating`), and that id is stored in every flow that uses it, so it must not change after admins start using the type. It must not be one of the built-in ids `start`, `terminal`, `question`, `checklist`, `condition`, `switch`, `compare` or `flow_step`:

   ```ruby
   module FlowSteps
     class Rating
       include EasyFlow::Step

       step_name "Rating"

       setting :prompt, type: :string, required: true
       setting :scale, type: :select, options: %w[5 10], required: true

       output :score, type: :integer, label: "Score"

       names_by :prompt
       awaits_input
       drawn_by "flow_steps/rating"

       displays_by { |node| RatingPrompt.new(id: node.id, text: node.config["prompt"], scale: node.config["scale"].to_i) }
     end
   end
   ```

   For a small type with no methods of its own, the block form declares and registers in one call instead of a class and step 3:

   ```ruby
   EasyFlow.step(:note) do
     step_name "Note"
     setting :text, type: :string
     awaits_input
   end
   ```

3. Register each class-based type in `config/initializers/easy_flow.rb` inside `to_prepare`, so it is registered again after a code reload:

   ```ruby
   Rails.application.config.to_prepare do
     FlowSteps::Rating.register
   end
   ```

   A step whose type is not registered is neither shown nor run as that type.
4. Ask the developer which hosts' admins should be able to add the type. A registered type is in a host's palette, the step types an admin can add on that host's canvas, only when the host names no list of offered step types or its list includes the type's id. A type that declares `ends_here` is in every host's palette, and a type that declares `begins_here` is in none. When a host that names a list should offer the new type, add the type's id to that host's list through `easy_flow-install`. Leaving a type off a host's list only keeps admins from adding it there, and a step of that type already in one of the host's flows is still drawn and run.
5. Use these words to declare the type. Each is called once at class level (or inside the `EasyFlow.step` block):
   - `step_name "<label>"` — the name admins see on the canvas. Defaults to the id.
   - `setting :name, type:, label:, options:, required:, limit:, check:, from:, outputs_of:, kept_on:, attribute:` — a field the admin fills in on the canvas. `type` is one of `:string`, `:integer`, `:float`, `:boolean`, `:select`, `:multi_select`, `:previous_step`, `:from_step`, `:list`, `:flow`, or boot raises `EasyFlow::UnknownFieldType`. A `:select` or `:multi_select` must pass `options:`, or boot raises the same error. `options:` is either an array of strings, or a lambda taking no arguments that returns one; the lambda is called each time the canvas is opened and each time an admin saves the step's settings, so the options follow the app's data without a restart (`options: -> { Region.order(:name).pluck(:code) }`). A saved setting whose value is no longer among the options is refused the next time the admin saves that step. When the options come from the app's records, ask the developer which records, which column is stored as the value, and whether the list must differ by account or host, since the lambda is passed nothing and the same list is offered everywhere the type is used. A `:list` must take a block of `setting` calls describing one entry. `:previous_step` lets the admin pick an earlier step, and is always required. `outputs_of: :<setting>` offers the outputs of the step chosen in that setting, and `from: :<setting>` offers the values of the output chosen in that setting; either one makes the type `:from_step`. `:flow` lets the admin pick one of the flows the admin's list shows on the same host, offered by title, and is stored in `node.config` as that flow's id as a string. A `:flow` setting is not checked on save against the flows offered, so code that reads it looks the flow up through the host and handles a blank or unknown id. `limit:` is the most values a `:multi_select` takes. `check:` is a lambda given the value that returns an error message, or `nil` when the value is acceptable. `label:` defaults to the name humanized. `kept_on:` and `attribute:` keep the setting's value on one of the app's own records instead of in the flow; see "Keep a setting on one of the app's records".
   - `output :name, type:, label:, values:, from:` — a value the step records. `type` is one of `:string`, `:integer`, `:float`, `:boolean`, or boot raises `EasyFlow::UnknownOutputType`. `values:` is an array or a lambda taking the node, listing the values the output can take; the canvas offers these as the connections leaving the step, so a type that routes must declare them. `from: :<setting>` takes the values from the step chosen in that setting.
   - `names_by :setting` or `names_by { |node| ... }` — what the step is called on the canvas, from a setting or computed.
   - `awaits_input` — the visitor is shown this step and submits an answer to it.
   - `waits_until { |node, state| ... }` — the run stops at this step until the block returns a truthy value. See step 8.
   - `answer_check { |node, value| ... }` — checks a submitted answer before it is recorded. `value` is the submitted string, an array of strings when the input submits several values, or `nil` or `""` when the input sent nothing. An array may hold blank strings. Return a message to refuse the answer, or `nil` to accept it. Without it every answer is accepted, including a blank one.
   - `ends_here` / `begins_here` — marks the type as an end or a start of a flow. A run that ends on a step of an `ends_here` type gives that step's `output` setting as `run.output`, so a type of the app's own that ends a flow declares `setting :output, type: :string` for the admin to fill in, or gives no output.
   - `starts_a_flow` — when a stored run stops at a step of this type, a run of another flow is started. The type must declare `setting :flow, type: :flow` and `setting :version, type: :integer`, since the new run is started on that flow's version with that number. The new run is only started at a step the run stops at, so the type must also declare `waits_until` or `awaits_input`. When the new run ends, its output is recorded under this step's id, so a type that should follow a connection per output defines `route` returning `state[node.id]` and declares an `output` whose `values:` are the outputs the named flow can end with. Before writing such a type, ask the developer whether the built-in Flow step is enough. See "Follow a run into the flow a Flow step started".
     - On the canvas, a step of the type is marked `Runs a flow`.
     - Once the step's `:flow` setting names a flow, clicking the step takes the admin to that flow's page, and a `Settings` button on the step opens the step's own settings. When the type declares more than one `:flow` setting, the click goes to the flow named in the first one that holds a value.
     - While the step's `:flow` setting is blank, clicking the step opens its settings like any other step.
     - While an admin is connecting two steps, clicking the step picks it as the connection's target, the same as any other step.
   - `displays_by { |node| ... }` or `displays_by { |node, run| ... }` — builds the object handed to the step's partial as the local `step`. Without it the partial receives the node itself. A block that takes two arguments is also given the visitor's stored `EasyFlow::Run`, which is `nil` when the flow keeps no stored run at this point and in an admin's preview, so the block must handle `nil`. The block is also called with a `nil` run once for each step already answered every time a step page is shown, to count progress, so it must not be slow and must not change anything.
   - `drawn_by "<partial>"` — the partial that draws this type for a visitor. Without it the host's default drawing is used, which draws one answer to pick and expects `step.id`, `step.text` and `step.choices`, each choice answering `value`, `label`, `hint` and `info`, so a type with its own display shape needs its own partial.
6. For a type that computes or routes, define instance methods on the class (or `process { |node, state| ... }` / `route { |node, state| ... }` in the block form):

   ```ruby
   def process(node, state)
     state[node.config["step"]].to_i * 2
   end

   def route(node, state)
     state[node.config["step"]] == node.config["answer"]
   end
   ```

   - `node` has `id`, `type` and `config`; `config` is a hash of the admin's settings with string keys.
   - `state` is the answers recorded so far, keyed by step id as strings. An answer is a string, or an array of strings for a step that takes several values, such as a checklist.
   - `process` returns the value recorded under this step's id. It runs as soon as a visitor reaches the step, before the next step is shown.
   - A type that declares more than one `output` returns a hash from `process`, keyed by each output's name as a string. A later compare step reads the output the admin picks from that hash.
   - `route` returns the value that picks the connection to follow; it is compared as a string with the value each leaving connection is labelled with, so `false` follows the connection labelled `false`. Returning `nil` follows the first connection. A returned value that matches no connection's label ends the flow at that step. A route that returns `true` or `false` declares `output :result, type: :boolean, values: [true, false]`.
   - To branch on a checklist, read its array and return one value. Ask the developer what decides the branch, such as one given answer being ticked, any of several, or how many were ticked:

     ```ruby
     setting :step, type: :previous_step
     setting :answer, type: :string, required: true

     output :result, type: :boolean, values: [true, false]

     def route(node, state)
       Array(state[node.config["step"]]).include?(node.config["answer"])
     end
     ```
   - In a flow that loops, the first visit to a step is recorded under its id and each later visit under `<id>@<n>`, where `n` counts from 2. `route` is given the latest visit's answer under the plain step id. `process` and `waits_until` are given the answers as recorded, so the plain id holds the first visit's answer and later visits are under `<id>@2`, `<id>@3` and on. A `process` step reached again records its result under its own `<id>@<n>`. When a computing or waiting type reads an earlier step that can be asked again, ask the developer whether it should read the first visit or the latest.
7. For a type that awaits input, write the partial named in `drawn_by`, for example `app/views/flow_steps/_rating.html.erb`. It receives the display object as `step`. It renders only the input, since the page supplies the form, the Next button and the Back button. The input must be named `answers[<step id>]`, or the answer is not recorded:

   ```erb
   <%= label_tag "answers[#{step.id}]", step.text %>
   <%= number_field_tag "answers[#{step.id}]", nil, in: 1..step.scale %>
   ```

   Name the input from `step.id`, never from a stored or hard-coded id. On a later visit to the step in a loop, the node's id is `<id>@<n>`, and the answer is only recorded against that visit when the input is named with it. A `displays_by` block must pass `node.id` through as the display object's `id` for the same reason.

   Ask the developer whether the step takes one answer or several. An input named `answers[<step id>]` submits one value, recorded as the string the visitor submitted. Inputs named `answers[<step id>][]`, such as checkboxes, submit several, recorded as an array of strings with blank entries removed. For several, put a hidden blank field of the same name before the inputs, so that a visitor who ticks nothing records an empty array and not `""`:

   ```erb
   <%= hidden_field_tag "answers[#{step.id}][]", "", id: nil %>
   <% step.choices.each do |choice| %>
     <%= check_box_tag "answers[#{step.id}][]", choice.value, false, id: nil %>
   <% end %>
   ```

   An input that submits a hash, such as one named `answers[<step id>][key]`, is dropped and treated as blank.

   A compare step reads a typed answer such as `"12"` as the number it spells, and an answer that is missing, is an array or is not a number makes it follow its `false` connection.

   A blank single answer is recorded as `""` and the visitor moves on, unless the type's `answer_check` refuses it. For a type that takes several answers, refuse nothing ticked with `Array(value).compact_blank.empty?`, since `value.blank?` is false for an array holding only the hidden blank field. When the check returns a message, nothing is recorded and the same step is shown again with that message. This holds whether the flow keeps a stored run or carries its answers in the page, and the page supplies what it needs for both, so the partial adds nothing for it. Ask the developer whether the visitor may leave this step blank, and whether that is fixed for the type or chosen per step by the admin. For a per-step choice, declare a `:boolean` setting and read it in the check:

   ```ruby
   setting :required, type: :boolean
   answer_check { |node, value| "Fill this in to go on." if node.config["required"] && value.blank? }
   ```
8. For a type that waits, declare `waits_until` with a block that says whether what the step waits for has happened:

   ```ruby
   module FlowSteps
     class AwaitPayment
       include EasyFlow::Step

       step_name "Payment"

       setting :invoice_step, type: :previous_step

       waits_until { |node, state| Invoice.paid?(state[node.config["invoice_step"]]) }
     end
   end
   ```

   - The block is given `node` and `state` only, the same as `process`, and is not given the run or its owner. Ask the developer what the step waits for, and how the block finds it from the step's settings and the answers recorded before it. If it cannot be found from those, stop and ask, since the block has nothing else to read.
   - The block is called each time the visitor loads the step page, and each time the app calls `run.advance`. Keep it to a single lookup.
   - While the block returns a falsy value, the visitor is shown `Waiting for <name>.` and no form, no Next button and no Back button. `<name>` is what `names_by` gives, or the `step_name` when there is none, so give the type a name a visitor can read.
   - Once the block returns a truthy value, `true` is recorded under the step's id, or the value `process` returns when the type also defines `process`, and the run goes on to the next step.
   - Do not declare `awaits_input` on a type that waits. The waiting message replaces the form, so the input is never shown.
   - The page does not reload itself. Ask the developer how the run should move on when what it waits for happens:
     - The visitor reloads the page. This needs nothing more, and works whether or not the flow keeps a stored run.
     - The app calls `run.advance` where the event is handled, such as a webhook or a job. See "Read a run and its answers". This needs a stored run, so it only applies to a flow the admin set to save each step.
9. Restart the server, open a flow on the canvas of each host that should offer the type, and check the type is in the palette, its settings show, and a preview walks through it. On a host that names a list of offered step types without the type's id, check the type is not in the palette. For a type that declares `starts_a_flow`, check the step is marked `Runs a flow`, that once a flow is picked in its settings clicking the step goes to that flow's page, and that its `Settings` button opens its settings.

### Keep a setting on one of the app's records

Use this when an admin should edit a value that belongs to one of the app's own records, such as a customer's name, from a step's settings on the canvas, and the flow should not hold a copy of it.

1. Ask the developer which record holds the value, which of its attributes, and which of the step's other settings identifies the record. Do not pick these.
2. Ask the developer which admins may change which records. The finder below is given only the step's settings, not the admin, the host or the owner, so an admin who can type an id into a setting can reach any record the finder will find. If records must be limited to one account or host, stop and ask how the finder can tell, since it has nothing else to read.
3. Declare the setting with `kept_on:`, a lambda given the step's settings as a hash with string keys that returns the record or `nil`, and `attribute:`, the record's attribute that holds the value. `attribute:` defaults to the setting's name:

   ```ruby
   setting :customer, type: :string
   setting :customer_name, type: :string, kept_on: ->(config) { Customer.find_by(id: config["customer"]) }, attribute: :name
   ```

4. What then holds:
   - The canvas shows the value read from the record each time it draws the step, or a blank when the finder returns `nil`.
   - When the admin saves the step's settings, the value is written to the record with `update` at that moment, before the flow is published, and on every save of that step whether or not the value changed. The setting's `type`, `required:` and `check:` are applied first.
   - When the finder returns `nil`, nothing is written and the save goes on.
   - When the record refuses the value, the save is refused with the setting's label followed by the record's own error, such as `Customer name is too long (maximum is 40 characters)`. None of the step's kept settings are written and none of its other settings are saved. This holds when the app already has a transaction open.
   - The value is never stored in the flow's document or its versions, so publishing, undo and a run's pinned version never hold or change it.
   - `node.config` in `process`, `route`, `waits_until`, `answer_check`, `names_by` and `displays_by` does not hold a kept setting. A step that needs the value reads it from the record.
5. Restart the server, open a flow on the canvas, add a step of the type, save a value, and check the record holds it and that a value the record refuses shows its error.

### Serve a host's flows from the app's own controller

1. Ask the developer which host this controller serves, what path the visitor pages live under, and what should happen when a visitor finishes. Do not choose the finish behaviour for them.
2. Add the routes in `config/routes.rb`. The names must be the prefix followed by `_flow`, `_flow_step`, `_flow_runs` and `_run`, because the controller builds every link and redirect from those four:

   ```ruby
   get   "intake/:slug",      to: "intake_flows#show",  as: :intake_flow
   get   "intake/:slug/step", to: "intake_flows#step",  as: :intake_flow_step
   post  "intake/:slug/runs", to: "intake_flows#start", as: :intake_flow_runs
   get   "intake/runs/:id",   to: "intake_flows#step",  as: :intake_run
   patch "intake/runs/:id",   to: "intake_flows#update"
   ```

3. Create the controller, naming the host with `hosted_by` and the route prefix with `routed_by`:

   ```ruby
   class IntakeFlowsController < EasyFlow::FlowsController
     hosted_by :intake
     routed_by :intake

     private

     def finished(answers, run)
       redirect_to main_app.intake_summary_path(run)
     end
   end
   ```

   The controller inherits from the base controller set at install, uses the host's layout, visitor authorization and refusal methods, and only finds flows that belong to the named host. Pages it does not override use the engine's own views.
4. Override only the private methods the developer's answers call for:
   - `finished(answers, run)` — called when the visitor reaches the end. `answers` is the answers on the path taken, keyed by step id as symbols, each a string or, for a checklist, an array of strings. `run` is the stored `EasyFlow::Run`, or `nil` when the admin set the flow to save nothing. A flow the admin set to save on finish gets its run created at this point. To act on which way the flow ended, read `run.output`; when `run` is `nil` there is no output to read. It must render or redirect. Default: the engine's completion page, which lists each answer on the path taken by its label, a checklist's answer as the labels of everything ticked joined into one sentence.
   - `start_run(flow)` — creates the run when a visitor starts a flow the admin set to save each step. Call `super` and change the run it returns, for example to set its `owner` or `label`. To start the run on a version other than the live one, return `EasyFlow::Run.start(flow, version: ...)` instead of calling `super`; see "Start a run on a chosen version".
   - `runner_for(definition)` — returns the runner used for each step. Return a subclass of `EasyFlow::QuestionRunner` to change what the step and completion pages read from it.
5. Visit `/<path>/<slug>` for a published flow and walk it to the end.

### Start a run on a chosen version

Use this when a visitor's run should follow a published version of a flow other than the live one, such as the version an earlier run of the same owner was on.

1. Ask the developer which version the run should start on and how the app knows it, such as a version number stored on the owner or read from the request. Do not pick it.
2. Find the version among the flow's own versions, for example `flow.definition_versions.find_by(number: number)`. A version answers `number`, and `live?` or `superseded?` when it is published.
3. Start the run with `EasyFlow::Run.start(flow, version: version)`. Without `version:` the run starts on the flow's live version. Either way the run is pinned to that version, and publishing another version later does not change it.
4. The version must be one the flow has published and not taken out of service, which is the live version or one it replaced. A version that is a draft, is retired or withdrawn, belongs to another flow, or is `nil` makes `start` raise `ActiveRecord::RecordInvalid` and no run is created. Ask the developer what the visitor is shown when that happens, such as starting on the live version instead or refusing.
5. To do this when a visitor starts a flow from the app's own controller, override `start_run(flow)` and return the run:

   ```ruby
   def start_run(flow)
     version = flow.definition_versions.find_by(number: current_customer.intake_version)
     EasyFlow::Run.start(flow, version: version || flow.live_version).tap { |run| run.update!(owner: current_customer) }
   end
   ```

   This only applies to a flow the admin set to save each step. A flow set to save on finish, or to save nothing, always runs on the live version.
6. Start a run on an older published version, walk it, and check the steps shown are that version's. Start one on a draft and check it is refused.

### Follow a run into the flow a Flow step started

Use this when a visitor's run reaches a Flow step and the app must take the visitor into the flow it names, or read the run it started.

1. This needs the engine's migrations installed, which `easy_flow-install` does.
2. What holds when a stored run stops at a Flow step, whether on the visitor's page load or on `run.advance`:
   - A run of the flow named in the step's settings is started on the version with the number in its settings. The flow is found by its id alone and not through the host, since a `:flow` setting is not checked on save.
   - The new run's `parent_run` is the run that reached the step, and its `parent_step` is the step's id as a string, or the visit key such as `"sub@2"` on a later visit in a loop.
   - The new run is moved on at once past every step that acts without the visitor, the same as `run.advance`. When it stops at a Flow step of its own, that starts a further run the same way.
   - It is started once per visit to the step, so loading the page again or calling `advance` again starts no second one.
   - Its `owner`, `label` and `status` are not copied from the parent run and are left blank.
   - The parent run shows the visitor `Waiting for Flow.` with no form, no Next button and no Back button, and stays on the Flow step until the new run ends.
   - A flow set to save on finish or to save nothing, and an admin's preview, keep no stored run, so they start no run at a Flow step.
   - A Flow step whose flow is blank or deleted raises `ActiveRecord::RecordNotFound`, and one whose version number is blank, unknown or not a published version in service raises `ActiveRecord::RecordInvalid`, at the moment the run stops there.
3. What holds when the new run ends, whether on its visitor's page load or on `inner.advance`:
   - The new run's `output` is recorded in the parent run under its `parent_step`, so `run.recorded[:<step id>]` holds the text the admin wrote on the End step the new run ended on. It is `nil` when that End step's output was left blank, or when the new run ended without reaching an End step.
   - It is recorded once. Loading the new run's page again or calling `advance` on it again changes nothing on the parent run.
   - A job is queued with the app's Active Job adapter, on the `default` queue, that calls `advance` on the parent run. The parent run also moves on the next time its own page is loaded, whichever comes first, so a parent run whose job never runs still moves on when its visitor reloads.
   - The parent run follows the connection leaving the Flow step labelled with that output. A `nil` output follows the first connection, and an output that matches no connection's label ends the parent run at the Flow step.
   - When the parent run then ends and was itself started by a Flow step, its own output is handed to its parent the same way.
   - The new run's own `finished` is still called on its visitor's page load. The job does not call `finished` for the parent run, and if the parent run reaches its end, `finished` is called the next time its visitor loads its page.
   - A visitor who presses Back on the step after a Flow step removes the recorded output, and the parent run waits on the Flow step again. No second run is started, and the parent run moves on again only when the new run's page is loaded or `advance` is called on it.
4. Find the run a parent run started at a step with `run.inner_runs.find_by(parent_step: step_id)`, and the run that started a run with `run.parent_run`.
5. Nothing takes the visitor from the parent run to the new run. Ask the developer how the visitor gets there, such as a link on the app's own page or a redirect from the app's controller, and where to show the new run, which is the `_run` route of the controller serving its host, such as `main_app.intake_run_path(inner)`. Do not pick.
6. Nothing takes the visitor back to the parent run when the new run ends either. Ask the developer whether the visitor goes back, and if so override `finished(answers, run)` in the controller serving the new run's host to redirect when `run&.parent_run` is present, to the `_run` route of the controller serving the parent run's host:

   ```ruby
   def finished(answers, run)
     return redirect_to main_app.intake_run_path(run.parent_run) if run&.parent_run

     super
   end
   ```

7. Ask the developer whether the new run should belong to the parent run's owner. If so, set it where the app sends the visitor on, for example `inner.update!(owner: run.owner)`.
8. Ask the developer what the visitor is shown when the parent run cannot start its new run, since the error is raised on the visitor's page load.
9. Ask the developer what each output of the named flow should lead to in the parent flow. Each different output on the named version's End steps is a connection leaving the Flow step on the canvas, which an admin connects, so no code is needed unless the app acts on the output itself.
10. Publish a flow with a Flow step set to save each step, start a run, walk it to the Flow step, and check one run of the named flow exists with that run as its `parent_run`, and that reloading the page starts no second one. Walk the new run to an End step, and check the parent run records that End step's output at the Flow step and moves on along the connection labelled with it.

### Read a run and its answers

1. Find runs scoped to one host so one host never sees another's: `EasyFlow::Run.joins(:flow).where(easy_flow_definitions: { host: "intake" })`.
2. Read from a run:
   - `run.recorded` — the answers so far, a hash keyed by step id as symbols. A value is a string, or an array of strings for a checklist or any step that takes several answers, empty when nothing was ticked.
   - `run.flow` — the flow it belongs to.
   - `run.owner` — the optional record the run belongs to, polymorphic, set by the app. `run.label` and `run.status` are free string columns for the app's own use.
   - `run.parent_run` and `run.parent_step` — the run whose Flow step started this one and that step's id, both `nil` for a run a visitor or the app started. Once this run ends, `run.parent_run.recorded` holds this run's `output` under that step id.
   - `run.inner_runs` — the runs this run's Flow steps started.
   - `run.pinned_definition` — the flow document of the version the run started on.
   - `run.next_step(answers)` and `run.walked(answers)` — the next step, and the answers on the path taken, for a set of answers against that pinned version.
   - `run.output` — the text the admin wrote into the output setting of the End step the run ended on, read from the run's pinned version. It is `nil` when the run has not reached an End step, or ended on one whose output was left blank. A flow may have several End steps with a different output on each, so the output says which way the flow ended. Ask the developer what the app does with each output, and what it does when there is none.
   - `run.advance` — moves the run past every waiting step whose `waits_until` block now returns a truthy value, and past every step that computes a value, and records each result on the run. It stops at the next step that asks the visitor for input, the next waiting step that is not ready, or the end. It does not call `finished`; that is called the next time the visitor loads the run's page. When it stops at a Flow step it starts that step's run, and when it reaches the end of a run a Flow step started it hands the output to the parent run; see "Follow a run into the flow a Flow step started".
3. To show answers with their question text and answer labels, build a runner from the run's pinned document:

   ```ruby
   runner = EasyFlow::QuestionRunner.new(run.pinned_definition)
   runner.state_on_path(run.recorded).each do |step_id, value|
     puts "#{runner.question_text(step_id)}: #{runner.choice_label(step_id, value)}"
   end
   ```

   - `state_on_path(answers)` — only the answers on the path the visitor actually took, in the order they were given, dropping answers left behind by going back. In a flow that loops, it holds every visit: the first under the step id and each later one under `:"<id>@<n>"`, such as `:"job@2"`. Ask the developer whether each visit is shown as its own line or the visits to one question are grouped together; to group them, take the part of the key before `@`.
   - `question_text(id)` — the text of a question or checklist step, given either its id or a visit key such as `"job@2"`. For a step of any other type it returns that step's `question` setting, or `nil` when it has none.
   - `choice_label(id, value)` — the label of one chosen answer on a question or checklist, or the value itself when there is no label. It takes a visit key the same way as `question_text`. Handed a checklist's array, it returns one string, the label of each ticked value joined into a sentence such as `Email, Phone, and Post`, and an empty string when nothing was ticked. Ask the developer whether a checklist's answers are shown as that one sentence or each on its own; for each on its own, call it once per ticked value with `value.map { |ticked| runner.choice_label(step_id, ticked) }`.
   - `step(id)` finds the step for either its id or a visit key.
   - `next_step(answers, run: nil)` — the next step to show, built by its type's `displays_by`. Pass `run:` when a type's display block takes the run.
   - `steps_on_path(answers)` — the steps on the path taken, each built by its type's `displays_by` with a `nil` run.
   - `steps`, `slug` and `headline` read the rest of the document.

## Conventions

- A step type's id comes from its class name or the id passed to `EasyFlow.step`, and it is stored in flow documents, so renaming the class or id breaks every flow that uses it.
- Never give a step type one of the built-in ids: `start`, `terminal`, `question`, `checklist`, `condition`, `switch`, `compare`, `flow_step`.
- Register class-based step types inside `to_prepare`. A type registered anywhere else is lost on code reload in development.
- Registering a type does not put it in the palette of a host that names a list of offered step types without the type's id. Which step types a host offers is set through `easy_flow-install`, not here.
- A type that declares `ends_here` is in every host's palette, and a type that declares `begins_here` is in no host's palette.
- An `options:` lambda is passed nothing, and one list is offered on every host's canvas, so it cannot narrow the options by admin, account or host.
- A setting declared with `kept_on:` lives only on the app's record, written when the admin saves the step, so a step's code never finds it in `node.config`.
- A `kept_on:` lambda is given only the step's settings, so it cannot limit which records an admin reaches by admin, account or host.
- A `:flow` setting holds a flow's id as a string and is not checked against the flows offered, so code reading it looks the flow up through the host.
- On the canvas, clicking a step of a `starts_a_flow` type whose `:flow` setting names a flow goes to that flow's page, and the step's settings open from its `Settings` button.
- A type that routes declares the values its output takes, or the canvas offers no connections to label.
- A run starts only on a version its own flow has published and not retired or withdrawn, and any other version raises `ActiveRecord::RecordInvalid`.
- Always read a run against `run.pinned_definition`, never the flow's live version, since a run keeps the version it started on after a new one is published.
- Always look flows and runs up through a host.
- In a flow that loops, a later visit's answer is keyed `<id>@<n>`, so code that reads answers never assumes one answer per step id. A step id may not contain `@`, and a flow with one is refused when published.
- A loop that comes back to a step with no answer given since the last visit to it ends the flow there, so every loop needs a step that awaits input.
- A step's input field is named `answers[<step.id>]` for one value or `answers[<step.id>][]` for several. Any other name is ignored, and a hash is treated as blank.
- An answer is a string or an array of strings, so code that reads answers never assumes a string. A checklist's answer is always an array.
- Condition, switch and compare do not branch on an array answer. Branching on one takes an app step type that defines `route`.
- A `displays_by` block that takes the run handles a `nil` run.
- An answer the type's `answer_check` refuses is never recorded, and the visitor is shown the same step with the check's message. An answer no check refuses is recorded, a blank single one as `""`.
- A `waits_until` block is given only the step and the answers recorded so far, so what it waits for must be findable from those.
- A type that waits never also declares `awaits_input`.
- `run.advance` only moves a stored run, and never finishes it; the visitor's next page load does.
- A flow's output is free text an admin writes on each End step, so code that acts on it handles `nil` and any value it does not expect.
- A flow's output is read from a stored run only, so a flow the admin set to save nothing gives none.
- A run started by a Flow step has no owner until the app sets one, and nothing sends the visitor to it or back from it.
- A run that reaches a Flow step waits there until the run it started ends, then records that run's output, which may be `nil`, and follows the connection labelled with it.
- A parent run is moved on by an Active Job job, so the app's queue adapter must run jobs for it to move on without its visitor reloading.
- Only a stored run starts a run at a Flow step.
- A `FlowsController` subclass needs all four named routes for its prefix; a missing one raises when the visitor is linked or redirected to it.
- The engine installs, mounts and configures hosts, the step types each host offers, layouts, the default drawing and checks through `easy_flow-install`, not here.
