# Changelog

## [Unreleased]

### Fixed

- A Flow step whose inner flow ends on an End step with no output records "ended" and its parent run moves on, and the canvas offers an "ended" connection out of that Flow step.
- Counting the questions left in a run finishes on a flow that loops back to an earlier step, and counts each question ahead once.

## [0.27.0] - 2026-10-20

### Added

- A visitor whose stored run reaches a Flow step is taken to the first unanswered step of the inner run it started, and a visitor who opens the parent run's address while that inner run is unfinished is taken there too.
- A visitor who finishes an inner run is taken back to the parent run, which moves on without waiting for its background job and shows its next step.
- A controller that subclasses the visitor pages takes visitors into and out of inner runs at its own run addresses.

### Fixed

- A branching step reads only the answers recorded before it on the run's path, so a Condition that checks whether a Flow step further along has ended sees it as unplayed until the run has passed it.

## [0.26.0] - 2026-10-20

### Added

- A Multiple select step (`multiple_select`) asks a question whose answers each carry a value, a label and a weight, lets the visitor tick several, and records every value ticked.
- A Fill in the blank step (`fill_in_the_blank`) asks a question the visitor answers by typing, records the text as typed, and keeps its list of accepted answers off the visitor's page.
- An admin can set a category on either step and mark either one required, and a required one refuses an empty answer with a message saying why.

## [0.25.0] - 2026-10-20

### Added

- A host can set `finds_flows_across_owners = true` so its visitor pages find a flow by its public code and a run by its public code among every owner's flows in that host. The visitor pages then link to a flow at its public code instead of its slug.
- A host that leaves the setting off finds flows on its visitor pages by slug among the current owner's flows exactly as before, and the admin pages list, open and preview only the current owner's flows whether the setting is on or off.

## [0.24.0] - 2026-10-12

### Added

- Flows and flow versions take a random code from the public_code gem. In an app that has run the `AddPublicCodeToEasyFlowDefinitions` and `AddPublicCodeToEasyFlowVersions` migrations, every flow management address carries the flow's code, returning to an earlier version is addressed by that version's code, and a numbered flow address is not found.
- An app that has not run those migrations keeps addressing and finding flows and versions by id exactly as before.

### Upgrading

To switch an app's flows and versions to codes, copy and run the new migrations, then restart the app:

```
bin/rails easy_flow:install:migrations
bin/rails db:migrate
```

A host that finds an easy_flow flow by its address, such as alembic, has to move to a release that finds it by code at the same time.

## [0.23.0] - 2026-10-12

### Added

- Flow runs take a random code from the public_code gem. In an app that has run the `AddPublicCodeToEasyFlowRuns` migration, every run address carries the run's code, runs are found by it, and a numbered run address is not found.
- An app that has not run that migration keeps addressing and finding runs by id exactly as before.

### Upgrading

To switch an app's runs to codes, copy and run the new migration, then restart the app:

```
bin/rails easy_flow:install:migrations
bin/rails db:migrate
```

A host that overrides `run_address` and `find_run` keeps the addresses it builds.
