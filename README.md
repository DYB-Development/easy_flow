# easy_flow
Guided, versioned, branching flows for Rails apps

## For each

A For each step (`:for_each`) is drawn on the canvas as a dashed box. It runs the steps inside the box once for each item of a list an earlier step recorded, starting items in list order. It runs only in a flow that saves its runs, and a flow that keeps nothing tells the visitor so.

Its settings:

- `list` names the list as `<step>.<output>`, such as `outline.variants`, or as the step id alone when that step recorded the array as its whole value.
- `concurrency` is how many items may be unfinished at the same time. With none set, items run one at a time.
- `on_item_failure` is `continue` or `stop`. Under `continue`, a failed item ends only that item. Under `stop`, no item starts after an item has failed, and the items already running are allowed to end.
- `item_limit` is the most items the list may hold. With none set, the limit is 100.

Each visit of a held step is recorded under its item number, counting from 1, such as `write@item2`, and a further visit inside the same item adds the visit number, such as `write@item2@2`. A held step's input can tick `The current item` to receive that item's value from the list. An input naming another held step receives that step's output for the same item. An item ends when its steps leave the box, or when a held step routes to `failed`. An item counts as running once one of its held steps has a recorded visit.

### Steps ready now

`run.next_step(run.recorded)` names one step, as it always has. `run.ready_steps` names every step that may run now. Outside a For each step it holds the next step alone. Inside one it holds the next held step of each unfinished item, never more than `concurrency` of them, in list order.

```ruby
run.ready_steps.map(&:id)
# => ["write@item1", "write@item2", "write@item3"]
run.record("write@item2", { "result" => "passed" })
run.advance
run.ready_steps.map(&:id)
# => ["write@item1", "write@item3", "write@item4"]
```

`run.advance` runs every acting step among the ready steps, not only the first.

### What it records

Once every item has ended, the For each step records these outputs under its own id:

- `result` is `passed` when no item failed, and `failed` otherwise.
- `items` holds one entry per item that ran, mapping each held step the item reached to its latest value.
- `passed` and `failed` count the items.
- `reason` says why the step failed when its list could not be run.

A step after the box reads them through an input that names the For each step and one of those outputs. An empty list runs no items, records `items` as an empty list, and the run goes on to the step after the box.

The run leaves the box on the connection that leaves it from a held step. Under `stop`, once an item has failed and the running items have ended, the run leaves on the `failed` connection of the held step that failed.

### A list that cannot be run

The step starts no item and records `result` as `failed` with a `reason` when:

- the earlier step recorded no value under the named output, such as `The step outline recorded no value under variants.`
- the value is not a list, such as `The list outline.variants is text, not a list.`, naming text, a number or a hash.
- the list holds more items than `item_limit`, such as `The list outline.variants holds 120 items, more than the limit of 100.`

The run then leaves on a `failed` connection that leaves the box from a held step. With none, the run stops there, as it does after any failed step with no `failed` connection.

### Reaching it again

A run that comes back to a For each step, through a later step that loops back to it or to a step before it, runs the held steps again for each item of the list as it stands then. The second pass records its visits with a pass number after the item, such as `write@item2@pass2` and `write@item2@pass2@2`, and the third pass with `pass3`. The first pass's keys carry no pass number. The For each step records each pass's outputs under its own visit, `variants` for the first and `variants@2` for the second, so both stay readable, and a step after the box reads the latest pass. A held step's input naming another held step reads that step's output for the same item in the same pass.
