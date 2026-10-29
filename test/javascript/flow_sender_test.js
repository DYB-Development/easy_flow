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
