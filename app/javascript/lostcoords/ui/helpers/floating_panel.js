import { Controller } from "@hotwired/stimulus"
import { registerDismissable } from "helpers/dismiss_stack"
import { liftToTopLayer } from "helpers/top_layer"

const BEFORE_OPEN = "overlay:before-open"
const PAGE_LEAVES = ["turbo:before-cache", "turbo:before-visit", "turbo:before-render"]

export class FloatingPanel extends Controller {
  static targets = ["trigger", "popover"]
  static values = { lift: { type: Boolean, default: true } }

  static togglesHidden = false
  static closesOnOutsideClick = true

  initialize() {
    this.closeForOther = (event) => {
      if (event.detail?.source !== this) this.close()
    }
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    this.closeForPageLeave = () => this.closeNow({ immediate: true })
  }

  connect() {
    document.addEventListener(BEFORE_OPEN, this.closeForOther)
    for (const type of PAGE_LEAVES) document.addEventListener(type, this.closeForPageLeave)
    window.addEventListener("pagehide", this.closeForPageLeave)
  }

  disconnect() {
    document.removeEventListener(BEFORE_OPEN, this.closeForOther)
    for (const type of PAGE_LEAVES) document.removeEventListener(type, this.closeForPageLeave)
    window.removeEventListener("pagehide", this.closeForPageLeave)
    this.release({ immediate: true })
  }

  toggle(event) {
    event?.preventDefault()
    event?.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open(opener) {
    if (this.isOpen) return
    this.opener = opener instanceof Element ? opener : this.triggerTarget

    document.dispatchEvent(new CustomEvent(BEFORE_OPEN, { detail: { source: this } }))
    this.show()
    if (this.lifts) this.releaseLift = liftToTopLayer(this.popoverTarget, this.opener)
    this.triggerTarget.setAttribute("aria-expanded", "true")

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
    if (!this.isOpen) return

    this.hide()
    this.release({ immediate })
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.afterClose()
  }

  afterClose() {}

  release({ immediate = false } = {}) {
    this.releaseLift?.({ immediate })
    this.releaseLift = null
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
    return this.popoverTarget.hasAttribute("data-open")
  }

  get lifts() {
    return this.liftValue
  }

  get focusOnClose() {
    return this.opener
  }
}
