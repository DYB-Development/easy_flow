import { test } from "node:test"
import assert from "node:assert/strict"
import { createFlowSender, createPictureSender } from "../../app/javascript/easy_flow/canvas/flowSender.js"

test("a flow change that cannot reach the server says it was not saved", async () => {
  const errors = []
  const unreachable = async () => { throw new TypeError("Failed to fetch") }
  const send = createFlowSender({ base: "/flows/1/canvas", token: "t", fetch: unreachable, onFlow: () => {}, onNotice: () => {}, onError: (error) => errors.push(error) })

  await send("/steps", "POST", {}).catch(() => {})

  assert.deepEqual(errors, [ "Your change was not saved because the server could not be reached." ])
})

test("a chosen picture is sent to the flow's pictures and its kept reference and address come back", async () => {
  const sent = []
  const answering = async (url, options) => { sent.push([ url, options.method, options.body.get("picture") ]); return { ok: true, json: async () => ({ reference: "picture-1", url: "/pictures/picture-1" }) } }
  const pick = createPictureSender({ base: "/flows/1/canvas", token: "t", fetch: answering, onError: () => {} })

  const kept = await pick("the file")

  assert.deepEqual([ sent, kept ], [ [ [ "/flows/1/canvas/pictures", "POST", "the file" ] ], { reference: "picture-1", url: "/pictures/picture-1" } ])
})

test("a refused picture shows the author why and keeps nothing", async () => {
  const errors = []
  const refusing = async () => ({ ok: false, json: async () => ({ error: "Pictures cannot be added yet." }) })
  const pick = createPictureSender({ base: "/flows/1/canvas", token: "t", fetch: refusing, onError: (error) => errors.push(error) })

  const kept = await pick("the file")

  assert.deepEqual([ errors, kept ], [ [ "Pictures cannot be added yet." ], null ])
})

const answering = (first, flow = { nodes: [] }) => {
  const answers = [ first, { ok: true, json: async () => flow } ]
  return async () => answers.shift()
}

test("a warning about unconnected steps carries the steps and where to send the acceptance", async () => {
  const warnings = []
  const warned = { ok: false, json: async () => ({ error: "Cannot publish.", unconnected: [ { id: "aside", label: "Aside" } ] }) }
  const send = createFlowSender({ base: "/flows/1/canvas", token: "t", fetch: answering(warned), onFlow: () => {}, onNotice: () => {}, onError: () => {}, onWarning: (warning) => warnings.push(warning) })

  await send("/publish", "POST")

  assert.deepEqual(warnings, [ { path: "/publish", steps: [ { id: "aside", label: "Aside" } ] } ])
})

test("a warning about unconnected steps draws the flow again so the canvas matches it", async () => {
  const drawn = []
  const warned = { ok: false, json: async () => ({ unconnected: [ { id: "aside", label: "Aside" } ] }) }
  const send = createFlowSender({ base: "/flows/1/canvas", token: "t", fetch: answering(warned, { nodes: [ "fresh" ] }), onFlow: (flow) => drawn.push(flow), onNotice: () => {}, onError: () => {} })

  await send("/publish", "POST")

  assert.deepEqual(drawn, [ { nodes: [ "fresh" ] } ])
})

test("any other answer clears the warning", async () => {
  const warnings = []
  const refused = { ok: false, json: async () => ({ error: "Cannot publish." }) }
  const send = createFlowSender({ base: "/flows/1/canvas", token: "t", fetch: answering(refused), onFlow: () => {}, onNotice: () => {}, onError: () => {}, onWarning: (warning) => warnings.push(warning) })

  await send("/publish", "POST", { remove_unconnected: [ "aside" ] })

  assert.deepEqual(warnings, [ null ])
})
