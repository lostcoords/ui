import { isEditable } from "lostcoords/ui/helpers/roving_focus"

// Browsers show the focus ring on anything focused after a key press, and Escape, Enter in a
// field and typing are key presses: a dialog opened with the mouse and closed with Escape hands
// focus back to its opener with a ring nobody asked for. Only moving focus by key counts here.
const MOVES = new Set(["Tab", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Home", "End"])
const QUIET = "data-lc-focus-quiet"
const CONTROL = "a[href], button, summary, [tabindex]"
let byKeyboard = false
let pressed = null

document.addEventListener(
  "keydown",
  (event) => {
    pressed = null
    if (event.key === "Tab" || (MOVES.has(event.key) && !isEditable(event.target)))
      byKeyboard = true
  },
  true,
)
document.addEventListener(
  "pointerdown",
  (event) => {
    byKeyboard = false
    pressed = event.target.closest?.(CONTROL) ?? null
  },
  true,
)
// A same-URL refresh morphs the page against server HTML, which never carries the mark.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.detail.attributeName === QUIET) event.preventDefault()
})

// What opened whatever is opening now: the element with focus, or the control just pressed.
// Safari on a Mac doesn't focus a button or link on click, so there the browser has nothing to
// hand focus back to when a dialog closes.
export function currentOpener(overlay) {
  const active = document.activeElement
  if (active && active !== document.body && !overlay.contains(active)) return active
  return pressed && !overlay.contains(pressed) ? pressed : null
}

// Focus goes back to opener when closing overlay left it nowhere: on the body, or still inside.
export function returnFocus(opener, overlay) {
  const active = document.activeElement
  const lost = !active || active === document.body || overlay.contains(active)
  if (lost && opener?.isConnected && opener.getClientRects().length > 0)
    opener.focus({ preventScroll: true })
}

// Call after focus has come back from a closed dialog, menu or panel. Unless the person is moving
// focus by keyboard, the element that has it keeps it without the ring until focus moves on.
// A text field always shows its ring, as it does on a click.
export function settleFocus() {
  const element = document.activeElement
  if (byKeyboard || !element || element === document.body || isEditable(element)) return

  element.setAttribute(QUIET, "")
  element.addEventListener("blur", () => element.removeAttribute(QUIET), { once: true })
}
