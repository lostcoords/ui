import { Controller } from "@hotwired/stimulus"
import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"
import { hidePopoverAfterExit } from "lostcoords/ui/helpers/top_layer"

// A popover the gem rendered as popover="auto", made manual when it connects so that every close is
// the gem's and plays the exit, which Safari skips when the browser closes a popover itself: a tap
// outside, Escape, a popovertarget button that hides it and a [data-lc-popover-close] element in it.
// Without JavaScript it stays a native auto popover.
export default class extends Controller {
  connect() {
    if (!this.element.matches(":popover-open")) this.element.popover = "manual"
    this.onToggle = (event) => (event.newState === "open" ? this.opened() : this.closed())
    this.onPointerDown = this.onPointerDown.bind(this)
    this.onClick = this.onClick.bind(this)
    this.element.addEventListener("toggle", this.onToggle)
    if (this.element.matches(":popover-open")) this.opened()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle)
    this.closed()
  }

  hide() {
    return hidePopoverAfterExit(this.element)
  }

  opened() {
    this.element.removeAttribute("data-closing")
    if (this.unregister) return
    document.addEventListener("pointerdown", this.onPointerDown, true)
    document.addEventListener("click", this.onClick, true)
    this.unregister = registerDismissable({
      element: this.element,
      type: "popover",
      close: () => this.hide(),
      isOpen: () => this.element.matches(":popover-open:not([data-closing])"),
    })
  }

  closed() {
    document.removeEventListener("pointerdown", this.onPointerDown, true)
    document.removeEventListener("click", this.onClick, true)
    this.unregister?.()
    this.unregister = null
  }

  // The popover's own buttons toggle it on click, so a press on one is not a press outside.
  onPointerDown(event) {
    if (this.element.contains(event.target) || this.invoker(event.target)) return
    this.hide()
  }

  onClick(event) {
    const invoker = this.invoker(event.target)
    if (invoker) {
      if (invoker.getAttribute("popovertargetaction") === "show") return
      event.preventDefault()
      this.hide()
    } else if (
      event.target.closest?.("[data-lc-popover-close]") &&
      this.element.contains(event.target)
    ) {
      this.hide()
    }
  }

  invoker(target) {
    const button = target.closest?.("[popovertarget]")
    return button?.popoverTargetElement === this.element ? button : null
  }
}
