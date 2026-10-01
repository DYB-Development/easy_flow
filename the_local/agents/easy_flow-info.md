---
name: easy_flow-info
description: Use to learn what easy_flow offers — guided flows an admin draws on a canvas and a visitor runs one step at a time, versioned documents of steps and connections, flows that loop back to ask a step again, hosts and the step types each offers its admins, runs, the built-in step types including questions and checklists that can require an answer and explain each answer behind an info button, and branching on an answer or comparing a number, step types the host app registers, the checks they make on an answer, what a step shows a visitor and how that can depend on the visitor's run, and steps that hold a run until something outside the flow has happened, and the settings an admin fills in, including picks whose options come from the app's data.
tools: Read
scope: guided flows — versioned documents of steps and the connections between them, drawn on a canvas by an admin and run by a visitor one step at a time, with step types the host registers
---

This local explains easy_flow and the words it uses. It makes no changes and gives no steps.

## What easy_flow is

easy_flow is a Rails engine for guided, branching flows. An admin builds a flow on a canvas by placing steps and connecting them, previews it, and publishes it. A visitor then walks the published flow one step at a time, and each answer decides which step comes next.

Reach for it when an app needs a questionnaire, an intake form, or any decision path that an admin should be able to change without a deploy. The engine ships a start step, an end step, a question step, a checklist step, and three steps that pick a branch from earlier answers. Anything else a flow needs to ask, do, or wait for is a step type the app declares itself.

## Interface

easy_flow declares no commands of its own for this local. Its surface is split between the other two:

- **easy_flow-install** owns putting the engine into an app: its migrations, mounting it, choosing the controller it inherits from, naming hosts and the step types each one offers, choosing the default step drawing, the flow checks, and the admin pages.
- **easy_flow-develop** owns building on it: declaring and registering step types, including ones that wait, moving a run on once what it waits for has happened, serving a host's flows from the app's own controllers and routes, and reading a visitor's run and answers.

## How to use it

- To get easy_flow running in an app, or to change how it is configured, including which step types a host's admins can add, use **easy_flow-install**.
- To add a step type, give a step type its own rule for refusing an answer, make what a step shows depend on the visitor's run, hold a run until something outside the flow has happened, put a flow on the app's own pages, or act on what a visitor answered, use **easy_flow-develop**.
- To branch a flow on an answer or on a number the visitor gave, no code is needed: an admin places one of the built-in branching steps on the canvas.
- To make a visitor answer a question or tick something on a checklist before going on, no code is needed: an admin marks that step as required on the canvas.
- To let a visitor tick several answers on one step, no code is needed: an admin places a checklist step on the canvas.
- To explain an answer to the visitor, no code is needed: an admin fills in that answer's info on a question or checklist step.
- To ask a step again, such as repeating a question until the visitor says they are done, no code is needed: an admin connects a later step back to an earlier one on the canvas.
- If the question is only what a word below means, this page is the answer.

## Conventions

- **Flow** — one guided path, found by its slug within its host. It holds a working document the admin edits and a list of versions.
- **Document** — the flow's content: its steps (nodes), the connections between them (edges), a headline and a slug.
- **Version** — a numbered snapshot of the document. A version is a draft until it is published, and a flow has at most one live version at a time.
- **Canvas** — the admin screen where steps are added, configured, moved, removed and connected, with undo and redo. Publishing happens there.
- **Preview** — an admin walking the current flow without starting a stored run.
- **Step type** — what a kind of step is: its display name, its settings (the fields an admin fills in), its outputs (the values it records), and whether it waits for the visitor, acts on its own, or waits for something outside the flow. A step that acts on its own may record a value worked out from the answers so far, pick which connection to follow, or both.
- **Display** — what a step type hands the visitor's page to draw a step, such as its question text and its answers. A step type may build its display from the step alone, or from the step and the visitor's stored run, so the same step can show something different to each visitor. There is no stored run in an admin's preview or in a flow that carries its answers in the page, and the display is then built without one.
- **Answer check** — a rule a step type may carry that looks at a visitor's answer and, when the answer is not acceptable, returns the message the visitor sees. A step type with no such rule accepts every answer.
- **Setting** — one field an admin fills in when configuring a step on the canvas. It is text, a whole number, a decimal, a yes or no, a pick from a list, several picks from a list, an earlier step, an earlier step's output, or a list of entries that each hold their own fields. A setting can be required, limited to a number of picks, or checked by a rule the step type supplies.
- **Options** — the values a pick-from-a-list setting offers. They are either a fixed list written into the step type, or a lookup the app provides that is read each time the canvas or a save asks for them, so they can come from the app's own data. A saved value that is not among the options is refused.
- **Output** — a value a step records into the run, with a type and a label. Later steps read outputs, and a setting that points at an earlier step offers that step's known values on the canvas.
- **Start** and **End** — the built-in step types that begin and finish a flow.
- **Question** — the built-in step type that asks the visitor: a question text, an optional category, a yes-or-no required setting, and a list of answers, each with a value, a label, a weight, a hint and an info. The visitor picks one answer, and that answer's value is recorded.
- **Checklist** — the built-in step type that asks the visitor to tick any number of answers: a question text, a yes-or-no required setting, and a list of answers, each with a value, a label and an info. The list of ticked values is recorded, and a checklist left with nothing ticked records an empty list.
- **Hint** — a short line of text shown under an answer's label on a question step.
- **Info** — a longer explanation of one answer on a question or checklist step. The visitor opens it with an info button beside that answer, and an answer with no info has no button.
- **Read-back** — the list a visitor sees when a flow finishes: each question or checklist asked, beside the label of the answer given. A checklist's ticked answers are read back as their labels joined into one phrase, such as "Email, Phone and Post", and an answer with no label is read back as its value.
- **Required question** — a question step the admin has marked required. A blank answer to it is refused with the message "Fill this in to go on."
- **Required checklist** — a checklist step the admin has marked required. Submitting it with nothing ticked is refused with the message "Tick at least one to go on."
- **Condition** — a built-in branching step that checks whether an earlier step's answer is, or is not, a chosen value, and follows the true or the false connection.
- **Switch** — a built-in branching step that follows the connection labelled with an earlier step's answer.
- **Compare** — a built-in branching step that reads an earlier step's answer as a number and checks it against an amount by more than, less than, at least or at most, then follows the true or the false connection. When the earlier step recorded several outputs, the admin picks which one. An answer that is missing or is not a number decides false.
- **Waiting step** — a step whose type carries a rule saying whether what it waits for has happened, such as a payment clearing or a document being signed. A run that reaches it stops there, and the visitor sees "Waiting for" followed by the step's name, with no form to submit. Once the rule says it has happened, the run moves past the step the next time the visitor's page is loaded or the app moves the run on, and the step is recorded as `true`.
- **Registry** — the list of step types the app has registered, alongside the built-in ones. A step whose type is not registered is not shown or run as that type, and its answers are not checked.
- **Host** — a named part of the app that owns a set of flows. A host sets the visitor layout and the admin layout, how admins are authenticated, how visitors are authorized, how a refusal is answered, and optionally which step types it offers. Flows are always looked up through a host, so one host never sees another's flows.
- **Offered step types** — the list of step types a host names for its admins to add. A host that names no list offers every registered step type. The list only narrows the palette.
- **Palette** — the step types an admin can add on a host's canvas. It never holds the start step, always holds the end step, and otherwise holds the step types the host offers. A step already in a flow whose type the host does not offer is still drawn and run.
- **Run** — one visitor's pass through a flow. A run is pinned to the version that was live when it started, so publishing a new version does not change a run already under way. It records each answer by visit, and going back discards the last answer on the path.
- **Stored run** and **carried answers** — the two ways a visitor's progress is held. A stored run is saved by the app and found again by its id. A flow that keeps nothing carries the answers given so far in the page itself and sends them along with each step.
- **Answers** — the recorded state of a run, keyed by visit. The next step is always worked out from these answers and the connections in the pinned version.
- **Loop** — a connection that leads back to a step the run has already passed, so that step is visited again. Branching steps read the most recent answer to a step, so a loop ends when an answer sends the run down a different connection.
- **Visit** — one time a run reaches a step. The first visit is keyed by the step id alone, and each later visit is keyed by the step id, an `@`, and the visit number, such as `size@2`. Every visit's answer is kept, and a finished run lists each one.
- **Stopped loop** — a run that comes back to a step with no new answer given since its last visit there ends at that point rather than cycling forever. Only answers the visitor gives count, so a loop made only of steps that act on their own stops the first time it comes round.
- **Reserved `@`** — a step id may not contain `@`, since that mark numbers later visits. A flow holding such a step id is reported as invalid.
- **Refused answer** — an answer the step's answer check turned down. Nothing is recorded for that step, and the visitor is shown the same step again with the check's message. This works the same whether the flow keeps a stored run or carries its answers in the page.
- **Blank answer** — a step the visitor leaves blank. On a step whose answer check does not refuse it, such as a question or checklist that is not required, the blank is recorded and the visitor moves on to the next step. This works the same whether the flow keeps a stored run or carries its answers in the page, and every value ticked on a checklist is carried either way.
- **Checks** — warnings on a flow's shape: an answer value no connection routes, a path nothing follows, and a step that leads nowhere. The engine turns all three on by default. These are separate from answer checks, which look at what a visitor submits.
