import React from "react"
import { CARD } from "./styles"

const GroupHeader = ({ node, header, onSelect }) => (
  <div ref={node.ref} data-group-header={node.id} onClick={onSelect}
       className="font-mono text-gray-500 dark:text-gray-400"
       style={{ position: "relative", zIndex: 2, width: CARD, fontSize: 11, whiteSpace: "nowrap", cursor: "pointer" }}>{header}</div>
)

export default GroupHeader
