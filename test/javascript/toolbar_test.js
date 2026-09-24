import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Toolbar from "../../app/javascript/easy_flow/canvas/Toolbar.jsx"

const drawn = () => renderToStaticMarkup(React.createElement(Toolbar, {
  undoable: true, redoable: true, onAdd: () => {}, onUndo: () => {}, onRedo: () => {}
}))

const classesWith = (html, attribute) => (html.match(new RegExp(`<[^<>]*${attribute}[^<>]*`))?.[0].match(/class="([^"]*)"/)?.[1] || "").split(" ")

test("draws adding a step as a round keystone button", () => {
  const classes = classesWith(drawn(), 'title="Add a step"')

  assert.ok(classes.includes("ks-button-secondary") && classes.includes("rounded-full"))
})

test("offers undo as keystone's secondary button", () => {
  assert.ok(classesWith(drawn(), 'title="Undo the last change"').includes("ks-button-secondary"))
})
