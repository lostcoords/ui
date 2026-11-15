import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"

const registrations = new WeakMap()

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
  const unregisterOnClose = () => {
    if (!dialog.open) unregister()
  }
  const unregister = () => {
    if (registrations.get(dialog) !== unregister) return
    registrations.delete(dialog)
    dialog.removeEventListener("close", unregisterOnClose)
    dialog.removeEventListener("click", closeOnBackdrop)
    unregisterDismissable()
  }

  registrations.set(dialog, unregister)
  dialog.addEventListener("close", unregisterOnClose)
  dialog.addEventListener("click", closeOnBackdrop)
  return unregister
}
