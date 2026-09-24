import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"

const REACTS_OWN = "Minified React error"

const built = (name) => readFileSync(new URL(`../../app/assets/builds/easy_flow/${name}`, import.meta.url), "utf8")

test("the canvas carries no React of its own", () => {
  assert.equal(built("canvas.js").includes(REACTS_OWN), false)
})
