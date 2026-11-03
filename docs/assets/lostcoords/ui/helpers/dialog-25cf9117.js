import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"

const registrations = new WeakMap()

export function registerDialog(dialog, { close = () => dialog.close(), lockScroll } = {}) {
  const existing = registrations.get(dialog)
  if (existing) return existing

  const unregisterDismissable = registerDismissable({
    element: dialog,
    type: "lc-dialog",
    lockScroll,
    close,
    isOpen: () => dialog.open,
  })
  const closeOnBackdrop = (event) => {
    if (event.target === dialog) close(event)
  }
  const unregister = () => {
    if (registrations.get(dialog) !== unregister) return
    registrations.delete(dialog)
    dialog.removeEventListener("close", unregister)
    dialog.removeEventListener("click", closeOnBackdrop)
    unregisterDismissable()
  }

  registrations.set(dialog, unregister)
  dialog.addEventListener("close", unregister)
  dialog.addEventListener("click", closeOnBackdrop)
  return unregister
}
