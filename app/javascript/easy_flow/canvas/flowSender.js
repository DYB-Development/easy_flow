const UNREACHABLE = "Your change was not saved because the server could not be reached."

export const createFlowSender = ({ base, token, fetch, onFlow, onError, onNotice }) => async (path, method, body) => {
  const response = await fetch(base + path, {
    method, headers: { "Content-Type": "application/json", "X-CSRF-Token": token }, body: body && JSON.stringify(body)
  }).catch(() => null)
  if (!response) {
    onNotice(null)
    return onError(UNREACHABLE)
  }

  const answered = await response.json().catch(() => ({}))

  if (!response.ok) {
    onNotice(null)
    return onError(answered.error || "That change was refused")
  }

  onError(null)
  onNotice(answered.notice || null)
  onFlow(await (await fetch(base + ".json", { headers: { Accept: "application/json" } })).json())
}
