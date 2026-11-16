import React from "react"

const GroupBox = ({ id, bounds }) => (
  <div data-group-box={id}
       className="border border-dashed border-gray-400 bg-white/60 dark:border-zinc-600 dark:bg-zinc-900/60"
       style={{ position: "absolute", zIndex: 1, borderRadius: 8, boxSizing: "border-box", ...bounds }} />
)

export default GroupBox
