import React from "react"

const open = "border border-amber-500 bg-white text-amber-700 dark:bg-zinc-900 dark:text-amber-400"
const joined = "border border-gray-300 bg-white text-gray-500 dark:border-zinc-600 dark:bg-zinc-900 dark:text-gray-400"
const choosing = "border border-accent-600 bg-accent-600 text-white"

const Port = ({ name, connected, armed, onArm, connecting }) => (
  <button onClick={(event) => { if (connecting) return; event.stopPropagation(); onArm(event) }}
          title={armed ? "Now choose a step to connect to" : "Connect this branch"}
          className={armed ? choosing : connected ? joined : open}
          style={{
            padding: "1px 8px", marginRight: 4, borderRadius: 999, fontSize: 11, cursor: "pointer"
          }}>{name || "next"}</button>
)

export default Port
