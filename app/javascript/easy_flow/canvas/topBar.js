export const barPressed = ({ send, onPress }) => (event) => {
  const button = event.target.closest?.("[data-bar-action]")
  if (!button) return

  button.closest("details")?.removeAttribute("open")
  onPress()
  if (button.dataset.barPath) send(button.dataset.barPath, "POST")
}
