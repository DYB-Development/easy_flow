import { useMemo, useState } from "react"
import { createFlowSender, createPictureSender } from "./flowSender"

const useFlow = (base, token, initial) => {
  const [ flow, setFlow ] = useState(initial)
  const [ error, setError ] = useState(null)
  const [ notice, setNotice ] = useState(null)
  const [ warning, setWarning ] = useState(null)

  const send = useMemo(
    () => createFlowSender({ base, token, fetch: (...request) => window.fetch(...request), onFlow: setFlow, onError: setError, onNotice: setNotice, onWarning: setWarning }),
    [ base, token ]
  )

  const pickPicture = useMemo(
    () => createPictureSender({ base, token, fetch: (...request) => window.fetch(...request), onError: setError }),
    [ base, token ]
  )

  return { flow, error, notice, warning, setWarning, send, pickPicture }
}

export default useFlow
