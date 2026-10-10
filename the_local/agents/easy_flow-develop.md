---
name: easy_flow-develop
description: Use PROACTIVELY for adding a step type to easy_flow flows (a step that asks the visitor something, takes several answers at once, computes a value from earlier answers, records several values under names an admin enters in the step's settings, counts how many times an earlier step was answered so a loop can give up after a number of tries, picks the next branch, or holds the visitor until something outside the flow has happened), holding a run until a number of minutes after an earlier answer, the next time of day after it, or a date, branching on the hour, weekday or time an earlier step was completed or on the minutes between two completed steps, reading when each step was completed and when a waiting run will move on, showing a step differently depending on the visitor's stored run, branching on what a visitor ticked on a checklist, moving a paused run on once what it waits for has happened, refusing a blank or invalid answer to a step with a message, offering an admin a step setting whose options are read from the app's own records, letting an admin pick another flow of the same host in a step's settings, adding a step type that starts another flow and works out which flow and version to run from its own settings, adding a step type that starts another flow chosen from the visitor's run, such as its owner or its answers, offering a visitor only the answers to a step that their earlier answers allow, filling in a step that has only one possible answer without asking it, skipping a step that does not apply to a visitor, letting an admin edit a value stored on one of the app's own records from a step's settings on the canvas, serving a host's flows from the app's own controller and routes, starting a visitor's run on a published version of a flow other than the live one, acting when a visitor finishes a flow, acting on the output a visitor's flow ended with, keeping a flow from being published while a step that starts another flow names a flow or version that cannot run or leads back to the flow it sits in, finding the run of another flow that a Flow step started, the run a waiting run is waiting on, and the run that started it, sending a visitor back to the run that started a flow once that flow ends, handling a run whose starting run was removed with its flow, handling a Flow step that cannot start its flow or whose flow ended with no output, taking one file or several from a visitor at a step, showing a step's recorded answer by a label the step type works out, and reading a run's recorded answers and question labels, including every answer ticked on a checklist and every visit's answer when a flow loops back to a question already asked — MUST BE USED instead of hand-rolling questionnaire steps, checkbox lists, file upload steps, branching logic, answer lists filtered by earlier answers, skipped questions, number comparisons, comparisons of two earlier answers, hard-coded setting options, copying a record's value into a flow and back, answer validation, retry counters, timers or scheduled delays, step completion timestamps, polling or "come back later" pages, flow controllers or answer lookups.
tools: Read, Write, Edit, Grep
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local follows the steps below exactly and invents none. Where a step names a decision, it asks the developer and does not pick.

## What easy_flow is

A Rails engine for flows an admin draws on a canvas and a visitor runs one step at a time. Each step is an instance of a step type. The engine ships twelve: start (`:start`), end (`:terminal`, whose one setting is the output an admin writes for a flow that ends there), question (`:question`, a question with a list of answers of which the visitor picks one, which the admin can mark required so a blank answer is refused), checklist (`:checklist`, a question with a list of answers of which the visitor ticks any number, which the admin can mark required so a visitor who ticks nothing is refused), File upload (`:file_upload`, a question the visitor answers by choosing one file from a file upload control labelled with the question text, with an admin setting listing the accepted file types as comma-separated extensions such as `.pdf, .png`, which limits the visitor's file picker to those types and is shown under the control as `Accepts` followed by the list as the admin wrote it, such as `Accepts .pdf, .png`, which the admin can mark required so a visitor who chooses no file is refused, and whose recorded answer is the reference the host's file store returned for the file), four that pick a branch from earlier answers with no code — condition (`:condition`, is or is not a chosen value, where the admin must pick one of the earlier step's outputs and the answer is read from that output when the earlier step recorded several and whole otherwise, so a Condition cannot be completed on a step whose type declares no output), switch (`:switch`, follows the connection labelled with the answer), compare (`:compare`, reads the answer as a number, from the output the admin picks when the earlier step recorded several, and checks it by more than, less than, at least or at most against an amount) and Compare two values (`:compare_two_values`, reads the answers of two earlier steps the admin picks as numbers, reading each from the output the admin picks when that step recorded several, and checks the first by more than, less than, at least, at most or equal to against the second plus an amount the admin may give, a blank amount adding nothing, following its `true` or `false` connection, and following `false` when either answer is missing, is an array or is not a number) — Count (`:count`, which acts without the visitor and records a whole number, how many visits to an earlier step the admin picks the run has recorded, counting only visits that gave the answer the admin picks or every visit when the admin picks none, reading that answer from the output the admin picks when the earlier step recorded several, named on the canvas `Count` followed by the earlier step's id and the answer, such as `Count tests failed`, and recording a new count under its own visit key each time a loop reaches it, so a compare step after it can end a loop once the count reaches an amount), Wait (`:wait`, which holds the run until a time worked out from an earlier step the admin picks as `Counting from`; see "Hold a run until a time"), and Flow (`:flow_step`, names another flow of the same host and the number of one of its versions, with one connection for each different output that version's End steps write, and named on the canvas by that flow's title and the version number, such as `Intake, version 2`). When a stored run stops at a Flow step, a run of the named flow is started on the named version, and the first run waits on the Flow step. When the second run ends with an output, that output is recorded in the first run at the Flow step, and the first run moves on along the connection labelled with that output. When the second run ends with no output, nothing is recorded and the first run stays waiting at the Flow step. On a question and on a checklist the admin can give each answer info, a longer explanation the visitor opens with an info button beside that answer. An admin may connect a step back to an earlier one, so a flow can ask the same question more than once, and each visit's answer is kept. The time each step visit was completed is kept together with its recorded value; see "Read when steps were completed". A File upload step takes a file only in a flow the admin set to save each step. In a flow set to save on finish or to save nothing, a visitor who chooses a file is shown `A file can only be uploaded in a flow that saves its runs.` and cannot go on with it. Before writing a step type to ask for one answer or several, to take a file, to branch on an answer or a number, to branch on how two earlier answers compare, to branch on when an earlier step was completed, to count the visits to an earlier step, or to hold a run until a time, ask the developer whether an admin placing one of the built-in types on the canvas is enough. None of condition, switch, compare or Compare two values reads a checklist's answer, so branching on what a visitor ticked takes a step type of the app's own that defines `route`. Use this local when the app needs a step type of its own, needs a host's flows on its own pages with its own behaviour when a visitor finishes, needs a visitor's earlier answers to decide which answers a later step offers, or needs to read what a visitor answered. It assumes easy_flow is already installed and a host is declared; if not, hand off to `easy_flow-install` first.

## Interface

- `EasyFlow::Step` — a module a class includes to declare a step type with class-level words, registered with `.register`.
- `EasyFlow.step` — declares and registers a step type in one call from a block of the same words, for a type small enough not to need its own class.
- `labels_answer_by` — a word in a step type's declaration giving the label a run's recorded answer to a step of that type is shown by, on the completion page and from `EasyFlow::QuestionRunner#choice_label`.
- `outputs_named_by` — a word in a step type's declaration adding one output for each entry an admin enters in one of the type's list settings, named by that entry, so the admin decides the names of the values the step records.
- `host.allowed_answers=` — set on a host to a lambda given a step and the answers recorded so far, returning the answers that step may take in this run: several narrows the answers shown, one is recorded without showing the step, and none records a blank and skips it.
- `EasyFlow::FlowsController` — the visitor controller; the app subclasses it to serve one host's flows from its own routes and to change what happens at the start, on each step and at the finish.
- `hosted_by` — class method on a `FlowsController` subclass naming the host whose flows it serves.
- `routed_by` — class method on a `FlowsController` subclass naming the prefix of the app's own route names that the controller redirects and links to.
- `EasyFlow::Run` — the stored record of one visitor's pass through a flow, started with `EasyFlow::Run.start` on the live version or a chosen published one and pinned to that version, moved on past a waiting step with `advance`, read for the output its flow ended with by `output`, for when each step visit was completed by `completed_at` and for the time a Wait step holds it until by `held_until`, and linked to the runs its Flow steps started by `inner_runs`, to the one it is waiting on by `waiting_on`, and to the run that started it by `parent_run`.
- `EasyFlow::QuestionRunner` — reads a flow document: its steps, the next step for a set of answers and the times their steps were completed, the answers on the path taken, and a question's text and an answer's label.

## How to use it

### Declare a step type

1. Ask the developer what the step does, and which of these it is:
   - It asks the visitor for input — declare `awaits_input`.
   - It computes a value from earlier answers with no visitor input — define `process`.
   - It only picks which connection to follow — define `route`.
   - It holds the visitor until something outside the flow has happened, such as a payment arriving or a reviewer approving — declare `waits_until`. When what it waits for is only a time, ask the developer whether the built-in Wait step is enough first; see "Hold a run until a time".
   A type may both `process` and `route`. A type that does none of the four is passed through without stopping when a visitor reaches it.
2. Create the class in the app, for example `app/models/flow_steps/rating.rb`. The class name, underscored, is the type's id (`Rating` becomes `:rating`), and that id is stored in every flow that uses it, so it must not change after admins start using the type. It must not be one of the built-in ids `start`, `terminal`, `question`, `checklist`, `file_upload`, `condition`, `switch`, `compare`, `compare_two_values`, `count`, `wait` or `flow_step`:

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
   - `output :name, type:, label:, values:, from:` — a value the step records. `type` is one of `:string`, `:integer`, `:float`, `:boolean`, or boot raises `EasyFlow::UnknownOutputType`. `values:` is an array or a lambda taking the node, listing the values the output can take; the canvas offers these as the connections leaving the step, so a type that routes must declare them. `from: :<setting>` takes the values from the step chosen in that setting. A Condition step requires the admin to pick one of the earlier step's outputs, so a type whose answer admins should test with a Condition declares at least one `output`, with `values:` so the Condition offers answers to pick.
   - `outputs_named_by :<list setting>` — adds one output for each entry an admin enters in that `:list` setting, named by the entry's `name`, so the setting's entry block must declare `setting :name, type: :string`. Ask the developer whether the admin or the type decides the names of the values the step records. Do not pick.
     - The named outputs follow any outputs the type declares with `output`, in the order the admin entered them. An entry with a blank `name` adds none.
     - Each is a `:string` output labelled with its name humanized, so an entry named `coverage` is offered as `Coverage`.
     - They are offered wherever an admin picks one of a step's outputs: on a step of a type of the app's own through a setting declared with `outputs_of:`, and on the built-in Condition, Compare, Compare two values and Count steps.
     - A named output lists no values, so a setting declared with `from:` on it offers nothing to pick. A Condition, whose answer is required, cannot be completed on a named output, and a Count on one counts every visit. Ask the developer whether a Compare or a Compare two values step, which take no answer to pick, is enough for what admins will test.
     - A named output is not a connection leaving the step, so a type that routes still declares its connections with `output ... values:`.
     - The type records the values with `process`, returning a hash keyed by each name as a string. See step 6.

     ```ruby
     setting(:checks, type: :list) { setting :name, type: :string }

     outputs_named_by :checks

     def process(node, state)
       Array(node.config["checks"]).to_h { |check| [ check["name"], CheckResult.for(check["name"]) ] }
     end
     ```

     Here `CheckResult.for` is the app's own lookup.
   - `names_by :setting` or `names_by { |node| ... }` — what the step is called on the canvas, from a setting or computed.
   - `awaits_input` — the visitor is shown this step and submits an answer to it.
   - `waits_until { |node, state| ... }` or `waits_until { |node, state, times| ... }` — the run stops at this step until the block returns a truthy value. See step 8.
   - `answer_check { |node, value| ... }` — checks a submitted answer before it is recorded. `value` is the submitted string, an array of strings when the input submits several values, or `nil` or `""` when the input sent nothing. An array may hold blank strings. Return a message to refuse the answer, or `nil` to accept it. Without it every answer is accepted, including a blank one. For a file input, see step 7.
   - `labels_answer_by { |node, value| ... }` — the label a recorded answer to a step of this type is shown by. `value` is one recorded answer, and for an array answer the block is called once per entry. Return the label, or `nil` or `""` to fall back to the label of the question answer with that value, and then to the value itself. The block is called on every completion page and every `choice_label` call, so it must not be slow and must not change anything. Ask the developer what a visitor or admin reading the answer should see in place of the stored value.
   - `ends_here` / `begins_here` — marks the type as an end or a start of a flow. A run that ends on a step of an `ends_here` type gives that step's `output` setting as `run.output`, so a type of the app's own that ends a flow declares `setting :output, type: :string` for the admin to fill in, or gives no output.
   - `starts_a_flow` — when a stored run stops at a step of this type, a run of another flow is started. Without `chooses_flow`, the type must declare `setting :flow, type: :flow` and `setting :version, type: :integer`, since the new run is started on that flow's version with that number. The new run is only started at a step the run stops at, so the type must also declare `waits_until` or `awaits_input`. When the new run ends, its output is recorded under this step's id, so a type that should follow a connection per output defines `route` returning `state[node.id]` and declares an `output` whose `values:` are the outputs the named flow can end with. Before writing such a type, ask the developer whether the built-in Flow step is enough. See "Follow a run into the flow a Flow step started".
     - On the canvas, a step of the type is marked `Runs a flow`.
     - Once the step's `flow` setting names a flow, clicking the step takes the admin to that flow's page, and a `Settings` button on the step opens the step's own settings. Any other `:flow` setting the type declares is not followed by the click and is not read when the run is started.
     - A flow's page reached by clicking the step shows a `Back to <title>` button, or `Back to <slug>` when the flow it came from has no title, which returns the admin to the flow the step is in. The button is shown only when that flow belongs to the same host.
     - While the step's `flow` setting is blank, clicking the step opens its settings like any other step.
     - While an admin is connecting two steps, clicking the step picks it as the connection's target, the same as any other step.
     - The step's card shows `missing flow` while its `flow` setting is blank or names no existing flow, and `unrunnable version` while the flow exists but its `version` setting is blank, names no version of that flow, or names one that is a draft, retired or withdrawn.
     - The step's card shows `circular` while its `flow` setting names the flow the step sits in, or names a flow whose chosen version holds a `starts_a_flow` step that leads back to it the same way, through any number of flows. Each flow along the way is read at the version named in the `version` setting of the step that leads to it.
     - While `missing flow`, `unrunnable version` or `circular` shows, saving the flow as a new version and publishing it are refused. These checks are always made and are not among the optional checks set through `easy_flow-install`, so the type needs no `required:` or `check:` on those two settings for them.
   - `chooses_flow { |node| { flow: ..., version: ... } }` — for a `starts_a_flow` type, works out the flow and version a step runs from the step's own settings instead of reading the settings named `flow` and `version`. Ask the developer which settings decide the flow and version, and how. Do not pick.
     - The block is given the node only. `node.config` holds the admin's settings with string keys, without any setting declared with `kept_on:`.
     - It returns a hash with the symbol keys `flow:`, the flow's id as an integer or a string, and `version:`, the version's number. A blank value under either key is treated as not chosen.
     - When the block returns `nil`, the step falls back to the settings named `flow` and `version`.
     - What it returns is used everywhere the settings named `flow` and `version` are used otherwise: the run started when a stored run stops at the step, the `missing flow`, `unrunnable version` and `circular` marks and the refusal to save or publish, and the flow's page opened by clicking the step on the canvas.
     - The flow is found by its id alone, not through the host or owner. Ask the developer which flows the block may name, and look the flow up through the host inside the block when it must be limited to one host or owner.
     - A step of a type with no `names_by`, or whose `names_by` gives a blank, is named after the flow and version the block returns, as that flow's title and the version number, such as `Onboarding, version 2`, or `version 2` alone when the flow has no title. That name is shown on the canvas and in `Waiting for <name>.` while a run waits at the step. When the block returns `nil`, the step is not named after the settings named `flow` and `version`, and falls back to its id on the canvas and its `step_name` in the waiting message. Ask the developer whether that name is what admins and visitors should read, and declare `names_by` when it is not.
     - The block is called each time the canvas draws the step, each time the step's name is shown, each time the flow is saved as a version or published, and when a run stops at the step, so it must not be slow and must not change anything.
     - A type that routes on the new run's output declares an `output` whose `values:` are the outputs the chosen flow can end with, or the canvas offers no connections to label.

     ```ruby
     module FlowSteps
       class Offer
         include EasyFlow::Step

         step_name "Offer"

         setting :plan, type: :select, options: %w[basic premium], required: true

         starts_a_flow
         waits_until { |_node, _state| false }
         chooses_flow { |node| OfferFlow.for_plan(node.config["plan"]) }

         def route(node, state)
           state[node.id]
         end
       end
     end
     ```

     Here `OfferFlow.for_plan` is the app's own lookup, returning `{ flow: <id>, version: <number> }` or `nil`.
   - `chooses_flow_from_run { |node, run| { flow: ..., version: ... } }` — for a `starts_a_flow` type, works out the flow and version from the stored run that reached the step, such as its `owner` or its `recorded` answers, instead of from the step's settings. Ask the developer what in the run decides the flow and version, and how. Do not pick.
     - The block is given the node and the stored `EasyFlow::Run`. It returns a hash with the symbol keys `flow:`, the flow's id as an integer or a string, and `version:`, the version's number.
     - It is called only when a stored run stops at the step, once per visit, before that visit's run is started. It is never called on the canvas, when the step is named, or when the flow is saved or published.
     - A type that declares it never reads `chooses_flow` or the settings named `flow` and `version`, so it needs neither setting.
     - Since the flow is not known until a run reaches the step, the step is never marked `missing flow`, `unrunnable version` or `circular`, saving and publishing are never refused for it, and nothing checks that the chosen flow does not lead back to the flow the step is in. Clicking the step on the canvas opens its settings.
     - A step of the type with no `names_by` is named by its id on the canvas and by its `step_name` in `Waiting for <name>.`, so declare `names_by` or a `step_name` a visitor can read.
     - The flow is found by its id alone, not through the host or owner. Ask the developer which flows the block may name, and look the flow up through the run's flow's host or the run's owner inside the block when it must be limited.
     - When the block returns `nil`, a blank `flow:`, or the id of no existing flow, `EasyFlow::InnerFlowError` is raised with a message naming the step, such as `The step pick chose no flow to run`, and no run is started. A retired or withdrawn version raises `EasyFlow::InnerFlowError` as for a Flow step, and a blank version number, one naming no version of the flow, or one naming a draft raises `ActiveRecord::RecordInvalid`.
     - When the started run ends with an output, that output is recorded under the step's id as for a Flow step. When it ends with no output, `"ended"` is recorded instead, and the parent run moves on. A type that routes on what is recorded declares an `output` whose `values:` include `"ended"` beside the outputs the chosen flows can end with. Ask the developer what `"ended"` should lead to.
     - A flow set to save on finish or to save nothing, and an admin's preview, keep no stored run, so the block is not called and no run is started.

     ```ruby
     module FlowSteps
       class Plan
         include EasyFlow::Step

         step_name "Plan"

         starts_a_flow
         waits_until { |_node, _state| false }
         chooses_flow_from_run { |_node, run| PlanFlow.for_customer(run.owner) }
       end
     end
     ```

     Here `PlanFlow.for_customer` is the app's own lookup, returning `{ flow: <id>, version: <number> }` or `nil`.
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
   - A type that declares more than one `output`, or declares `outputs_named_by`, returns a hash from `process`, keyed by each output's name as a string. A later Condition, Compare, Compare two values or Count step reads the output the admin picks from that hash, and reads a recorded answer that is not a hash whole.
   - `route` returns the value that picks the connection to follow; it is compared as a string with the value each leaving connection is labelled with, so `false` follows the connection labelled `false`. Returning `nil` follows the first connection. A returned value that matches no connection's label ends the flow at that step. A route that returns `true` or `false` declares `output :result, type: :boolean, values: [true, false]`.
   - To route on when an earlier step was completed, define `route(node, state, times)` with a third argument, or `route { |node, state, times| ... }` in the block form. A `route` defined with two arguments works as before and is not given the times.
     - `times` is a hash keyed by step id as strings, holding the time each step on the path taken so far was completed, as a time in the app's time zone. For a step visited more than once, it holds the latest visit's time under the plain step id.
     - A step that only routes, a start and an end record no answer, so they have no time.
     - A step with no time is missing from the hash, so read it with `times[id]` and handle `nil`.
     - Ask the developer what about the time decides the branch, such as the hour, the weekday or how long ago it was. Do not pick. Before writing the type, ask whether a built-in Compare or Compare two values step reading the hour, weekday or minutes an earlier step was completed at is enough; see "Read when steps were completed".
   - `process` is not given the times. A `process` defined with a third argument is handed an empty hash.
   - A setting declared with `outputs_of:` also offers `completed_hour`, `completed_weekday` and `completed_minute` for a step that records a value. When the admin picks one, `state` holds no value under that name, so a type that reads the picked output works it out from `times` in `route`, or handles a missing value.
   - To branch on a checklist, read its array and return one value. Ask the developer what decides the branch, such as one given answer being ticked, any of several, or how many were ticked:

     ```ruby
     setting :step, type: :previous_step
     setting :answer, type: :string, required: true

     output :result, type: :boolean, values: [true, false]

     def route(node, state)
       Array(state[node.config["step"]]).include?(node.config["answer"])
     end
     ```
   - In a flow that loops, the first visit to a step is recorded under its id and each later visit under `<id>@<n>`, where `n` counts from 2. `route` is given the latest visit's answer under the plain step id. The `times` given to `route` and `waits_until` hold the latest visit's time under the plain step id. `process` and `waits_until` are given the answers as recorded, so the plain id holds the first visit's answer and later visits are under `<id>@2`, `<id>@3` and on. A `process` step reached again records its result under its own `<id>@<n>`. When a computing or waiting type reads an earlier step that can be asked again, ask the developer whether it should read the first visit or the latest. To end a loop after a number of visits, ask the developer whether a built-in Count step followed by a compare step is enough before writing a type that counts.
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

   Before writing a type that takes a file, ask the developer whether the built-in File upload step is enough, since it takes one file. For a type of the app's own that takes a file, ask the developer whether the step takes one file or several:
   - For one file, name the file input `answers[<step id>]`, such as `file_field_tag "answers[#{step.id}]"`. The page's form already sends files.
   - For several, name the input `answers[<step id>][]`, such as `file_field_tag "answers[#{step.id}][]", multiple: true`, and put the hidden blank field of the same name before it, as for checkboxes, so that a visitor who chooses none records an empty array and not `""`.
   - In a flow the admin set to save each step, `answer_check` is given the uploaded file, which responds to `original_filename`, or `nil` when the visitor chose none. For an input that sends several, it is given the array as sent, which may hold the hidden blank string beside the files, so check each entry that responds to `original_filename`. Once no check refuses the answer, each file is handed to the host's file store, set through `easy_flow-install`, and the string reference the store returns is recorded in its place: one reference for one file, or an array of references in the order the files were sent, with blank entries removed. When the host has no file store, `EasyFlow::NoFileStore` is raised on the visitor's submit and nothing is recorded. This holds for any step a file is sent to in a stored run, whatever its type.
   - In a flow set to save on finish or to save nothing, no file reaches the check, and it is given a string, an array of strings, or `nil` instead. Refuse an answer that does not respond to `original_filename`, as the built-in step does with `A file can only be uploaded in a flow that saves its runs.`, or that string is recorded as the answer.
   - Declare `labels_answer_by` to show the recorded reference by a name a reader knows, such as the file's name read back from the app's store. For an array of references the block is called once per reference.

   A compare or Compare two values step reads a typed answer such as `"12"` as the number it spells, and an answer that is missing, is an array or is not a number makes it follow its `false` connection.

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

   - The block is given `node` and `state`, and is not given the run or its owner. Ask the developer what the step waits for, and how the block finds it from the step's settings and the answers recorded before it. If it cannot be found from those, stop and ask, since the block has nothing else to read.
   - A block that takes a third argument is also given `times`, a hash keyed by step id as strings holding the time each completed step was completed, as a time in the app's time zone, with the latest visit's time under the plain step id for a step visited more than once. A step with no time is missing from it. When the step waits only for a time, ask the developer whether the built-in Wait step is enough before writing the type.
   - The block is called each time the visitor loads the step page, and each time the app calls `run.advance`. Keep it to a single lookup.
   - While the block returns a falsy value, the visitor is shown `Waiting for <name>.` and no form, no Next button and no Back button. `<name>` is what `names_by` gives, or for a type that declares `chooses_flow` the chosen flow's title and version, or the `step_name` when there is neither, so give the type a name a visitor can read.
   - In a flow that keeps no stored run, the waiting page also shows a `Check again` button that loads the page again with the answers and the times their steps were completed.
   - Once the block returns a truthy value, `true` is recorded under the step's id, or the value `process` returns when the type also defines `process`, and the run goes on to the next step.
   - Do not declare `awaits_input` on a type that waits. The waiting message replaces the form, so the input is never shown.
   - The page does not reload itself. Ask the developer how the run should move on when what it waits for happens:
     - The visitor reloads the page, or presses `Check again` in a flow that keeps no stored run. This needs nothing more, and works whether or not the flow keeps a stored run.
     - The app calls `run.advance` where the event is handled, such as a webhook or a job. See "Read a run and its answers". This needs a stored run, so it only applies to a flow the admin set to save each step.
9. Restart the server, open a flow on the canvas of each host that should offer the type, and check the type is in the palette, its settings show, and a preview walks through it. On a host that names a list of offered step types without the type's id, check the type is not in the palette. For a type that declares `starts_a_flow`, check the step is marked `Runs a flow`, that once a flow is picked in its settings clicking the step goes to that flow's page, that the `Back to` button on that page returns to the flow the step is in, and that its `Settings` button opens its settings. Also check that the step shows `missing flow` while no flow is picked, `unrunnable version` while the version number names no live or replaced version, `circular` while it names the flow it sits in, and that publishing is refused until each is fixed. For a type that declares `chooses_flow`, set the settings the block reads and check that clicking the step goes to the flow the block names, that a type with no `names_by` is named on the canvas by that flow's title and version, and that a run stopping at the step starts a run of that flow on that version. For a type that declares `chooses_flow_from_run`, start a stored run whose owner or answers the block reads, walk it to the step, and check `run.waiting_on` is a run of the flow and version the block names, and that a run for which the block names no flow raises `EasyFlow::InnerFlowError`.

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
   - `finished(answers, run)` — called when the visitor reaches the end. `answers` is the answers on the path taken, keyed by step id as symbols, each a string or, for a checklist, an array of strings. `run` is the stored `EasyFlow::Run`, or `nil` when the admin set the flow to save nothing. A flow the admin set to save on finish gets its run created at this point. To act on which way the flow ended, read `run.output`; when `run` is `nil` there is no output to read. It must render or redirect. Default: the engine's completion page, which lists each answer on the path taken by its label, a checklist's answer as the labels of everything ticked joined into one sentence, and a File upload step's answer as the name the host's file store gives the file.
   - `start_run(flow)` — creates the run when a visitor starts a flow the admin set to save each step. Call `super` and change the run it returns, for example to set its `owner` or `label`. To start the run on a version other than the live one, return `EasyFlow::Run.start(flow, version: ...)` instead of calling `super`; see "Start a run on a chosen version".
   - `runner_for(definition)` — returns the runner used for each step. Return a subclass of `EasyFlow::QuestionRunner` to change what the step and completion pages read from it, built with `host: flow_host`, such as `IntakeRunner.new(definition, host: flow_host)`. A runner built without `host:` ignores the host's `allowed_answers`, so every step offers every answer and none is filled in or skipped.
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
   - A run of the flow named in the step's settings is started on the version with the number in its settings, or of the flow and version its type's `chooses_flow` or `chooses_flow_from_run` block returns. The flow is found by its id alone and not through the host, since a `:flow` setting is not checked on save.
   - The new run's `parent_run` is the run that reached the step, and its `parent_step` is the step's id as a string, or the visit key such as `"sub@2"` on a later visit in a loop.
   - The new run is moved on at once past every step that acts without the visitor, the same as `run.advance`. When it stops at a Flow step of its own, that starts a further run the same way.
   - It is started once per visit to the step, so loading the page again or calling `advance` again starts no second one.
   - Its `owner` is the parent run's `owner` at the moment the new run is started, or blank when the parent run has none. Setting or changing the parent run's owner later does not change it. Its `label` and `status` are not copied and are left blank.
   - The parent run shows the visitor `Waiting for <name>.`, where the built-in Flow step's name is the named flow's title and version number, such as `Waiting for Intake, version 2.`, with no form, no Next button and no Back button, and stays on the Flow step until the new run ends.
   - A flow set to save on finish or to save nothing, and an admin's preview, keep no stored run, so they start no run at a Flow step.
   - A flow cannot be published while one of its Flow steps names a missing flow, a version that cannot run, or a flow that leads back to it. A flow or version can still stop being runnable after the flow holding the step was published, such as a named flow being deleted or its version retired or withdrawn. Then, at the moment the run stops at the Flow step, one of these is raised and no run is started:
     - `ActiveRecord::RecordNotFound` when the named flow is gone.
     - `EasyFlow::InnerFlowError` when the named version is retired or withdrawn, with a message naming the Flow step's id, such as `The Flow step sub names a version that cannot run`.
     - `ActiveRecord::RecordInvalid` when the version number is blank, names no version of the flow, or names a draft.
3. What holds when the new run ends with an output, whether on its visitor's page load or on `inner.advance`:
   - The new run's `output` is recorded in the parent run under its `parent_step`, so `run.recorded[:<step id>]` holds the text the admin wrote on the End step the new run ended on.
   - It is recorded once. Loading the new run's page again or calling `advance` on it again changes nothing on the parent run.
   - A job is queued with the app's Active Job adapter, on the `default` queue, that calls `advance` on the parent run. The parent run also moves on the next time its own page is loaded, whichever comes first, so a parent run whose job never runs still moves on when its visitor reloads.
   - The parent run follows the connection leaving the Flow step labelled with that output. An output that matches no connection's label ends the parent run at the Flow step.
   - When the parent run then ends and was itself started by a Flow step, its own output is handed to its parent the same way.
   - The new run's own `finished` is still called on its visitor's page load. The job does not call `finished` for the parent run, and if the parent run reaches its end, `finished` is called the next time its visitor loads its page.
   - A visitor who presses Back on the step after a Flow step removes the recorded output, and the parent run waits on the Flow step again. No second run is started, and the parent run moves on again only when the new run's page is loaded or `advance` is called on it.
4. What holds when the new run ends with no output, which happens when it ends on an End step whose output was left blank, or ends without reaching an End step, and the step that started it is not of a type that declares `chooses_flow_from_run` (for that type, `"ended"` is recorded and the parent run moves on):
   - Nothing is recorded in the parent run, and the parent run stays at the Flow step showing `Waiting for <name>.` on every page load. Nothing in the engine moves it on.
   - A job is still queued that fails with `EasyFlow::InnerFlowError` and a message naming the Flow step's id, such as `Nothing was recorded at the Flow step sub, so its run cannot move on`. The job does not move the parent run.
   - Each later page load of the new run, and each later `advance` on it, queues another job that fails the same way.
   - What happens to a failed job, such as a retry or a report, is decided by the app's Active Job adapter and error reporting.
   - The new run's own `finished` is still called on its visitor's page load.
5. What holds when an admin removes a flow:
   - Every run of the removed flow is deleted with it.
   - A run that one of those runs' Flow steps started is kept. Its `parent_run` becomes `nil` and its `parent_step` keeps the step id.
   - When such a kept run ends, nothing is recorded anywhere and no job is queued.
   - Removing a flow is refused while one of its runs is the run that a run of another flow is stopped at a Flow step waiting on, so a waiting run's `waiting_on` is never deleted this way.
   - A run of the removed flow that was started by a Flow step but is no longer waited on is deleted, so `run.inner_runs.find_by(parent_step: step_id)` returns `nil` for that step afterwards.
6. Find the runs:
   - `run.waiting_on` — the run started at the step `run` is stopped at, or `nil` when `run` is stopped at a step that started no run, or has reached its end.
   - `run.inner_runs.find_by(parent_step: step_id)` — the run started at a given step, or visit key such as `"sub@2"`, whether or not `run` is still stopped there.
   - `run.parent_run` — the run that started `run`.
7. Nothing takes the visitor from the parent run to the new run. Ask the developer how the visitor gets there, such as a link on the app's own page or a redirect from the app's controller, and where to show the new run, which is the `_run` route of the controller serving its host, such as `main_app.intake_run_path(run.waiting_on)`. Do not pick.
8. Nothing takes the visitor back to the parent run when the new run ends either. Ask the developer whether the visitor goes back, and if so override `finished(answers, run)` in the controller serving the new run's host to redirect when `run&.parent_run` is present, to the `_run` route of the controller serving the parent run's host. Check `run&.parent_run` and not `parent_step`, since a run whose parent flow was removed keeps its `parent_step` with no `parent_run`:

   ```ruby
   def finished(answers, run)
     return redirect_to main_app.intake_run_path(run.parent_run) if run&.parent_run

     super
   end
   ```

9. The new run already belongs to the parent run's owner, so a run that should have an owner needs it set on the parent run before the parent reaches the Flow step, such as in `start_run(flow)`. Ask the developer whether the new run should belong to a different record, and if so set it where the app sends the visitor on, for example `run.waiting_on.update!(owner: ...)`.
10. Ask the developer what the visitor is shown when the parent run cannot start its new run, since `ActiveRecord::RecordNotFound`, `EasyFlow::InnerFlowError` or `ActiveRecord::RecordInvalid` is raised on the visitor's page load.
11. Ask the developer what each output of the named flow should lead to in the parent flow. Each different output on the named version's End steps is a connection leaving the Flow step on the canvas, which an admin connects, so no code is needed unless the app acts on the output itself. Only outputs written on built-in End steps are offered as connections, so a named flow that ends on a step of the app's own `ends_here` type hands over an output that matches no connection, and the parent run ends at the Flow step.
12. Ask the developer what should happen when a named flow ends with no output and its parent run is left waiting, such as admins writing an output on every End step of a flow another flow names, or the app watching for the failed job's `EasyFlow::InnerFlowError` and acting on the parent run. Do not pick. Publishing does not refuse a named flow whose End step has a blank output.
13. Publish a flow with a Flow step set to save each step, start a run with an owner, walk it to the Flow step, and check `run.waiting_on` is one run of the named flow with that run as its `parent_run` and the same `owner`, and that reloading the page starts no second one. Walk the new run to an End step, and check the parent run records that End step's output at the Flow step and moves on along the connection labelled with it. Walk another new run to an End step with a blank output, and check the parent run stays waiting and the queued job fails with `EasyFlow::InnerFlowError`. While a parent run waits on a new run, check that removing the named flow is refused. Remove the parent run's flow, and check the new run is kept with no `parent_run` and that finishing it neither raises nor queues a job.

### Decide which answers a step offers in a run

Use this when what a visitor answered earlier decides which answers a later step may take, such as a product sold as a download only being offered `download`.

1. Ask the developer which steps of which host's flows this applies to, which earlier answers decide it, and which answers each combination allows. Do not pick.
2. Inside the block that declares the host, set through `easy_flow-install`, assign a lambda:

   ```ruby
   host.allowed_answers = ->(step, answers) do
     case step.id.split("@").first
     when "sold_as" then %w[download] if answers[:kind] == "pdf"
     end
   end
   ```

   - `step` is the step the run has stopped at, with `id`, `type` and `config`. On a later visit to a step in a flow that loops, its `id` is the visit key `<id>@<n>`, so compare the part before `@` to match every visit.
   - `answers` is the answers recorded so far, keyed by step id as symbols, with later visits under `:"<id>@<n>"`. A value is a string, an array of strings, or what a computing step recorded.
   - The lambda is called for every step the run stops at: one that awaits input, one that computes a value, one that waits, and a Flow step. It is not called for a step that only routes, a start or an end.
   - It is called several times on every page load and on every `run.advance`, so it must not be slow and must not change anything.
3. What it returns decides the step:
   - `nil` — the step offers every answer and behaves as it would with no lambda.
   - An array of two or more strings — the visitor is shown only the answers whose value is in the array, compared exactly as strings. This narrows a question, a checklist, and an app type whose display object answers `choices` and `with(choices:)`, such as one built with `Data.define`. Any other display is shown unchanged.
   - An array of one string — that string is recorded under the step's id without the step being shown, and the run moves on.
   - An empty array — `""` is recorded under the step's id without the step being shown, and the run moves on.
   - For one or none, what is recorded replaces whatever the step's type would do: a computing step's `process` is not called, a waiting step does not wait, and a Flow step starts no run.
4. What then holds:
   - It applies on the visitor's step pages of the host's flows, whether the flow keeps a stored run or carries its answers in the page, in an admin's preview, and on `run.advance`, which reads the host the run's flow belongs to.
   - A runner the app builds itself, such as `EasyFlow::QuestionRunner.new(run.pinned_definition)`, ignores it unless built with `host:`.
   - The Back button removes every answer the host filled in after the last step the visitor was shown, and the visitor's answer to that step, and shows that step again.
   - A filled-in or skipped step's answer is in `run.recorded` and on the completion page like any other answer, `""` for a skipped one.
   - The array narrows only what is shown. A submitted value outside it is still recorded unless the step type's `answer_check` refuses it, and `answer_check` is not given the earlier answers. Ask the developer whether that is acceptable.
5. Publish a flow on the host, walk it with earlier answers that allow several, one and no answers to a step, and check the step shows only the allowed answers, is filled in, and is skipped. Press Back after a filled-in step and check the visitor returns to the question before it.

### Read when steps were completed

Use this when the app or a flow's branches depend on when a visitor completed a step, such as routing differently out of hours, or reading how long a visitor took between two steps.

1. The times on a stored run need the engine's migrations installed, which `easy_flow-install` does.
2. What holds:
   - Each time a step visit records a value, the current time is kept with that value as the time the visit was completed, under the same key, including each later visit's `<id>@<n>`. This covers a visitor's answer, a value `process` computed, a waiting step moving on, and an answer the host's `allowed_answers` filled in or skipped.
   - The Back button removes the time with the value.
   - In a flow set to save each step, each value and its time are kept on the run together as the step is completed.
   - In a flow set to save on finish or to save nothing, the times travel in the page with the answers, and the engine's step page carries them, so a partial adds nothing for them. A flow set to save on finish keeps the times of the steps on the path taken on the run it creates. A flow set to save nothing keeps none.
   - In a flow set to save on finish or to save nothing, the times come from the page, so a visitor can change them. Ask the developer whether anything that depends on a time, such as a Wait step or a branch on the hour, may be decided by the visitor in those flows.
   - A value a run held before the engine kept times has no time.
3. Every step that records a value, which is a step that awaits input, computes a value or waits, offers three outputs wherever an admin picks one of its outputs:
   - `completed_hour`, labelled `Hour completed` — the hour of the day it was completed, 0 to 23, in the app's time zone.
   - `completed_weekday`, labelled `Weekday completed` — the day of the week it was completed, 1 for Monday to 7 for Sunday, in the app's time zone.
   - `completed_minute`, labelled `Minutes since 1970 when completed` — the whole minutes from the start of 1970 to when it was completed, so two of them subtract to the minutes between two completed steps.
   - For a step visited more than once, each reads the latest visit's time.
4. Compare and Compare two values read these outputs. A Compare step on `completed_hour` at least 17 branches on a step completed after 5pm. A Compare two values step comparing one step's `completed_minute` with an earlier step's `completed_minute` plus 30 branches on whether the later step was completed at least 30 minutes after the earlier one. A step with no time makes either one follow its `false` connection.
5. Condition and Count also offer these outputs but do not read them. A Condition cannot be completed on one, since there is no answer to pick, and a Count on one counts every visit.
6. For a type of the app's own, see the `route` bullets in step 6 of "Declare a step type" and the `waits_until` bullets in step 8.
7. Read the times from a stored run with `run.completed_at`; see "Read a run and its answers".
8. Publish a flow set to save each step with a Compare on a question's `completed_hour`, walk it, and check the branch taken matches the hour the question was completed and that `run.completed_at` holds a time for each recorded value.

### Hold a run until a time

Use this when a visitor's run should stop until a set time has passed, such as an hour after a form was submitted, the next 9:00 after it, or a fixed date.

1. Ask the developer whether an admin placing the built-in Wait step on the canvas is enough before writing a type. It is in every host's palette unless the host names a list of offered step types without `wait`, which is set through `easy_flow-install`.
2. The Wait step's settings, filled in by the admin:
   - `Counting from` — an earlier step, required. The time the step was completed is the time the wait counts from, or the latest visit's time when it was visited more than once.
   - `Minutes after it` — a whole number of minutes. Blank counts as 0.
   - `Next time of day after it, as HH:MM` — the run is held until the first time the clock reads that hour and minute after the counted time, in the app's time zone, which is the same day when that is still to come and the next day otherwise.
   - `Date, as YYYY-MM-DD` — the run is held until the start of that date in the app's time zone.
   - A date wins over a time of day, and a time of day wins over minutes. The time of day and the date are not checked on save, so a value in another form is not refused.
   - The step is named on the canvas and in the waiting message by what it waits for: the date as the admin wrote it, such as `2026-10-12`, or else the time of day followed by `after` and the counted step's id, such as `09:00 after ask`, or else the minutes followed by `minutes after` and the counted step's id, such as `30 minutes after ask`. When the date, the time of day and the minutes are all blank, the step is named by its id on the canvas and the waiting message reads `Waiting for Wait.`, and the run moves on as soon as the counted step has a time.
3. What then holds:
   - Without a date, the run is held for as long as the counted step has no time, such as a step that only routes or a step not on the path taken.
   - While held, the visitor is shown `Waiting for <name>.`, such as `Waiting for 30 minutes after ask.`, with no form, no Next button and no Back button.
   - Once the time has passed, `true` is recorded under the step's id and the run goes on, when the visitor next loads the page or the app calls `run.advance`, the same as any waiting step. The page does not reload itself. Ask the developer how the run should move on, as in step 8 of "Declare a step type", such as a job the app schedules for `run.held_until` that calls `run.advance`.
   - `run.held_until` gives the time a stored run stopped at a Wait step is held until, or `nil` when it is not stopped at a Wait step or the time is not known yet.
   - In a flow set to save on finish or to save nothing, the waiting page also shows a `Check again` button, which loads the page again with the answers and the times their steps were completed, so the Wait moves on once its time has passed. Reloading the page in the browser instead takes the completion time of the step just submitted again, so a Wait counting minutes or a time of day from that step does not move on by reloading. Ask the developer whether such a flow needs to be set to save each step.
4. Publish a flow set to save each step with a Wait step counting a few minutes from a question, walk it to the Wait step, check the page shows `Waiting for <minutes> minutes after <question id>.` and `run.held_until` is that many minutes after the answer, and check `run.advance` after that time moves the run on. In a flow set to save nothing, walk to the same Wait step, wait past the time, press `Check again`, and check the next step is shown.

### Read a run and its answers

1. Find runs scoped to one host so one host never sees another's: `EasyFlow::Run.joins(:flow).where(easy_flow_definitions: { host: "intake" })`.
2. Read from a run:
   - `run.recorded` — the answers so far, a hash keyed by step id as symbols. A value is a string, or an array of strings for a checklist or any step that takes several answers, empty when nothing was ticked. A File upload step's value is the reference the host's file store returned, not the file, and a step of the app's own that took several files holds an array of references, so the app reads each file back from its own store.
   - `run.completed_at` — the time each step visit was completed, a hash keyed the same as `run.recorded`, each value a time in the app's time zone, including each later visit under `:"<id>@<n>"`. A value recorded before the engine kept times has no time, so its key is missing. See "Read when steps were completed".
   - `run.held_until` — the time the run is held until while stopped at a Wait step, or `nil`. See "Hold a run until a time".
   - `run.flow` — the flow it belongs to.
   - `run.owner` — the optional record the run belongs to, polymorphic, set by the app. `run.label` and `run.status` are free string columns for the app's own use.
   - `run.parent_run` and `run.parent_step` — the run whose Flow step started this one and that step's id, both `nil` for a run a visitor or the app started. Once this run ends with an output, `run.parent_run.recorded` holds that `output` under that step id. When it ends with none, nothing is recorded there. When an admin removed the flow the parent run belonged to, `parent_run` is `nil` and `parent_step` still holds the step id.
   - `run.inner_runs` — the runs this run's Flow steps started.
   - `run.waiting_on` — the run started at the step this run is stopped at, or `nil` when no run was started there.
   - `run.pinned_definition` — the flow document of the version the run started on.
   - `run.next_step(answers)` and `run.walked(answers)` — the next step, and the answers on the path taken, for a set of answers against that pinned version, routed with the run's own `completed_at`.
   - `run.output` — the text the admin wrote into the output setting of the End step the run ended on, read from the run's pinned version. It is `nil` when the run has not reached an End step, or ended on one whose output was left blank. A flow may have several End steps with a different output on each, so the output says which way the flow ended. Ask the developer what the app does with each output, and what it does when there is none.
   - `run.advance` — moves the run past every waiting step whose `waits_until` block now returns a truthy value, and past every step that computes a value, and records each result on the run. It stops at the next step that asks the visitor for input, the next waiting step that is not ready, or the end. It does not call `finished`; that is called the next time the visitor loads the run's page. When it stops at a Flow step it starts that step's run, and when it reaches the end of a run a Flow step started it hands the output to the parent run; see "Follow a run into the flow a Flow step started".
3. To show answers with their question text and answer labels, build a runner from the run's pinned document:

   ```ruby
   runner = EasyFlow::QuestionRunner.new(run.pinned_definition)
   runner.state_on_path(run.recorded, times: run.completed_at).each do |step_id, value|
     puts "#{runner.question_text(step_id)}: #{runner.choice_label(step_id, value)}"
   end
   ```

   - Pass `times: run.completed_at` to `state_on_path` and `next_step`. Without it, a step that routes on when an earlier step was completed finds no time, so a Compare or Compare two values reading a time follows `false` and the path read may differ from the one the visitor took.
   - `state_on_path(answers, times: {})` — only the answers on the path the visitor actually took, in the order they were given, dropping answers left behind by going back. In a flow that loops, it holds every visit: the first under the step id and each later one under `:"<id>@<n>"`, such as `:"job@2"`. Ask the developer whether each visit is shown as its own line or the visits to one question are grouped together; to group them, take the part of the key before `@`.
   - `question_text(id)` — the text of a question or checklist step, given either its id or a visit key such as `"job@2"`. For a step of any other type it returns that step's `question` setting, or `nil` when it has none.
   - `choice_label(id, value)` — the label the step's type gives the answer with `labels_answer_by`, or else the label of one chosen answer on a question or checklist, or else the value itself. For a File upload step it is the name the host's file store gives the recorded reference, or the reference itself when the store gives none. It takes a visit key the same way as `question_text`. Handed a checklist's array, it returns one string, the label of each ticked value joined into a sentence such as `Email, Phone, and Post`, and an empty string when nothing was ticked. Ask the developer whether a checklist's answers are shown as that one sentence or each on its own; for each on its own, call it once per ticked value with `value.map { |ticked| runner.choice_label(step_id, ticked) }`.
   - `step(id)` finds the step for either its id or a visit key.
   - `next_step(answers, run: nil, times: {})` — the next step to show, built by its type's `displays_by`. Pass `run:` when a type's display block takes the run. Its answers are narrowed by the host's `allowed_answers` only when the runner was built with `host:`.
   - `steps_on_path(answers)` — the steps on the path taken, each built by its type's `displays_by` with a `nil` run.
   - `steps`, `slug` and `headline` read the rest of the document.

## Conventions

- A step type's id comes from its class name or the id passed to `EasyFlow.step`, and it is stored in flow documents, so renaming the class or id breaks every flow that uses it.
- Never give a step type one of the built-in ids: `start`, `terminal`, `question`, `checklist`, `file_upload`, `condition`, `switch`, `compare`, `compare_two_values`, `count`, `wait`, `flow_step`.
- Register class-based step types inside `to_prepare`. A type registered anywhere else is lost on code reload in development.
- Registering a type does not put it in the palette of a host that names a list of offered step types without the type's id. Which step types a host offers is set through `easy_flow-install`, not here.
- A type that declares `ends_here` is in every host's palette, and a type that declares `begins_here` is in no host's palette.
- An `options:` lambda is passed nothing, and one list is offered on every host's canvas, so it cannot narrow the options by admin, account or host.
- A setting declared with `kept_on:` lives only on the app's record, written when the admin saves the step, so a step's code never finds it in `node.config`.
- A `kept_on:` lambda is given only the step's settings, so it cannot limit which records an admin reaches by admin, account or host.
- A `:flow` setting holds a flow's id as a string and is not checked against the flows offered, so code reading it looks the flow up through the host.
- A `starts_a_flow` type reads the flow and version to run from its `chooses_flow_from_run` block when it declares one, and otherwise from the settings named `flow` and `version`, unless it declares `chooses_flow` and that block returns a choice.
- A `chooses_flow` block is given only the step, finds the flow by id with no host or owner scope, and is called on every canvas draw, name shown, save and publish, so it limits the flows it names itself and changes nothing.
- A step of a `chooses_flow` type with no `names_by` is named by the chosen flow's title and version number.
- A `chooses_flow_from_run` block is called only when a stored run stops at the step, finds the flow by id with no host or owner scope, and is never checked on save or publish, so the block limits the flows it names itself.
- A run started by a `chooses_flow_from_run` step that ends with no output records `"ended"` at that step, and the parent run moves on.
- A host's `allowed_answers` lambda is given only the step and the answers recorded so far, and is called many times per page load, so it reads only those and changes nothing.
- A step the host allows one answer is recorded without being shown, and one it allows none is recorded as `""` and skipped, whatever the step's type.
- A runner the app builds without `host:` ignores the host's `allowed_answers`.
- A flow holding a `starts_a_flow` step whose `flow` names no existing flow, or whose `version` names no live or replaced version of it, or whose `flow` leads back to the flow the step sits in directly or through other flows, cannot be saved as a version or published, and these checks cannot be turned off.
- On the canvas, clicking a step of a `starts_a_flow` type whose `flow` setting names a flow goes to that flow's page, which has a `Back to` button to the flow the step is in, and the step's settings open from its `Settings` button.
- A type that routes declares the values its output takes, or the canvas offers no connections to label.
- An output named by `outputs_named_by` takes its name from an entry's `name`, lists no values, and is never a connection leaving the step.
- A run starts only on a version its own flow has published and not retired or withdrawn, and any other version raises `ActiveRecord::RecordInvalid`.
- Always read a run against `run.pinned_definition`, never the flow's live version, since a run keeps the version it started on after a new one is published.
- Always look flows and runs up through a host.
- In a flow that loops, a later visit's answer is keyed `<id>@<n>`, so code that reads answers never assumes one answer per step id. A step id may not contain `@`, and a flow with one is refused when published.
- A loop that comes back to a step with no answer given since the last visit to it ends the flow there, so every loop needs a step that awaits input.
- A step's input field is named `answers[<step.id>]` for one value or `answers[<step.id>][]` for several. Any other name is ignored, and a hash is treated as blank.
- An answer is a string or an array of strings, so code that reads answers never assumes a string. A checklist's answer is always an array.
- Condition, switch, compare and Compare two values do not branch on an array answer. Branching on one takes an app step type that defines `route`.
- A `displays_by` block that takes the run handles a `nil` run.
- A file is taken only in a flow that keeps a stored run, only from an input named `answers[<step.id>]` or, for several files, `answers[<step.id>][]`, and only when the host has a file store, and the run records the store's reference for each file, never the file.
- A `labels_answer_by` block changes only how an answer is shown, never what is recorded.
- An answer the type's `answer_check` refuses is never recorded, and the visitor is shown the same step with the check's message. An answer no check refuses is recorded, a blank single one as `""`.
- A `waits_until` block is given only the step, the answers recorded so far and, when it takes a third argument, the times their steps were completed, so what it waits for must be findable from those.
- A `route` is given the times steps were completed only when it takes a third argument, and `process` is never given them.
- Every value a step visit records is kept with the time the visit was completed, on a stored run and carried in the page otherwise, and a time carried in the page can be changed by the visitor.
- A runner the app builds reads times only when handed `times: run.completed_at`.
- A Wait step without a date holds the run for as long as the step it counts from has no time.
- A type that waits never also declares `awaits_input`.
- `run.advance` only moves a stored run, and never finishes it; the visitor's next page load does.
- A flow's output is free text an admin writes on each End step, so code that acts on it handles `nil` and any value it does not expect.
- A flow's output is read from a stored run only, so a flow the admin set to save nothing gives none.
- A run started by a Flow step takes the owner its parent run had when it was started, and nothing sends the visitor to it or back from it.
- A run that reaches a Flow step waits there until the run it started ends with an output, then records that output and follows the connection labelled with it.
- A run started by a Flow step that ends with no output leaves its parent run waiting at the Flow step, and each job queued to move the parent on fails with `EasyFlow::InnerFlowError`.
- A Flow step whose named version was retired or withdrawn after publishing raises `EasyFlow::InnerFlowError` naming the step when a run stops there.
- A parent run is moved on by an Active Job job, so the app's queue adapter must run jobs for it to move on without its visitor reloading.
- Only a stored run starts a run at a Flow step.
- Removing a flow deletes its runs and keeps the runs their Flow steps started with no `parent_run`, so code that follows a run to the run that started it reads `parent_run` and handles `nil`.
- A flow cannot be removed while a run of another flow is waiting on one of its runs at a Flow step.
- A `FlowsController` subclass needs all four named routes for its prefix; a missing one raises when the visitor is linked or redirected to it.
- The engine installs, mounts and configures hosts, the step types each host offers, layouts, the default drawing and checks through `easy_flow-install`, not here.
