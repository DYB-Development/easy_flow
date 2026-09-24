import React, { useEffect, useMemo, useRef, useState } from "react"
import StepCard from "./StepCard"
import Inspector from "./Inspector"
import Placeholder from "./Placeholder"
import { offeredTo } from "./choices"
import TypePicker from "./TypePicker"
import Toolbar from "./Toolbar"
import Panel from "./Panel"
import ConnectorLayer from "./ConnectorLayer"
import useFlow from "./useFlow"
import useConnectors from "./useConnectors"
import { CARD, GAP_X, GAP_Y } from "./styles"
import { nextId } from "./ids"

const page = { display: "flex", height: "100%", minHeight: 0, fontSize: 13 }
const scroll = { flex: 1, overflow: "auto", position: "relative" }
const waiting = { position: "absolute", top: 56, left: 16, zIndex: 5, width: CARD + 24, padding: 12, borderRadius: 8 }

const grid = { display: "grid", rowGap: GAP_Y, columnGap: 0, padding: 40, justifyContent: "center", position: "relative" }
const notice = { position: "sticky", zIndex: 8, top: 8, margin: "8px auto 0", width: "fit-content", padding: "6px 12px", borderRadius: 6, fontSize: 12 }

export const Choosing = ({ port, onCancel }) => (
  <div className="bg-accent-100 text-accent-800 dark:bg-accent-900 dark:text-accent-100" style={notice}>
    Choose the step “{port || "next"}” should lead to — <button onClick={onCancel} className="text-accent-800 underline dark:text-accent-100" style={{ border: "none", background: "none", cursor: "pointer", fontSize: 12, padding: 0 }}>cancel</button>
  </div>
)

const Canvas = ({ base, token, initial }) => {
  const { flow, error, notice, send } = useFlow(base, token, initial)
  const [ selected, setSelected ] = useState(null)
  const [ adding, setAdding ] = useState(null)
  const [ armed, setArmed ] = useState(null)
  const [ dragging, setDragging ] = useState(null)
  const [ showing, setShowing ] = useState(false)
  const cards = useRef({})
  const surface = useRef(null)

  useEffect(() => {
    const open = () => { setSelected(null); setShowing(true) }
    document.addEventListener("easy_flow:open-flow", open)
    return () => document.removeEventListener("easy_flow:open-flow", open)
  }, [])

  useEffect(() => {
    if (!showing) return

    const away = (event) => {
      if (!event.target.closest("[data-builder-panel], [data-open-panel]")) setShowing(false)
    }
    document.addEventListener("click", away)
    return () => document.removeEventListener("click", away)
  }, [ showing ])

  useEffect(() => {
    document.dispatchEvent(new CustomEvent("easy_flow:flow-named", { detail: flow.flow?.title || flow.flow?.slug }))
  }, [ flow.flow?.title, flow.flow?.slug ])

  const byId = useMemo(() => Object.fromEntries(flow.nodes.map((node) => [ node.id, node ])), [ flow.nodes ])
  const { links, extent } = useConnectors(flow, surface, cards, [ flow, selected, byId ])

  const violationsFor = useMemo(() => {
    const grouped = {}
    flow.violations.forEach((violation) => (grouped[violation.node] ||= []).push(violation))
    return grouped
  }, [ flow.violations ])

  const attached = flow.nodes.filter((node) => !node.loose)
  const loose = flow.nodes.filter((node) => node.loose)
  const rows = Math.max(0, ...attached.map((node) => node.row)) + 1
  const columns = Math.max(0, ...attached.map((node) => node.column)) + 1

  const connectTo = (target) => {
    if (!armed) return

    const [ source, port ] = armed
    setArmed(null)
    if (source !== target) send("/edges", "POST", { from: source, to: target, on: port || null })
  }

  const selectedNode = flow.nodes.find((node) => node.id === selected)
  const entryFor = flow.palette.find((entry) => entry.type === selectedNode?.type)

  return (
    <div className="text-gray-900 dark:text-gray-100" style={page} onMouseUp={() => setDragging(null)}
         onKeyDown={(event) => { if (event.key === "Escape") { setSelected(null); setArmed(null); setAdding(null) } }}
         tabIndex={-1}>
      <div ref={surface} className="bg-surface-50 dark:bg-surface-950" style={scroll}
           onClick={(event) => { if (event.target === surface.current) { setSelected(null); setArmed(null); setShowing(false) } }}>
        {armed && (
          <Choosing port={armed[1]} onCancel={() => setArmed(null)} />
        )}
        <Toolbar undoable={flow.undoable} redoable={flow.redoable}
                 onAdd={() => setAdding({ at: { x: 16, y: 52 } })}
                 onUndo={() => { setSelected(null); send("/undo", "POST") }}
                 onRedo={() => { setSelected(null); send("/redo", "POST") }} />

        <ConnectorLayer links={links} extent={extent} dragging={dragging}
                        onInsert={(link) => setAdding({ from: link.source, to: link.target, at: { x: link.midX + 30, y: link.midY } })}
                        onRemove={(link) => { setSelected(null); send("/edges", "DELETE", { from: link.source, to: link.target }) }}
                        onDrop={(link) => { const held = dragging; setDragging(null); send("/steps/" + held + "/move", "PATCH", { from: link.source, to: link.target }) }} />

        {loose.length > 0 && (
          <div data-loose className="border border-dashed border-gray-300 bg-gray-50 dark:border-zinc-700 dark:bg-zinc-900" style={waiting}>
            <div className="text-gray-500 dark:text-gray-400" style={{ fontSize: 11, marginBottom: 6 }}>Not in the flow yet — drag one onto a connection</div>
            {loose.map((node) => (
              <div key={node.id} style={{ marginBottom: 8 }}>
                <StepCard
                  node={{
                    ...node,
                    ref: (element) => { cards.current[node.id] = element },
                    violations: violationsFor[node.id] || [],
                    connected: []
                  }}
                  selected={selected === node.id}
                  armed={armed && armed[0] === node.id ? armed[1] : null}
                  connecting={Boolean(armed)}
                  onSelect={() => (armed ? connectTo(node.id) : setSelected(node.id))}
                  onArm={(port, event) => { event.stopPropagation(); setArmed([ node.id, port ]) }}
                  onDragStart={() => setDragging(node.id)}
                  onDragEnd={() => setDragging(null)} />
              </div>
            ))}
          </div>
        )}

        <div style={{ ...grid, gridTemplateColumns: `repeat(${columns + 1}, ${(CARD + GAP_X) / 2}px)`, gridTemplateRows: `repeat(${rows}, auto)` }}>
          {attached.map((node) => (
            <div key={node.id} style={{ gridRow: node.row + 1, gridColumn: `${node.column + 1} / span 2`, zIndex: 2 }}>
              {node.placeholder && (
                <Placeholder node={{ ...node, ref: (element) => { cards.current[node.id] = element } }}
                             dragging={Boolean(dragging)}
                             onFill={() => setAdding({ from: node.from, on: node.on, at: { x: 16, y: 52 } })}
                             onDrop={() => {
                               const held = dragging
                               setDragging(null)
                               if (held) send("/edges", "POST", { from: node.from, to: held, on: node.on })
                             }} />
              )}
              {!node.placeholder && <StepCard
                node={{
                  ...node,
                  ref: (element) => { cards.current[node.id] = element },
                  violations: violationsFor[node.id] || [],
                  connected: flow.edges.filter((edge) => edge.source === node.id).map((edge) => edge.label || null)
                }}
                selected={node.id === selected}
                armed={armed && armed[0] === node.id ? armed[1] : null}
                connecting={Boolean(armed) && armed[0] !== node.id}
                onSelect={() => (armed ? connectTo(node.id) : setSelected(node.id))}
                onArm={(port, event) => {
                  const frame = surface.current.getBoundingClientRect()
                  setAdding({
                    from: node.id, on: port,
                    at: { x: event.clientX - frame.left + surface.current.scrollLeft + 8,
                          y: event.clientY - frame.top + surface.current.scrollTop + 8 }
                  })
                }}
                onDragEnd={() => setDragging(null)}
                onDragStart={() => setDragging(node.id)}
              />}
            </div>
          ))}
        </div>

        {adding && (
          <TypePicker entries={flow.palette} at={adding.at} onDismiss={() => setAdding(null)}
                      onConnect={adding.on !== undefined ? () => { setArmed([ adding.from, adding.on ]); setAdding(null) } : null}
                      onPick={(entry) => {
                        const where = adding
                        setAdding(null)
                        send("/steps", "POST", { id: nextId(entry.type, flow.nodes.map((node) => node.id)), type: entry.type, from: where.from, to: where.to, on: where.on })
                      }} />
        )}
      </div>

      {showing && !selectedNode && (
        <Panel flow={flow.flow || {}} changes={flow.changes || []} problems={flow.violations} refusal={error} notice={notice}
               onClose={() => setShowing(false)}
               onCreate={() => send("/versions", "POST")}
               onPublish={() => send("/publish", "POST")}
               onSaveDetails={(details) => send("/details", "PATCH", { flow: details })} />
      )}

      {selectedNode && (
        <Inspector node={selectedNode}
                   fields={entryFor?.fields || {}} holds={entryFor?.records || {}}
                   labels={entryFor?.labels || {}} recordLabels={entryFor?.record_labels || {}}
                   choices={offeredTo(selectedNode, entryFor)}
                   onClose={() => setSelected(null)}
                   onSave={(config) => send(`/steps/${selectedNode.id}`, "PATCH", { config })}
                   onDelete={() => { setSelected(null); send(`/steps/${selectedNode.id}`, "DELETE") }} />
      )}
    </div>
  )
}

export default Canvas
