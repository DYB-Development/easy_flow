import React from "react"
import { blocksOf } from "./reading"

const stack = { display: "flex", flexDirection: "column", gap: 14, padding: "64px 24px 24px" }

const Steps = ({ steps, draw }) => (
  <div data-flow-row className="flex flex-col sm:flex-row sm:flex-wrap sm:items-center" style={{ rowGap: 14 }}>
    {steps.map((step) => (
      <div key={step.id} className="flex flex-col sm:flex-row sm:items-center">
        {draw(step)}
      </div>
    ))}
  </div>
)

const LeftToRight = ({ nodes, draw }) => (
  <div data-flow-rows style={stack}>
    {blocksOf(nodes).map((block) => (
      <Steps key={block.group?.id || block.steps[0].id} steps={block.steps} draw={draw} />
    ))}
  </div>
)

export default LeftToRight
