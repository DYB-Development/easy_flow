import { test } from "node:test"
import assert from "node:assert/strict"
import { layOut } from "../../app/javascript/easy_flow/canvas/graph.js"

const step = (id, given = {}) => ({ id, label: id, ...given })
const link = (source, target, label) => ({ id: `${source}-${target}`, source, target, label })

const columnOf = (graph, id) => graph.places[id].column

test("puts a step one column to the right of the step that leads into it", () => {
  const graph = layOut([ step("ask"), step("gate") ], [ link("ask", "gate") ])

  assert.equal(columnOf(graph, "gate"), columnOf(graph, "ask") + 1)
})

test("puts a step a connection loops back to to the left of the step it loops back from", () => {
  const graph = layOut([ step("start"), step("write"), step("check"), step("retry") ],
                       [ link("start", "write"), link("write", "check"), link("check", "retry"), link("retry", "write") ])

  assert.deepEqual([ "start", "write", "check", "retry" ].map((id) => columnOf(graph, id)), [ 0, 1, 2, 3 ])
})

const rowOf = (graph, id) => graph.places[id].row

test("fans the branches of a step out into separate rows", () => {
  const graph = layOut([ step("gate"), step("yes"), step("no") ], [ link("gate", "yes", "true"), link("gate", "no", "false") ])

  assert.notEqual(rowOf(graph, "yes"), rowOf(graph, "no"))
})

test("puts a step in a lower row below the tallest card in the row above it", () => {
  const nodes = [ step("start"), step("gate"), step("yes"), step("no") ]
  const graph = layOut(nodes, [ link("start", "gate"), link("gate", "yes", "true"), link("gate", "no", "false") ], { heights: { start: 140 } })
  const above = graph.places.yes.row < graph.places.no.row ? "yes" : "no"
  const below = above === "yes" ? "no" : "yes"

  assert.ok(graph.places[below].y >= graph.places.start.y + 140)
})

const routeOf = (graph, id) => graph.links.find((each) => each.id === id).points

test("draws a connection as a line from the right edge of one card to the left edge of the next", () => {
  const graph = layOut([ step("ask"), step("gate") ], [ link("ask", "gate") ])
  const points = routeOf(graph, "ask-gate")
  const { ask, gate } = graph.places

  assert.deepEqual([ points[0][0], points.at(-1)[0] ], [ ask.x + ask.width, gate.x ])
})

const pipeline = {
  nodes: [ "start", "brief", "gate", "write", "review", "retries", "publish", "end", "rejected", "failed" ].map((id) => step(id)),
  edges: [ link("start", "brief"), link("brief", "gate"), link("brief", "failed", "failed"),
           link("gate", "write", "true"), link("gate", "rejected", "false"),
           link("write", "review"), link("review", "publish", "approved"), link("review", "write", "changes"), link("review", "retries", "failed"),
           link("retries", "write", "again"), link("retries", "failed", "give_up"), link("publish", "end") ]
}

const crossing = ([ [ x1, y1 ], [ x2, y2 ] ], card) => {
  const [ left, right, top, bottom ] = [ Math.min(x1, x2), Math.max(x1, x2), Math.min(y1, y2), Math.max(y1, y2) ]
  return left < card.x + card.width && right > card.x && top < card.y + card.height && bottom > card.y &&
    (left !== right || (left > card.x && left < card.x + card.width)) && (top !== bottom || (top > card.y && top < card.y + card.height))
}

test("routes no line through a card, including lines that loop back or skip columns", () => {
  const graph = layOut(pipeline.nodes, pipeline.edges)
  const crossed = graph.links.flatMap((each) => each.points.slice(1).flatMap((point, at) =>
    Object.entries(graph.places).filter(([ , card ]) => crossing([ each.points[at], point ], card)).map(([ id ]) => `${each.id} crosses ${id}`)))

  assert.deepEqual(crossed, [])
})

test("measures the graph past its rightmost card and below its lowest line", () => {
  const graph = layOut(pipeline.nodes, pipeline.edges)
  const lines = graph.links.flatMap((each) => each.points)
  const cards = Object.values(graph.places)

  assert.deepEqual([ graph.width > Math.max(...cards.map((card) => card.x + card.width)), graph.height > Math.max(...lines.map(([ , y ]) => y)) ], [ true, true ])
})

test("leaves out a connection to or from a step that is not drawn", () => {
  const graph = layOut([ step("ask"), step("gate") ], [ link("start", "ask"), link("ask", "gate"), link("gate", "end") ])

  assert.deepEqual(graph.links.map((each) => each.id), [ "ask-gate" ])
})

test("measures a flow with no steps to draw as an empty graph", () => {
  const graph = layOut([], [])

  assert.ok(Number.isFinite(graph.width) && Number.isFinite(graph.height))
})

const grouped = {
  nodes: [ step("outline"), step("variants", { holds: [ "write", "check" ] }), step("write"), step("check"), step("approve") ],
  edges: [ link("outline", "variants"), link("variants", "write"), link("write", "check"), link("check", "approve") ]
}

const within = (card, box) =>
  card.x >= box.x && card.x + card.width <= box.x + box.width && card.y >= box.y && card.y + card.height <= box.y + box.height

test("draws the steps a group step holds inside the group's box", () => {
  const graph = layOut(grouped.nodes, grouped.edges)

  assert.deepEqual([ "write", "check" ].map((id) => within(graph.places[id], graph.places.variants)), [ true, true ])
})

test("enters a group's box from the step before it and leaves the box for the step after it", () => {
  const graph = layOut(grouped.nodes, grouped.edges)
  const box = graph.places.variants

  assert.deepEqual([ routeOf(graph, "outline-variants").at(-1)[0], routeOf(graph, "check-approve")[0][0] ], [ box.x, box.x + box.width ])
})

const counted = (count, shape) => {
  const reads = { count: 0 }
  const watched = (value) => new Proxy(value, { get: (target, key) => { reads.count += 1; return target[key] } })
  const { nodes, edges } = shape(count)

  layOut(nodes.map(watched), edges.map(watched))
  return reads.count / count
}

const chain = (count) => {
  const nodes = Array.from({ length: count }, (_, at) => step(`s${at}`))
  return { nodes, edges: nodes.slice(1).map((each, at) => link(`s${at}`, each.id)) }
}

const failingToOneEnd = (count) => {
  const { nodes, edges } = chain(count)
  return { nodes: [ ...nodes, step("failed") ], edges: [ ...edges, ...nodes.map((each) => link(each.id, "failed", "failed")), link(`s${count - 1}`, "s0", "again") ] }
}

test("reads each step about as often in a flow of 400 steps as in a flow of 100 when laying out a chain", () => {
  assert.ok(counted(400, chain) < 2 * counted(100, chain))
})
