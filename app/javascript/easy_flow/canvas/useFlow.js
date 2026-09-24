import { useMemo, useState } from "react"
import { createFlowSender } from "./flowSender"

const useFlow = (base, token, initial) => {
  const [ flow, setFlow ] = useState(initial)
  const [ error, setError ] = useState(null)
  const [ notice, setNotice ] = useState(null)

  const send = useMemo(
    () => createFlowSender({ base, token, fetch: (...request) => window.fetch(...request), onFlow: setFlow, onError: setError, onNotice: setNotice }),
    [ base, token ]
  )

  return { flow, error, notice, send }
}

export default useFlow
