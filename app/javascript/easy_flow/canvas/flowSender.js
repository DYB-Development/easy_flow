const UNREACHABLE = "Your change was not saved because the server could not be reached."

const NOT_REFRESHED = "Your change was saved, but the canvas could not be refreshed. Reload the page to see it."

const redraw = async ({ base, fetch, onFlow, onError }) => {
  const response = await fetch(base + ".json", { headers: { Accept: "application/json" } }).catch(() => null)
  const flow = response?.ok ? await response.json().catch(() => null) : null

  return flow ? onFlow(flow) : onError(NOT_REFRESHED)
}

export const createFlowSender = ({ base, token, fetch, onFlow, onError, onNotice, onWarning = () => {} }) => async (path, method, body) => {
  const drawn = { base, fetch, onFlow, onError }
  const response = await fetch(base + path, {
    method, headers: { "Content-Type": "application/json", "X-CSRF-Token": token }, body: body && JSON.stringify(body)
  }).catch(() => null)
  if (!response) {
    onNotice(null)
    return onError(UNREACHABLE)
  }

  const answered = await response.json().catch(() => ({}))

  if (answered.unconnected) {
    onNotice(null)
    onError(null)
    onWarning({ path, steps: answered.unconnected })
    return redraw(drawn)
  }

  onWarning(null)

  if (!response.ok) {
    onNotice(null)
    return onError(answered.error || "That change was refused")
  }

  onError(null)
  onNotice(answered.notice || null)
  return redraw(drawn)
}

export const createPictureSender = ({ base, token, fetch, onError }) => async (file) => {
  const body = new FormData()
  body.append("picture", file)
  const response = await fetch(base + "/pictures", { method: "POST", headers: { "X-CSRF-Token": token }, body }).catch(() => null)
  if (!response) {
    onError(UNREACHABLE)
    return null
  }

  const answered = await response.json().catch(() => ({}))
  if (!response.ok) {
    onError(answered.error || "That picture was refused")
    return null
  }

  onError(null)
  return answered
}
