import { createRoot } from "react-dom/client"
import { register } from "keystone_ui-react/src/registry.js"
import { startMounting } from "keystone_ui-react/src/mounting.js"
import Canvas from "./canvas/Canvas"
import RunView from "./canvas/RunView"

register("easy_flow/flow-editor", Canvas)
register("easy_flow/run-view", RunView)

document.addEventListener("easy_flow:flow-named", (event) => {
  const heading = document.querySelector("[data-flow-heading]")
  if (heading) heading.textContent = event.detail
})

startMounting(document, createRoot)
