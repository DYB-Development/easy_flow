import React from "react"
import { CARD } from "./styles"

const GroupHeader = ({ node, header }) => (
  <div ref={node.ref} data-group-header={node.id}
       className="font-mono text-gray-500 dark:text-gray-400"
       style={{ position: "relative", zIndex: 2, width: CARD, fontSize: 11, whiteSpace: "nowrap" }}>{header}</div>
)

export default GroupHeader
