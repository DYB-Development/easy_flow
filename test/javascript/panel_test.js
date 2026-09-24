import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Panel from "../../app/javascript/easy_flow/canvas/Panel.jsx"

const shown = (tree, marker) => {
  const found = []
  const walk = (node) => {
    if (!node || typeof node !== "object") return
    if (Array.isArray(node)) return node.forEach(walk)
    if (node.props?.[marker] !== undefined) found.push(node)
    walk(node.props?.children)
  }
  walk(tree)
  return found
}

const panel = (given) => Panel({
  flow: { title: "A flow", version: 1, published: 1 },
  changes: [], problems: [], refusal: null, notice: null, ...given
})

test("says nothing has changed when the flow is untouched", () => {
  assert.equal(shown(panel({}), "data-change").length, 0)
})

test("lists a line for each change", () => {
  const tree = panel({ changes: [ "Added “A”", "Moved “B”" ] })

  assert.equal(shown(tree, "data-change").length, 2)
})

test("names each problem it was given", () => {
  const tree = panel({ problems: [ { node: "a", problem: "unreachable" } ] })

  assert.equal(shown(tree, "data-problem").length, 1)
})

test("shows a notice when something was done", () => {
  assert.equal(shown(panel({ notice: "Created version 2." }), "data-notice").length, 1)
})

test("shows a refusal instead of a notice when both arrive", () => {
  const tree = panel({ notice: "Created version 2.", refusal: "Cannot publish." })

  assert.equal(shown(tree, "data-notice").length, 0)
  assert.equal(shown(tree, "data-refusal").length, 1)
})

test("offers the way to the flow's history", () => {
  assert.equal(shown(panel({}), "data-history").length, 1)
})

test("offers the way to the definition and the details", () => {
  const tree = panel({})

  assert.equal(shown(tree, "data-definition").length, 1)
  assert.equal(shown(tree, "data-details").length, 1)
})

test("names a flow that has no title by its slug", () => {
  const tree = panel({ flow: { title: null, slug: "a-flow", version: 1, published: 1 } })

  assert.equal(shown(tree, "data-flow-name")[0].props.children, "a-flow")
})

test("offers the flow's title for editing", () => {
  assert.equal(shown(panel({}), "data-flow-title").length, 1)
})

test("offers the flow's start label for editing", () => {
  assert.equal(shown(panel({}), "data-flow-start-label").length, 1)
})

test("saves a field that was changed when it is left", () => {
  const saved = []
  const tree = panel({ flow: { title: "A flow", slug: "a-flow" }, onSaveDetails: (given) => saved.push(given) })

  shown(tree, "data-flow-title")[0].props.onBlur({ target: { value: "A better name" } })

  assert.deepEqual(saved, [ { title: "A better name" } ])
})

test("saves nothing when a field is left as it was stored", () => {
  const saved = []
  const tree = panel({ flow: { title: "A flow", slug: "a-flow" }, onSaveDetails: (given) => saved.push(given) })

  shown(tree, "data-flow-title")[0].props.onBlur({ target: { value: "A flow" } })

  assert.deepEqual(saved, [])
})

const classesOn = (tree, marker) => (renderToStaticMarkup(tree).match(new RegExp(`<[^<>]*${marker}[^<>]*`))?.[0].match(/class="([^"]*)"/)?.[1] || "").split(" ")

const labelled = (tree, text) => new RegExp(`class="ks-label"[^>]*>(<span[^>]*>)?${text}<`).test(renderToStaticMarkup(tree))

test("is drawn as a keystone panel", () => {
  assert.ok(classesOn(panel({}), "data-builder-panel").includes("ks-panel"))
})

test("colors the history link with the accent color", () => {
  assert.ok(classesOn(panel({}), "data-history").includes("text-accent-600"))
})

const withText = (tree, text) => {
  const found = []
  const walk = (node) => {
    if (!node || typeof node !== "object") return
    if (Array.isArray(node)) return node.forEach(walk)
    if (node.props?.children === text) found.push(node)
    walk(node.props?.children)
  }
  walk(tree)
  return found[0]
}

test("says a flow with no problems is fine in keystone's muted text color", () => {
  assert.ok(withText(panel({}), "Nothing wrong with this flow.").props.className?.split(" ").includes("text-gray-500"))
})

test("says nothing has changed in keystone's muted text color", () => {
  assert.ok(withText(panel({}), "Nothing has changed.").props.className?.split(" ").includes("text-gray-500"))
})

test("colors a refusal red", () => {
  assert.ok(classesOn(panel({ refusal: "Cannot publish." }), "data-refusal").includes("text-red-800"))
})

test("colors a notice green", () => {
  assert.ok(classesOn(panel({ notice: "Created version 2." }), "data-notice").includes("text-emerald-800"))
})

test("colors a problem amber", () => {
  const tree = panel({ problems: [ { node: "a", problem: "unreachable" } ] })

  assert.ok(classesOn(tree, "data-problem").includes("text-amber-700"))
})

test("labels the title field with keystone's label", () => {
  assert.ok(labelled(panel({}), "Title"))
})

test("labels the start label field with keystone's label", () => {
  assert.ok(labelled(panel({}), "Start label"))
})

test("draws the title field as a keystone input", () => {
  assert.ok(classesOn(panel({}), "data-flow-title").includes("ks-input"))
})

test("draws the start label field as a keystone input", () => {
  assert.ok(classesOn(panel({}), "data-flow-start-label").includes("ks-input"))
})

test("offers publishing as keystone's primary button", () => {
  assert.ok(classesOn(panel({}), "data-publish").includes("ks-button-primary"))
})

test("offers creating a version as keystone's secondary button", () => {
  assert.ok(classesOn(panel({}), "data-create-version").includes("ks-button-secondary"))
})

test("links to the definition as keystone's secondary button", () => {
  assert.ok(classesOn(panel({}), "data-definition").includes("ks-button-secondary"))
})

test("links to editing the details as keystone's secondary button", () => {
  assert.ok(classesOn(panel({}), "data-details").includes("ks-button-secondary"))
})

test("colors the close button with keystone's muted text color", () => {
  assert.ok(withText(panel({}), "×").props.className?.split(" ").includes("text-gray-500"))
})
