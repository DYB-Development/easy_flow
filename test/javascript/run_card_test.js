import { test } from "node:test"
import assert from "node:assert/strict"
import React from "react"
import { renderToStaticMarkup } from "react-dom/server"
import RunCard from "../../app/javascript/easy_flow/canvas/RunCard.jsx"

const step = { id: "outline", type: "agent", label: "outline", version: "v9", state: "done", status: "8.2s · $0.04" }

const drawn = (node = {}, given = {}) => renderToStaticMarkup(React.createElement(RunCard, { node: { ...step, ...node }, ...given }))

const text = (markup) => markup.replace(/<[^>]+>/g, "|").split("|").filter(Boolean)

test("writes the step's type code, name, version and status line in that order", () => {
  assert.deepEqual(text(drawn()), [ "agent", "outline", "v9", "8.2s · $0.04" ])
})

const card = (node = {}, given = {}) => RunCard({ node: { ...step, ...node }, ...given })

const classes = (element) => (element.props.className || "").split(" ")

const borderOf = (state) => classes(card({ state })).find((name) => /^border-(gray|green|amber|red)-\d+$/.test(name))

test("borders each card in the colour of its step's state", () => {
  assert.deepEqual([ "done", "paused", "pending", "failed" ].map(borderOf), [ "border-green-600", "border-amber-500", "border-gray-300", "border-red-600" ])
})

test("draws a paused step's edge thicker than the other steps' edges", () => {
  assert.deepEqual([ "done", "paused", "pending", "failed" ].map((state) => classes(card({ state })).includes("border-2")), [ false, true, false, false ])
})

test("links the card to the address its host supplied for the step", () => {
  assert.match(drawn({ address: "/runs/1/steps/outline" }), /^<a [^>]*href="\/runs\/1\/steps\/outline"/)
})
