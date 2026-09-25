---
name: easy_flow-develop
description: Use PROACTIVELY for adding a step type to easy_flow flows (a step that asks the visitor something, computes a value from earlier answers, or picks the next branch), serving a host's flows from the app's own controller and routes, acting when a visitor finishes a flow, and reading a run's recorded answers and question labels — MUST BE USED instead of hand-rolling questionnaire steps, branching logic, flow controllers or answer lookups.
tools: Read, Write, Edit, Grep
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer and does not pick.

## What easy_flow is

A Rails engine for flows an admin draws on a canvas and a visitor runs one step at a time. Each step is an instance of a step type, and the engine ships the question type (a question with a list of answers) plus its own start, end, condition and switch types. Use this local when the app needs a step type of its own, needs a host's flows on its own pages with its own behaviour when a visitor finishes, or needs to read what a visitor answered. It assumes easy_flow is already installed and a host is declared; if not, hand off to `easy_flow-install` first.

## Interface

- `EasyFlow::Step` — a module a class includes to declare a step type with class-level words, registered with `.register`.
- `EasyFlow.step` — declares and registers a step type in one call from a block of the same words, for a type small enough not to need its own class.
- `EasyFlow::FlowsController` — the visitor controller; the app subclasses it to serve one host's flows from its own routes and to change what happens at the start, on each step and at the finish.
- `hosted_by` — class method on a `FlowsController` subclass naming the host whose flows it serves.
- `routed_by` — class method on a `FlowsController` subclass naming the prefix of the app's own route names that the controller redirects and links to.
- `EasyFlow::Run` — the stored record of one visitor's pass through a flow, pinned to the version that was live when it started.
- `EasyFlow::QuestionRunner` — reads a flow document: its steps, the next step for a set of answers, the answers on the path taken, and a question's text and an answer's label.

## How to use it

### Declare a step type

1. Ask the developer what the step does, and which of these it is:
   - It asks the visitor for input — declare `awaits_input`.
   - It computes a value from earlier answers with no visitor input — define `process`.
   - It only picks which connection to follow — define `route`.
   A type may both `process` and `route`. A type that does none of the three is skipped when a visitor reaches it.
2. Create the class in the app, for example `app/models/flow_steps/rating.rb`. The class name, underscored, is the type's id (`Rating` becomes `:rating`), and that id is stored in every flow that uses it, so it must not change after admins start using the type:

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
4. Use these words to declare the type. Each is called once at class level (or inside the `EasyFlow.step` block):
   - `step_name "<label>"` — the name admins see on the canvas. Defaults to the id.
   - `setting :name, type:, label:, options:, required:, limit:, check:, from:, outputs_of:` — a field the admin fills in on the canvas. `type` is one of `:string`, `:integer`, `:float`, `:boolean`, `:select`, `:multi_select`, `:previous_step`, `:from_step`, `:list`. A `:select` or `:multi_select` must pass `options:`, or boot raises `EasyFlow::UnknownFieldType`. A `:list` must take a block of `setting` calls describing one entry. `:previous_step` lets the admin pick an earlier step. `outputs_of: :<setting>` offers the outputs of the step chosen in that setting, and `from: :<setting>` offers the values of the output chosen in that setting; either one makes the type `:from_step`.
   - `output :name, type:, label:, values:, from:` — a value the step records. `type` is one of `:string`, `:integer`, `:float`, `:boolean`, or boot raises `EasyFlow::UnknownOutputType`. `values:` is an array or a lambda taking the node, listing the values the output can take; the canvas offers these as the connections leaving the step. `from: :<setting>` takes the values from the step chosen in that setting.
   - `names_by :setting` or `names_by { |node| ... }` — what the step is called on the canvas, from a setting or computed.
   - `awaits_input` — the visitor is shown this step and must answer it.
   - `ends_here` / `begins_here` — marks the type as an end or a start of a flow.
   - `displays_by { |node| ... }` — builds the object handed to the step's partial as the local `step`. Without it the partial receives the node itself.
   - `drawn_by "<partial>"` — the partial that draws this type for a visitor. Without it the host's default drawing is used, which expects `step.id`, `step.text` and `step.choices`, so a type with its own display shape needs its own partial.
5. For a type that computes or routes, define instance methods on the class (or `process { |node, state| ... }` / `route { |node, state| ... }` in the block form):

   ```ruby
   def process(node, state)
     state[node.config["step"]].to_i * 2
   end

   def route(node, state)
     state[node.config["step"]] == node.config["answer"]
   end
   ```

   - `node` has `id`, `type` and `config`; `config` is a hash of the admin's settings with string keys.
   - `state` is the answers recorded so far, keyed by step id as strings.
   - `process` returns the value recorded under this step's id. It runs as soon as a visitor reaches the step, before the next step is shown.
   - `route` returns the value that picks the connection to follow; it is compared as a string with the value each leaving connection is labelled with. Returning `nil` follows the first connection.
6. For a type that awaits input, write the partial named in `drawn_by`, for example `app/views/flow_steps/_rating.html.erb`. It receives the display object as `step`. It renders only the input, since the page supplies the form, the Next button and the Back button. The input must be named `answers[<step id>]`, or the answer is not recorded:

   ```erb
   <%= label_tag "answers[#{step.id}]", step.text %>
   <%= number_field_tag "answers[#{step.id}]", nil, in: 1..step.scale %>
   ```

7. Restart the server, open a flow on the canvas and check the type is offered, its settings show, and a preview walks through it.

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
   - `finished(answers, run)` — called when the visitor reaches the end. `answers` is the answers on the path taken, keyed by step id as symbols. `run` is the stored `EasyFlow::Run`, or `nil` when the flow keeps no record. It must render or redirect. Default: the engine's completion page.
   - `start_run(flow)` — creates the run when a visitor starts a flow that saves each step. Call `super` and change the run it returns, for example to set its `owner` or `label`.
   - `runner_for(definition)` — returns the runner used for each step. Return a subclass of `EasyFlow::QuestionRunner` to change what the step and completion pages read from it.
5. Visit `/<path>/<slug>` for a published flow and walk it to the end.

### Read a run and its answers

1. Find runs scoped to one host so one host never sees another's: `EasyFlow::Run.joins(:flow).where(easy_flow_definitions: { host: "intake" })`.
2. Read from a run:
   - `run.recorded` — the answers so far, a hash keyed by step id as symbols.
   - `run.flow` — the flow it belongs to.
   - `run.owner` — the optional record the run belongs to, polymorphic, set by the app. `run.label` and `run.status` are free string columns for the app's own use.
   - `run.pinned_definition` — the flow document of the version the run started on.
   - `run.next_step(answers)` and `run.walked(answers)` — the next step, and the answers on the path taken, for a set of answers against that pinned version.
3. To show answers with their question text and answer labels, build a runner from the run's pinned document:

   ```ruby
   runner = EasyFlow::QuestionRunner.new(run.pinned_definition)
   runner.state_on_path(run.recorded).each do |step_id, value|
     puts "#{runner.question_text(step_id)}: #{runner.choice_label(step_id, value)}"
   end
   ```

   - `state_on_path(answers)` — only the answers on the path the visitor actually took, dropping answers left behind by going back.
   - `question_text(id)` — the text of a question step. It returns `nil` for a step of any other type.
   - `choice_label(id, value)` — the label of the chosen answer, or the value itself when there is no label.
   - `steps`, `step(id)`, `next_step(answers)`, `steps_on_path(answers)`, `slug` and `headline` read the rest of the document.

## Conventions

- A step type's id comes from its class name or the id passed to `EasyFlow.step`, and it is stored in flow documents, so renaming the class or id breaks every flow that uses it.
- Register class-based step types inside `to_prepare`. A type registered anywhere else is lost on code reload in development.
- Always read a run against `run.pinned_definition`, never the flow's live version, since a run keeps the version it started on after a new one is published.
- Always look flows and runs up through a host.
- A step's input field is named `answers[<step id>]`. Any other name is ignored.
- A `FlowsController` subclass needs all four named routes for its prefix; a missing one raises when the visitor is linked or redirected to it.
- The engine installs, mounts and configures hosts, layouts, the default drawing and checks through `easy_flow-install`, not here.
