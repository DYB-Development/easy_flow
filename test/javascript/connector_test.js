import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Connector from "../../app/javascript/easy_flow/canvas/Connector.jsx"

const drawn = (props) => renderToStaticMarkup(React.createElement(Connector, {
  link: { source: "a", target: "b", midX: 100, midY: 100 }, dragging: false,
  onInsert: () => {}, onRemove: () => {}, onDrop: () => {}, ...props
}))

const classesWith = (html, attribute) => (html.match(new RegExp(`<[^<>]*${attribute}[^<>]*`))?.[0].match(/class="([^"]*)"/)?.[1] || "").split(" ")

test("offers inserting a step as a round keystone button", () => {
  assert.ok(classesWith(drawn(), 'title="Insert a step here"').includes("rounded-full"))
})

test("rings the insert button in the accent color while a step is dragged over it", () => {
  assert.ok(classesWith(drawn(), 'title="Insert a step here"').includes("data-[over=true]:ring-accent-600"))
})

test("offers removing the connection as a round keystone danger button", () => {
  assert.ok(classesWith(drawn(), 'title="Remove this connection"').includes("ks-button-danger"))
})

test("hides the insert button until the pointer is over the connection when the host has not asked otherwise", () => {
  assert.match(drawn(), /title="Insert a step here"[^>]*opacity:0/)
})

test("keeps the remove button hidden until the pointer is over the connection", () => {
  assert.match(drawn(), /title="Remove this connection"[^>]*opacity:0/)
})

test("shows the insert button without the pointer over the connection when the host asks for it", () => {
  assert.doesNotMatch(drawn({ alwaysShowInsertButtons: true }), /title="Insert a step here"[^>]*opacity:0/)
})
