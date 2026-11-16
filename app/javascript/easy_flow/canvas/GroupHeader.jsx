import React from "react"
import { CARD } from "./styles"

const line = { position: "relative", zIndex: 2, width: CARD, fontSize: 11, whiteSpace: "nowrap", cursor: "pointer" }

const compactLine = { ...line, width: "auto", whiteSpace: "normal", overflowWrap: "anywhere" }

const GroupHeader = ({ node, header, onSelect, compact = false }) => (
  <div ref={node.ref} data-group-header={node.id} onClick={onSelect}
       className="font-mono text-gray-500 dark:text-gray-400"
       style={compact ? compactLine : line}>{header}</div>
)

export default GroupHeader
