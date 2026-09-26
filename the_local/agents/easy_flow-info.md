---
name: easy_flow-info
description: Use to learn what easy_flow offers — guided flows an admin draws on a canvas and a visitor runs one step at a time, versioned documents of steps and connections, hosts, runs, the built-in step types including questions that can require an answer and branching on an answer or comparing a number, step types the host app registers and the checks they make on an answer, and the settings an admin fills in, including picks whose options come from the app's data.
tools: Read
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local explains easy_flow and the words it uses. It makes no changes and gives no steps.

## What easy_flow is

easy_flow is a Rails engine for guided, branching flows. An admin builds a flow on a canvas by placing steps and connecting them, previews it, and publishes it. A visitor then walks the published flow one step at a time, and each answer decides which step comes next.

Reach for it when an app needs a questionnaire, an intake form, or any decision path that an admin should be able to change without a deploy. The engine ships a start step, an end step, a question step, and three steps that pick a branch from earlier answers. Anything else a flow needs to ask or do is a step type the app declares itself.

## Interface

easy_flow declares no commands of its own for this local. Its surface is split between the other two:

- **easy_flow-install** owns putting the engine into an app: its migrations, mounting it, choosing the controller it inherits from, naming hosts, choosing the default step drawing, the flow checks, and the admin pages.
- **easy_flow-develop** owns building on it: declaring and registering step types, serving a host's flows from the app's own controllers and routes, and reading a visitor's run and answers.

## How to use it

- To get easy_flow running in an app, or to change how it is configured, use **easy_flow-install**.
- To add a step type, give a step type its own rule for refusing an answer, put a flow on the app's own pages, or act on what a visitor answered, use **easy_flow-develop**.
- To branch a flow on an answer or on a number the visitor gave, no code is needed: an admin places one of the built-in branching steps on the canvas.
- To make a visitor answer a question before going on, no code is needed: an admin marks that question step as required on the canvas.
- If the question is only what a word below means, this page is the answer.

## Conventions

- **Flow** — one guided path, found by its slug within its host. It holds a working document the admin edits and a list of versions.
- **Document** — the flow's content: its steps (nodes), the connections between them (edges), a headline and a slug.
- **Version** — a numbered snapshot of the document. A version is a draft until it is published, and a flow has at most one live version at a time.
- **Canvas** — the admin screen where steps are added, configured, moved, removed and connected, with undo and redo. Publishing happens there.
- **Preview** — an admin walking the current flow without starting a stored run.
- **Step type** — what a kind of step is: its display name, its settings (the fields an admin fills in), its outputs (the values it records), and whether it waits for the visitor or acts on its own. A step that acts on its own may record a value worked out from the answers so far, pick which connection to follow, or both.
- **Answer check** — a rule a step type may carry that looks at a visitor's answer and, when the answer is not acceptable, returns the message the visitor sees. A step type with no such rule accepts every answer.
- **Setting** — one field an admin fills in when configuring a step on the canvas. It is text, a whole number, a decimal, a yes or no, a pick from a list, several picks from a list, an earlier step, an earlier step's output, or a list of entries that each hold their own fields. A setting can be required, limited to a number of picks, or checked by a rule the step type supplies.
- **Options** — the values a pick-from-a-list setting offers. They are either a fixed list written into the step type, or a lookup the app provides that is read each time the canvas or a save asks for them, so they can come from the app's own data. A saved value that is not among the options is refused.
- **Output** — a value a step records into the run, with a type and a label. Later steps read outputs, and a setting that points at an earlier step offers that step's known values on the canvas.
- **Start** and **End** — the built-in step types that begin and finish a flow.
- **Question** — the built-in step type that asks the visitor: a question text, an optional category, a yes-or-no required setting, and a list of answers, each with a value, a label and a weight.
- **Required question** — a question step the admin has marked required. A blank answer to it is refused with the message "Fill this in to go on."
- **Condition** — a built-in branching step that checks whether an earlier step's answer is, or is not, a chosen value, and follows the true or the false connection.
- **Switch** — a built-in branching step that follows the connection labelled with an earlier step's answer.
- **Compare** — a built-in branching step that reads an earlier step's answer as a number and checks it against an amount by more than, less than, at least or at most, then follows the true or the false connection. When the earlier step recorded several outputs, the admin picks which one. An answer that is missing or is not a number decides false.
- **Registry** — the list of step types the app has registered, alongside the built-in ones. A step whose type is not registered is not shown or run as that type, and its answers are not checked.
- **Host** — a named part of the app that owns a set of flows. A host sets the visitor layout and the admin layout, how admins are authenticated, how visitors are authorized, and how a refusal is answered. Flows are always looked up through a host, so one host never sees another's flows.
- **Run** — one visitor's pass through a flow. A run is pinned to the version that was live when it started, so publishing a new version does not change a run already under way. It records each answer by step id, and going back discards the last answer on the path.
- **Answers** — the recorded state of a run, keyed by step id. The next step is always worked out from these answers and the connections in the pinned version.
- **Refused answer** — an answer the step's answer check turned down. Nothing is recorded for that step, and the visitor is shown the same step again with the check's message. This works the same whether the flow keeps a stored run or carries its answers in the page.
- **Blank answer** — a step the visitor leaves blank. On a step whose answer check does not refuse it, such as a question that is not required, the blank is recorded and the visitor moves on to the next step.
- **Checks** — warnings on a flow's shape: an answer value no connection routes, a path nothing follows, and a step that leads nowhere. The engine turns all three on by default. These are separate from answer checks, which look at what a visitor submits.
