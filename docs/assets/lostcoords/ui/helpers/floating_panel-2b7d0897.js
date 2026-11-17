import { Controller } from "@hotwired/stimulus"
import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"
import { liftToTopLayer, onPageLeave } from "lostcoords/ui/helpers/top_layer"

const BEFORE_OPEN = "overlay:before-open"

// A panel listens to the document only while it is open, and its teardown (disconnect, a page
// leave) never reads a target. A Turbo morph moves a panel's id-carrying trigger and panel into
// another host before Stimulus disconnects the emptied one, so a target read there would throw
// and leave the rest of the teardown undone.
export class FloatingPanel extends Controller {
  static targets = ["trigger", "popover"]
  static values = { lift: { type: Boolean, default: true } }

  static togglesHidden = false
  static closesOnOutsideClick = true

  initialize() {
    this.closeForOther = (event) => {
      // A panel opened inside this one (a menu in a popover form) keeps it open.
      const source = event.detail?.source
      if (source !== this && !this.element.contains(source?.element)) this.close()
    }
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
  }

  disconnect() {
    this.closeNow({ immediate: true })
  }

  toggle(event) {
    event?.preventDefault()
    event?.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  // A host that is a whole row opens its panel from a click anywhere on the row except its controls.
  toggleFromRow(event) {
    if (this.popoverTarget.contains(event.target)) return
    if (event.target.closest("a, button, input, select, textarea, [data-lc-menu-ignore]")) return

    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open(opener) {
    if (this.isOpen) return
    this.opener = opener instanceof Element ? opener : this.triggerTarget

    document.dispatchEvent(new CustomEvent(BEFORE_OPEN, { detail: { source: this } }))
    this.show()
    if (this.lifts) this.releaseLift = liftToTopLayer(this.popoverTarget, this.opener)
    this.triggerTarget.setAttribute("aria-expanded", "true")

    document.addEventListener(BEFORE_OPEN, this.closeForOther)
    this.stopPageLeave = onPageLeave(() => this.closeNow({ immediate: true }))
    if (this.constructor.closesOnOutsideClick)
      document.addEventListener("click", this.closeOnOutsideClick)
    this.unregisterDismissable = registerDismissable({
      element: this.element,
      type: "popover",
      close: () => this.close(),
      restoreFocus: () => this.focusOnClose?.focus({ preventScroll: true }),
      isOpen: () => this.isOpen,
    })
  }

  close() {
    this.closeNow()
  }

  closeNow({ immediate = false } = {}) {
    const wasOpen = this.isOpen
    if (wasOpen) this.hide()
    this.release({ immediate })
    if (!wasOpen) return

    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", "false")
    this.afterClose()
  }

  afterClose() {}

  release({ immediate = false } = {}) {
    this.releaseLift?.({ immediate })
    this.releaseLift = null
    document.removeEventListener(BEFORE_OPEN, this.closeForOther)
    this.stopPageLeave?.()
    this.stopPageLeave = null
    document.removeEventListener("click", this.closeOnOutsideClick)
    this.unregisterDismissable?.()
    this.unregisterDismissable = null
  }

  show() {
    if (this.constructor.togglesHidden) this.popoverTarget.hidden = false
    this.popoverTarget.toggleAttribute("data-open", true)
  }

  hide() {
    this.popoverTarget.toggleAttribute("data-open", false)
    if (this.constructor.togglesHidden) this.popoverTarget.hidden = true
  }

  get isOpen() {
    return this.hasPopoverTarget && this.popoverTarget.hasAttribute("data-open")
  }

  get lifts() {
    return this.liftValue
  }

  get focusOnClose() {
    return this.opener
  }
}
