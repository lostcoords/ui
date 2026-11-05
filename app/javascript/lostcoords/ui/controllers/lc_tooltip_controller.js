import { Controller } from "@hotwired/stimulus"
import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"
import { liftToTopLayer, onPageLeave } from "lostcoords/ui/helpers/top_layer"

// Opens the tooltip in the top layer, so no stacking context or overflow clip
// covers it. Without the Popover API it stays in place. Escape closes it before
// any menu or dialog around it, and it stays hidden until the pointer leaves
// and focus moves away.
export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.stopPageLeave = onPageLeave(() => this.close({ immediate: true }))
  }

  disconnect() {
    this.stopPageLeave?.()
    this.close({ immediate: true })
  }

  show(event) {
    if (event.type === "focusin" && !event.target.matches(":focus-visible")) return
    if (this.release || this.element.hasAttribute("data-dismissed")) return

    this.element.toggleAttribute("data-open", true)
    this.release = liftToTopLayer(this.contentTarget, this.element)
    this.unregister = registerDismissable({
      type: "tooltip",
      element: this.element,
      isOpen: () => this.element.hasAttribute("data-open"),
      close: () => this.dismiss(),
    })
  }

  hide() {
    if (this.element.matches(":hover") || this.element.querySelector(":focus-visible")) return

    delete this.element.dataset.dismissed
    this.close()
  }

  dismiss() {
    this.element.dataset.dismissed = ""
    this.close({ immediate: true })
  }

  close({ immediate = false } = {}) {
    this.element.toggleAttribute("data-open", false)
    this.release?.({ immediate })
    this.release = null
    this.unregister?.()
    this.unregister = null
  }
}
