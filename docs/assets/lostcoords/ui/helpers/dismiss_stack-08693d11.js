const stack = []
let nextOrder = 0
let lockedScrollY = 0
let scrollHolds = 0

export function registerDismissable(options) {
  if (stack.length === 0) document.addEventListener("keydown", dismissOnEscape, true)
  const entry = {
    type: "panel",
    isOpen: defaultIsOpen,
    ...options,
  }
  entry.priority ??= priorityFor(entry.type)
  entry.order = nextOrder++

  stack.push(entry)
  syncModalScrollLock()

  if (entry.type === "lc-dialog" && entry.element instanceof HTMLDialogElement) {
    entry.cancel = (event) => cancelDialog(event, entry)
    entry.element.addEventListener("cancel", entry.cancel)
  }

  return () => unregisterDismissable(entry)
}

export function holdDocumentScroll() {
  scrollHolds++
  syncModalScrollLock()

  let held = true
  return () => {
    if (!held) return
    held = false
    scrollHolds--
    syncModalScrollLock()
  }
}

export function closeTopDismissable(event) {
  const entry = topDismissable()
  if (!entry) return false

  closeEntry(entry, event)
  return true
}

function dismissOnEscape(event) {
  if (event.key !== "Escape" && event.key !== "Esc") return
  if (clearSearchField(event)) return
  if (!closeTopDismissable(event)) return

  event.preventDefault()
  event.stopPropagation()
  event.stopImmediatePropagation()
}

// Escape in a search field that has text clears it, as a native search field
// does, and only the next Escape closes the panel around it.
function clearSearchField(event) {
  const field = event.target
  if (!(field instanceof HTMLInputElement) || field.type !== "search" || field.value === "")
    return false
  if (!topDismissable()?.element.contains(field)) return false

  event.preventDefault()
  event.stopImmediatePropagation()
  field.value = ""
  field.dispatchEvent(new Event("input", { bubbles: true }))
  return true
}

function cancelDialog(event, dialogEntry) {
  const entry = topDismissable(dialogEntry.element)
  if (!entry) return

  event.preventDefault()
  closeEntry(entry, event)
}

function closeEntry(entry, event) {
  const closed = entry.close?.(event)
  if (closed === false) return

  entry.restoreFocus?.()
}

function topDismissable(scope = topModal()?.element) {
  const entries = openEntries()
  const scopedEntries = scope
    ? entries.filter((entry) => entry.element === scope || scope.contains(entry.element))
    : entries

  return scopedEntries.sort((a, b) => a.priority - b.priority || a.order - b.order).at(-1)
}

function topModal() {
  return openEntries()
    .filter((entry) => entry.type === "lc-dialog")
    .at(-1)
}

// The modal the page is limited to, if any: the top open lc-dialog, or a native
// modal <dialog> opened without one. Shortcuts and toasts stay inside it.
export function topModalElement() {
  return topModal()?.element ?? [...document.querySelectorAll("dialog:modal")].at(-1) ?? null
}

function openEntries() {
  return stack.filter((entry) => entry.element?.isConnected && entry.isOpen.call(entry))
}

function unregisterDismissable(entry) {
  const index = stack.indexOf(entry)
  if (index >= 0) stack.splice(index, 1)
  if (stack.length === 0) document.removeEventListener("keydown", dismissOnEscape, true)

  if (entry.cancel) {
    entry.element.removeEventListener("cancel", entry.cancel)
    entry.cancel = null
  }

  syncModalScrollLock()
}

function defaultIsOpen() {
  if (this.element instanceof HTMLDialogElement) return this.element.open
  if (this.element.hidden) return false
  return true
}

function priorityFor(type) {
  if (type === "tooltip") return 40
  if (type === "popover") return 30
  if (type === "panel") return 20
  return 10
}

function syncModalScrollLock() {
  if (
    scrollHolds > 0 ||
    openEntries().some((entry) => entry.type === "lc-dialog" && entry.lockScroll !== false)
  ) {
    lockDocumentScroll()
    return
  }

  unlockDocumentScroll()
}

function lockDocumentScroll() {
  const body = document.body
  if (!body || body.dataset.modalScrollLock === "true") return

  lockedScrollY = window.scrollY
  body.style.inlineSize = getComputedStyle(body).inlineSize
  body.dataset.modalScrollLock = "true"
  body.style.position = "fixed"
  body.style.inset = "0"
  body.style.top = `-${lockedScrollY}px`
  // Pinning the body drags the sticky nav off with the scrolled-away page;
  // the nav offsets itself by this to stay where it was.
  body.style.setProperty("--lc-scroll-lock-y", `${lockedScrollY}px`)
}

function unlockDocumentScroll() {
  const body = document.body
  if (body?.dataset.modalScrollLock !== "true") return

  body.style.position = ""
  body.style.inset = ""
  body.style.top = ""
  body.style.removeProperty("--lc-scroll-lock-y")
  body.style.inlineSize = ""
  delete body.dataset.modalScrollLock
  window.scrollTo({ top: lockedScrollY, behavior: "instant" })
  lockedScrollY = 0
}
