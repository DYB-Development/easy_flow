---
name: easy_flow-info
description: Use to learn what easy_flow offers — guided flows an admin draws on a canvas and a visitor runs one step at a time, versioned documents of steps and connections, hosts, runs, and step types the host app registers.
tools: Read
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local explains easy_flow and the words it uses. It makes no changes and gives no steps.

## What easy_flow is

easy_flow is a Rails engine for guided, branching flows. An admin builds a flow on a canvas by placing steps and connecting them, previews it, and publishes it. A visitor then walks the published flow one step at a time, and each answer decides which step comes next.

Reach for it when an app needs a questionnaire, an intake form, or any decision path that an admin should be able to change without a deploy. The engine ships one step type, a question with a list of answers. Anything else a flow needs to ask or do is a step type the app declares itself.

## Interface

easy_flow declares no commands of its own for this local. Its surface is split between the other two:

- **easy_flow-install** owns putting the engine into an app: its migrations, mounting it, choosing the controller it inherits from, naming hosts, choosing the canvas drawing, turning on optional checks, and the admin pages.
- **easy_flow-develop** owns building on it: declaring and registering step types, serving a host's flows from the app's own controllers and routes, and reading a visitor's run and answers.

## How to use it

- To get easy_flow running in an app, or to change how it is configured, use **easy_flow-install**.
- To add a step type, put a flow on the app's own pages, or act on what a visitor answered, use **easy_flow-develop**.
- If the question is only what a word below means, this page is the answer.

## Conventions

- **Flow** — one guided path, found by its slug. It holds a working document the admin edits and a list of versions.
- **Document** — the flow's content: its steps (nodes), the connections between them (edges), a headline and a slug.
- **Version** — a numbered snapshot of the document. A version is a draft until it is published, and a flow has at most one live version at a time.
- **Canvas** — the admin screen where steps are added, configured, moved, removed and connected, with undo and redo. Publishing happens there.
- **Preview** — an admin walking the current flow without starting a stored run.
- **Step type** — what a kind of step is: its display name, its settings (the fields an admin fills in), its outputs (the values it records), and whether it waits for the visitor or acts on its own. A step that acts on its own processes the answers so far and records a result, and a step type may also decide its own routing.
- **Question** — the built-in step type: a question text and a list of answers, each with a value, a label and a weight.
- **Registry** — the list of step types the app has registered. A step whose type is not registered is not shown or run as that type.
- **Host** — a named part of the app that owns a set of flows. A host sets the visitor layout and the admin layout, how admins are authenticated, how visitors are authorized, and how a refusal is answered. Flows are always looked up through a host, so one host never sees another's flows.
- **Run** — one visitor's pass through a flow. A run is pinned to the version that was live when it started, so publishing a new version does not change a run already under way. It records each answer by step id, and going back discards the last answer on the path.
- **Answers** — the recorded state of a run, keyed by step id. The next step is always worked out from these answers and the connections in the pinned version.
- **Checks** — optional warnings on a flow's shape an app can turn on: an answer value no connection routes, a path nothing follows, and a step that leads nowhere.
