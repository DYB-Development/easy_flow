import React from "react"
import Joint from "./Joint"
import { blocksOf, joining } from "./reading"

const stack = { display: "flex", flexDirection: "column", gap: 14, padding: "64px 24px 24px" }

const Steps = ({ steps, edges, draw }) => (
  <div data-flow-row className="flex flex-col sm:flex-row sm:flex-wrap sm:items-center" style={{ rowGap: 14 }}>
    {steps.map((step, at) => (
      <div key={step.id} className="flex flex-col sm:flex-row sm:items-center">
        {at > 0 && <Joint link={joining(edges, steps[at - 1], step)} />}
        {draw(step)}
      </div>
    ))}
  </div>
)

const box = { display: "flex", flexDirection: "column", gap: 8, padding: "10px 12px", borderRadius: 8 }

const Box = ({ group, steps, edges, draw }) => (
  <div data-group-box={group.id} className="border border-dashed border-gray-400 bg-white/60 dark:border-zinc-600 dark:bg-zinc-900/60" style={box}>
    {draw(group)}
    <Steps steps={steps} edges={edges} draw={draw} />
  </div>
)

const LeftToRight = ({ nodes, edges, draw }) => (
  <div data-flow-rows style={stack}>
    {blocksOf(nodes).map((block) => (block.group
      ? <Box key={block.group.id} group={block.group} steps={block.steps} edges={edges} draw={draw} />
      : <Steps key={block.steps[0].id} steps={block.steps} edges={edges} draw={draw} />))}
  </div>
)

export default LeftToRight
