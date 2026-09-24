import { test } from "node:test"
import assert from "node:assert/strict"
import { createFlowSender } from "../../app/javascript/easy_flow/canvas/flowSender.js"

test("a flow change that cannot reach the server says it was not saved", async () => {
  const errors = []
  const unreachable = async () => { throw new TypeError("Failed to fetch") }
  const send = createFlowSender({ base: "/flows/1/canvas", token: "t", fetch: unreachable, onFlow: () => {}, onNotice: () => {}, onError: (error) => errors.push(error) })

  await send("/steps", "POST", {}).catch(() => {})

  assert.deepEqual(errors, [ "Your change was not saved because the server could not be reached." ])
})
