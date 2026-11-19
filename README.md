# easy_flow
Guided, versioned, branching flows for Rails apps

## For each

A For each step (`:for_each`) is drawn on the canvas as a dashed box. It runs the steps inside the box once for each item of a list an earlier step recorded, one item after another, in list order. It runs only in a flow that saves its runs, and a flow that keeps nothing tells the visitor so.

Its settings:

- `list` names the list as `<step>.<output>`, such as `outline.variants`, or as the step id alone when that step recorded the array as its whole value.
- `concurrency` is how many items may run at the same time. Items still run one at a time.
- `on_item_failure` is `continue` or `stop`. A failed item still lets the next item start.

Each visit of a held step is recorded under its item number, counting from 1, such as `write@item2`, and a further visit inside the same item adds the visit number, such as `write@item2@2`. A held step's input can tick `The current item` to receive that item's value from the list. An input naming another held step receives that step's output for the same item. An item ends when its steps leave the box, or when a held step routes to `failed`.

Once every item has ended, the For each step records these outputs under its own id:

- `result` is `passed` when no item failed, and `failed` otherwise.
- `items` holds one entry per item, mapping each held step the item reached to its latest value.
- `passed` and `failed` count the items.

A step after the box reads them through an input that names the For each step and one of those outputs. An empty list runs no items, records `items` as an empty list, and the run goes on to the step after the box.
