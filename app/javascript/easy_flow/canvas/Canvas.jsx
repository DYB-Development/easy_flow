import React, { useEffect, useMemo, useRef, useState } from "react"
import StepCard from "./StepCard"
import GroupHeader from "./GroupHeader"
import GroupBox from "./GroupBox"
import { boxAt, headerOf, linksOutside, underHeader } from "./group"
import Inspector from "./Inspector"
import Placeholder from "./Placeholder"
import { offeredTo } from "./choices"
import TypePicker from "./TypePicker"
import StepList from "./StepList"
import Toolbar from "./Toolbar"
import Panel from "./Panel"
import Drawer from "./Drawer"
import ConnectorLayer from "./ConnectorLayer"
import LeftToRight from "./LeftToRight"
import useFlow from "./useFlow"
import useConnectors from "./useConnectors"
import { CARD, GAP_X, GAP_Y } from "./styles"
import { nextId } from "./ids"
import { branchLinesOf } from "./reading"

const HEADER_GAP = 8

const page = { display: "flex", height: "100%", minHeight: 0, fontSize: 13, position: "relative" }
const column = { flex: 1, minWidth: 0, display: "flex", flexDirection: "column", position: "relative" }
const scroll = { flex: 1, minHeight: 0, overflow: "auto", position: "relative" }
const waiting = { position: "absolute", top: 56, left: 16, zIndex: 5, width: CARD + 24, padding: 12, borderRadius: 8 }

const waitingInRows = { ...waiting, position: "static", alignSelf: "flex-start" }

const grid = { display: "grid", rowGap: GAP_Y, columnGap: 0, padding: 40, justifyContent: "center", position: "relative" }
const notice = { position: "sticky", zIndex: 8, top: 8, margin: "8px auto 0", width: "fit-content", padding: "6px 12px", borderRadius: 6, fontSize: 12 }

export const Choosing = ({ port, onCancel }) => (
  <div className="bg-accent-100 text-accent-800 dark:bg-accent-900 dark:text-accent-100" style={notice}>
    Choose the step “{port || "next"}” should lead to — <button onClick={onCancel} className="text-accent-800 underline dark:text-accent-100" style={{ border: "none", background: "none", cursor: "pointer", fontSize: 12, padding: 0 }}>cancel</button>
  </div>
)

const Canvas = ({ base, token, initial }) => {
  const { flow, error, notice, warning, setWarning, send, pickPicture } = useFlow(base, token, initial)
  const [ selected, setSelected ] = useState(null)
  const [ adding, setAdding ] = useState(null)
  const [ armed, setArmed ] = useState(null)
  const [ dragging, setDragging ] = useState(null)
  const [ carrying, setCarrying ] = useState(null)
  const [ showing, setShowing ] = useState(false)
  const cards = useRef({})
  const surface = useRef(null)

  useEffect(() => {
    const paths = { open: null, publish: "/publish", save_draft: "/versions" }
    const pressed = (event) => {
      const button = event.target.closest?.("[data-bar-action]")
      if (!button || !(button.dataset.barAction in paths)) return

      button.closest("details")?.removeAttribute("open")
      setSelected(null)
      setShowing(true)
      const path = paths[button.dataset.barAction]
      if (path) send(path, "POST")
    }
    document.addEventListener("click", pressed)
    return () => document.removeEventListener("click", pressed)
  }, [ send ])

  useEffect(() => {
    if (!showing) {
      setWarning(null)
      return
    }

    const away = (event) => {
      if (event.target.isConnected && !event.target.closest("[data-builder-panel], [data-open-panel], [data-bar-action]")) setShowing(false)
    }
    document.addEventListener("click", away)
    return () => document.removeEventListener("click", away)
  }, [ showing ])

  useEffect(() => {
    document.dispatchEvent(new CustomEvent("easy_flow:flow-named", { detail: flow.flow?.title || flow.flow?.slug }))
  }, [ flow.flow?.title, flow.flow?.slug ])

  useEffect(() => {
    document.dispatchEvent(new CustomEvent("easy_flow:flow-status", { detail: { status: flow.flow?.status, publishes: flow.flow?.publishes } }))
  }, [ flow.flow?.status, flow.flow?.publishes ])

  const byId = useMemo(() => Object.fromEntries(flow.nodes.map((node) => [ node.id, node ])), [ flow.nodes ])
  const { links, extent, boxes } = useConnectors(flow, surface, cards, [ flow, selected, byId ])

  const violationsFor = useMemo(() => {
    const grouped = {}
    flow.violations.forEach((violation) => (grouped[violation.node] ||= []).push(violation))
    return grouped
  }, [ flow.violations ])

  const leftToRight = flow.direction === "left_to_right"
  const attached = useMemo(() => flow.nodes.filter((node) => !node.loose), [ flow.nodes ])
  const loose = flow.nodes.filter((node) => node.loose)
  const branchLines = useMemo(() => (leftToRight ? branchLinesOf(attached, flow.edges, flow.nodes) : {}), [ leftToRight, attached, flow.edges, flow.nodes ])
  const connectedFrom = useMemo(() => {
    const ports = {}
    flow.edges.forEach((edge) => (ports[edge.source] ||= []).push(edge.label || null))
    return ports
  }, [ flow.edges ])
  const rows = Math.max(0, ...attached.map((node) => node.row)) + 1
  const columns = Math.max(0, ...attached.map((node) => node.column)) + 1

  const connectTo = (target) => {
    if (!armed) return

    const [ source, port ] = armed
    setArmed(null)
    if (source !== target) send("/edges", "POST", { from: source, to: target, on: port || null })
  }

  const regroup = (event) => {
    if (event.isDefaultPrevented() || !dragging) return
    event.preventDefault()
    const held = dragging
    setDragging(null)
    const frame = surface.current.getBoundingClientRect()
    const into = boxAt(boxes, { x: event.clientX - frame.left + surface.current.scrollLeft, y: event.clientY - frame.top + surface.current.scrollTop })
    const from = flow.nodes.find((node) => node.holds?.includes(held))?.id || null
    if (into !== from) send(`/steps/${held}/group`, "PATCH", { group: into })
  }

  const entryOf = (node) => [ ...flow.palette, ...(flow.unoffered || []) ].find((entry) => entry.type === node?.type)
  const selectedNode = flow.nodes.find((node) => node.id === selected)
  const entryFor = entryOf(selectedNode)

  const addStep = (entry, where = {}) =>
    send("/steps", "POST", { id: nextId(entry.type, flow.nodes.map((node) => node.id)), type: entry.type, from: where.from, to: where.to, on: where.on })

  const dropOnLink = (link) => {
    const [ entry, held ] = [ carrying, dragging ]
    setCarrying(null)
    setDragging(null)
    if (entry) addStep(entry, { from: link.source, to: link.target })
    else if (held) send("/steps/" + held + "/move", "PATCH", { from: link.source, to: link.target })
  }

  const pointed = (event) => {
    const frame = surface.current.getBoundingClientRect()
    return { x: event.clientX - frame.left + surface.current.scrollLeft + 8, y: event.clientY - frame.top + surface.current.scrollTop + 8 }
  }

  const cardProps = (node, connected) => ({
    node: { ...node, ref: (element) => { cards.current[node.id] = element }, violations: violationsFor[node.id] || [], connected },
    selected: node.id === selected,
    armed: armed && armed[0] === node.id ? armed[1] : null,
    connecting: Boolean(armed) && armed[0] !== node.id,
    onSelect: () => (armed ? connectTo(node.id) : setSelected(node.id)),
    onOpen: (path) => window.location.assign(path),
    onDragStart: () => setDragging(node.id),
    onDragEnd: () => setDragging(null),
    hideStepTypeCodes: flow.hide_step_type_codes,
    compact: leftToRight,
    branches: branchLines[node.id] || []
  })

  const draw = (node) => (
    <>
      {node.placeholder && (
        <Placeholder node={{ ...node, ref: (element) => { cards.current[node.id] = element } }}
                     dragging={Boolean(dragging)} compact={leftToRight}
                     onFill={() => setAdding({ from: node.from, on: node.on, at: { x: 16, y: 52 } })}
                     onDrop={() => {
                       const held = dragging
                       setDragging(null)
                       if (held) send("/edges", "POST", { from: node.from, to: held, on: node.on })
                     }} />
      )}
      {node.holds && (
        <GroupHeader node={{ ...node, ref: (element) => { cards.current[node.id] = element } }}
                     header={headerOf(node, entryOf(node), flow.hide_step_type_codes)} compact={leftToRight}
                     onSelect={() => (armed ? connectTo(node.id) : setSelected(node.id))} />
      )}
      {!node.placeholder && !node.holds && <StepCard {...cardProps(node, connectedFrom[node.id] || [])}
        onArm={(port, event) => setAdding({ from: node.id, on: port, at: pointed(event) })} />}
    </>
  )

  const waitingSteps = loose.length > 0 && (
    <div data-loose className="border border-dashed border-gray-300 bg-gray-50 dark:border-zinc-700 dark:bg-zinc-900" style={leftToRight ? waitingInRows : waiting}>
      <div className="text-gray-500 dark:text-gray-400" style={{ fontSize: 11, marginBottom: 6 }}>Not in the flow yet — drag one onto a connection</div>
      {loose.map((node) => (
        <div key={node.id} style={{ marginBottom: 8 }}>
          <StepCard {...cardProps(node, [])}
                    onArm={(port, event) => { event.stopPropagation(); setArmed([ node.id, port ]) }} />
        </div>
      ))}
    </div>
  )

  return (
    <div className="text-gray-900 dark:text-gray-100" style={page} onMouseUp={() => setDragging(null)}
         onKeyDown={(event) => { if (event.key === "Escape") { setSelected(null); setArmed(null); setAdding(null) } }}
         tabIndex={-1}>
      <StepList entries={flow.palette} groups={flow.step_groups || {}}
                onPick={(entry) => addStep(entry)} onCarry={setCarrying} onDrop={() => setCarrying(null)} />
      <div className="bg-surface-50 dark:bg-surface-950" style={column}>
        <div ref={surface} style={scroll}
             onClick={(event) => { if (event.target === surface.current) { setSelected(null); setArmed(null); setShowing(false) } }}
             onDragOver={(event) => { if (dragging) event.preventDefault() }}
             onDrop={regroup}>
          {armed && (
            <Choosing port={armed[1]} onCancel={() => setArmed(null)} />
          )}
          <Toolbar undoable={flow.undoable} redoable={flow.redoable}
                   onAdd={() => setAdding({ at: { x: 16, y: 52 } })}
                   onUndo={() => { setSelected(null); send("/undo", "POST") }}
                   onRedo={() => { setSelected(null); send("/redo", "POST") }} />

          {!leftToRight && boxes.map((box) => (
            <GroupBox key={box.id} id={box.id} bounds={box.bounds}
                      onDrop={() => { const held = dragging; setDragging(null); if (held) send(`/steps/${held}/group`, "PATCH", { group: box.id }) }} />
          ))}

          {!leftToRight && <ConnectorLayer links={linksOutside(links, flow.nodes)} extent={extent} dragging={dragging || carrying} alwaysShowInsertButtons={flow.always_show_insert_buttons}
                          onInsert={(link) => setAdding({ from: link.source, to: link.target, at: { x: link.midX + 30, y: link.midY } })}
                          onRemove={(link) => { setSelected(null); send("/edges", "DELETE", { from: link.source, to: link.target }) }}
                          onDrop={dropOnLink} />}

          {!leftToRight && waitingSteps}

          {leftToRight && <LeftToRight nodes={attached} edges={flow.edges} draw={draw} joints={{
            alwaysShowInsertButtons: flow.always_show_insert_buttons,
            dragging: Boolean(dragging || carrying),
            onInsert: (link, event) => setAdding({ from: link.source, to: link.target, at: pointed(event) }),
            onRemove: (link) => { setSelected(null); send("/edges", "DELETE", { from: link.source, to: link.target }) },
            onDrop: dropOnLink
          }}>{waitingSteps}</LeftToRight>}

          {!leftToRight && <div style={{ ...grid, gridTemplateColumns: `repeat(${columns + 1}, ${(CARD + GAP_X) / 2}px)`, gridTemplateRows: `repeat(${rows}, auto)` }}>
            {attached.map((node) => (
              <div key={node.id} style={{ gridRow: node.row + 1, gridColumn: `${node.column + 1} / span 2`, zIndex: 2, marginTop: underHeader(node, flow.nodes) ? HEADER_GAP - GAP_Y : 0 }}>
                {draw(node)}
              </div>
            ))}
          </div>}

          {adding && (
            <TypePicker entries={flow.palette} at={adding.at} onDismiss={() => setAdding(null)} hideStepTypeCodes={flow.hide_step_type_codes}
                        onConnect={adding.on !== undefined ? () => { setArmed([ adding.from, adding.on ]); setAdding(null) } : null}
                        onPick={(entry) => {
                          const where = adding
                          setAdding(null)
                          addStep(entry, where)
                        }} />
          )}
        </div>
        <Drawer checks={flow.checks || []} tabs={flow.drawer_tabs || []} onSelect={setSelected} />
      </div>

      {showing && !selectedNode && (
        <Panel flow={flow.flow || {}} changes={flow.changes || []} refusal={error} notice={notice} publishNote={flow.publish_note} warning={warning}
               onClose={() => setShowing(false)}
               onCreate={() => send("/versions", "POST")}
               onPublish={() => send("/publish", "POST")}
               onAccept={() => send(warning.path, "POST", { remove_unconnected: warning.steps.map((step) => step.id) })}
               onDecline={() => setWarning(null)}
               onSaveDetails={(details) => send("/details", "PATCH", { flow: details })} />
      )}

      {selectedNode && (
        <Inspector node={selectedNode}
                   fields={entryFor?.fields || {}} holds={entryFor?.records || {}}
                   labels={entryFor?.labels || {}} explanations={entryFor?.explanations || {}} recordLabels={entryFor?.record_labels || {}} recordExplanations={entryFor?.record_explanations || {}}
                   recordChoices={entryFor?.record_choices || {}} recordOutputsOf={entryFor?.record_outputs_of || {}}
                   choices={offeredTo(selectedNode, entryFor)}
                   onClose={() => setSelected(null)}
                   onSave={(config) => send(`/steps/${selectedNode.id}`, "PATCH", { config })}
                   onPickPicture={pickPicture}
                   refusal={error}
                   onDelete={() => { setSelected(null); send(`/steps/${selectedNode.id}`, "DELETE") }} />
      )}
    </div>
  )
}

export default Canvas
