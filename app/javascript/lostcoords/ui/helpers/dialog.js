import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"
import { settleFocus } from "lostcoords/ui/helpers/focus"

const registrations = new WeakMap()

// Turbo snapshots a page for Back with its open dialogs, and restoring one brings back the open
// attribute but not the top layer: the dialog shows inline, with no backdrop, focus trap or
// Escape. A dialog registered when the snapshot was taken is marked, so it comes back closed.
const MARK = "lcDialog"
document.addEventListener("turbo:before-render", ({ detail: { newBody } }) => {
  for (const dialog of newBody.querySelectorAll("dialog[data-lc-dialog]")) {
    dialog.removeAttribute("open")
    delete dialog.dataset[MARK]
  }
})
// A same-URL refresh morphs the page against server HTML, which never carries the mark.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.detail.attributeName === "data-lc-dialog" && registrations.has(event.target))
    event.preventDefault()
})

// Shows a modal <dialog> with focus on the dialog itself rather than its first control: a close
// button would draw the focus ring after a tap that focused nothing, and a first field would raise
// a phone's keyboard. A control marked autofocus still takes focus, and Tab reaches every control.
export function showDialog(dialog) {
  if (dialog.open) return
  dialog.showModal()
  if (dialog.querySelector("[autofocus]")) return
  if (!dialog.hasAttribute("tabindex")) dialog.tabIndex = -1
  dialog.focus({ preventScroll: true })
}

// Joins a <dialog> to the dismiss stack: Escape, the backdrop and a swipe call close, which may
// return false to keep it open, such as while it asks whether to discard changes. priority ranks
// it against panels open in it (a dialog is 10, a panel 20); restoreFocus runs after a close;
// lockScroll: false leaves the page scrollable behind it. Calling it again for an open dialog
// returns its registration; it ends when the dialog closes.
export function registerDialog(
  dialog,
  { close = () => dialog.close(), lockScroll, priority, restoreFocus } = {},
) {
  const existing = registrations.get(dialog)
  if (existing) return existing

  const unregisterDismissable = registerDismissable({
    element: dialog,
    type: "lc-dialog",
    lockScroll,
    priority,
    restoreFocus,
    close,
    isOpen: () => dialog.open,
  })
  // A click on the dialog element itself lands on its backdrop, or on its own padding, which
  // is inside its box and must not close it.
  const closeOnBackdrop = (event) => {
    if (event.target !== dialog) return
    const box = dialog.getBoundingClientRect()
    const inside =
      event.clientX >= box.left &&
      event.clientX <= box.right &&
      event.clientY >= box.top &&
      event.clientY <= box.bottom
    if (!inside) close(event)
  }
  // A dialog closed and shown again in the same task fires close while it is already open again.
  // By now the browser has handed focus back to what had it before the dialog opened.
  const unregisterOnClose = () => {
    if (dialog.open) return
    unregister()
    settleFocus()
  }
  const unregister = () => {
    if (registrations.get(dialog) !== unregister) return
    registrations.delete(dialog)
    delete dialog.dataset[MARK]
    dialog.removeEventListener("close", unregisterOnClose)
    dialog.removeEventListener("click", closeOnBackdrop)
    unregisterDismissable()
  }

  registrations.set(dialog, unregister)
  dialog.dataset[MARK] = ""
  dialog.addEventListener("close", unregisterOnClose)
  dialog.addEventListener("click", closeOnBackdrop)
  return unregister
}
