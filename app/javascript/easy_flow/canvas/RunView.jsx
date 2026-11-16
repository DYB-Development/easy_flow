import React from "react"
import LeftToRight from "./LeftToRight"
import GroupHeader from "./GroupHeader"
import RunCard from "./RunCard"
import { headerOf } from "./group"

const RunView = ({ nodes, edges, selected }) => (
  <LeftToRight nodes={nodes} edges={edges} joints={{}} draw={(node) => (node.holds
    ? <GroupHeader node={node} header={headerOf(node, node, false)} compact />
    : <RunCard node={node} selected={node.id === selected} />)} />
)

export default RunView
