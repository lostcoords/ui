import { isEditable } from "lostcoords/ui/helpers/roving_focus"

// Browsers show the focus ring on anything focused after a key press, and Escape, Enter in a
// field and typing are key presses: a dialog opened with the mouse and closed with Escape hands
// focus back to its opener with a ring nobody asked for. Only moving focus by key counts here.
const MOVES = new Set(["Tab", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Home", "End"])
const QUIET = "data-lc-focus-quiet"
let byKeyboard = false

document.addEventListener(
  "keydown",
  (event) => {
    if (event.key === "Tab" || (MOVES.has(event.key) && !isEditable(event.target)))
      byKeyboard = true
  },
  true,
)
document.addEventListener(
  "pointerdown",
  () => {
    byKeyboard = false
  },
  true,
)
// A same-URL refresh morphs the page against server HTML, which never carries the mark.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.detail.attributeName === QUIET) event.preventDefault()
})

// Call after focus has come back from a closed dialog, menu or panel. Unless the person is moving
// focus by keyboard, the element that has it keeps it without the ring until focus moves on.
// A text field always shows its ring, as it does on a click.
export function settleFocus() {
  const element = document.activeElement
  if (byKeyboard || !element || element === document.body || isEditable(element)) return

  element.setAttribute(QUIET, "")
  element.addEventListener("blur", () => element.removeAttribute(QUIET), { once: true })
}
