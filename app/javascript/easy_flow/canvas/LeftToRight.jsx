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

const LeftToRight = ({ nodes, edges, draw }) => (
  <div data-flow-rows style={stack}>
    {blocksOf(nodes).map((block) => (
      <Steps key={block.group?.id || block.steps[0].id} steps={block.steps} edges={edges} draw={draw} />
    ))}
  </div>
)

export default LeftToRight
