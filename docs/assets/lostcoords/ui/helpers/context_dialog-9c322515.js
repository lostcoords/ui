import { isSheetViewport } from "lostcoords/ui/helpers/viewport"

const EDGE = 16

export function showContextDialog(dialog, menu) {
  delete dialog.dataset.anchored
  if (!dialog.open) dialog.showModal()

  const rect = menu?.getBoundingClientRect()
  const corner = rect?.height
    ? { top: Math.max(EDGE, rect.bottom - dialog.offsetHeight), right: rect.right }
    : null
  if (anchorDialog(dialog, corner)) dialog.style.setProperty("--lc-dialog-origin", "bottom right")
}

export function anchorDialog(dialog, corner) {
  delete dialog.dataset.anchored
  dialog.style.removeProperty("--lc-dialog-top")
  dialog.style.removeProperty("--lc-dialog-right")
  if (!corner || isSheetViewport()) return false

  dialog.dataset.anchored = ""
  dialog.style.setProperty("--lc-dialog-top", `${corner.top}px`)
  dialog.style.setProperty(
    "--lc-dialog-right",
    `${Math.max(EDGE, window.innerWidth - corner.right)}px`,
  )
  return true
}
