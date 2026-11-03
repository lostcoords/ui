import { isSheetViewport } from "helpers/viewport"

const EDGE = 16

export function showContextDialog(dialog, menu) {
  delete dialog.dataset.anchored
  if (!dialog.open) dialog.showModal()

  const rect = menu?.getBoundingClientRect()
  const corner = rect?.height
    ? { top: Math.max(EDGE, rect.bottom - dialog.offsetHeight), right: rect.right }
    : null
  if (anchorDialog(dialog, corner)) dialog.style.setProperty("--dialog-origin", "bottom right")
}

export function anchorDialog(dialog, corner) {
  delete dialog.dataset.anchored
  dialog.style.removeProperty("--dialog-top")
  dialog.style.removeProperty("--dialog-right")
  if (!corner || isSheetViewport()) return false

  dialog.dataset.anchored = ""
  dialog.style.setProperty("--dialog-top", `${corner.top}px`)
  dialog.style.setProperty(
    "--dialog-right",
    `${Math.max(EDGE, window.innerWidth - corner.right)}px`,
  )
  return true
}
