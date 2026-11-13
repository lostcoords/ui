import { Controller } from "@hotwired/stimulus"
import { registerDismissable } from "lostcoords/ui/helpers/dismiss_stack"
import { liftToTopLayer, onPageLeave } from "lostcoords/ui/helpers/top_layer"

const OPEN_DELAY = 450
const CLOSE_DELAY = 200

// Opens a preview card after a short hover, or at once on keyboard focus, in
// the top layer beside its trigger. With a src it loads the card's HTML the
// first time it opens. The pointer can cross the gap to the card and stay on
// it; leaving both closes it after a moment, and Escape closes it at once.
// Touch screens never open it: a tap follows the link.
export default class extends Controller {
  static targets = ["trigger", "content"]
  static values = { src: String }

  connect() {
    this.stopPageLeave = onPageLeave(() => this.close({ immediate: true }))
    this.untab()
  }

  disconnect() {
    this.stopPageLeave?.()
    this.cancelTimers()
    this.close({ immediate: true })
  }

  enter(event) {
    if (event.type === "focusin" && !event.target.matches(":focus-visible")) return
    if (event.type === "mouseenter" && !matchMedia("(hover: hover)").matches) return
    clearTimeout(this.closing)
    if (this.release || this.opening) return
    this.opening = setTimeout(() => this.open(), event.type === "focusin" ? 0 : OPEN_DELAY)
  }

  leave() {
    clearTimeout(this.opening)
    this.opening = null
    this.closing = setTimeout(() => {
      if (this.element.matches(":hover") || this.element.querySelector(":focus-visible")) return
      this.close()
    }, CLOSE_DELAY)
  }

  async open() {
    this.opening = null
    if (this.release || !this.element.isConnected) return
    if (!this.contentTarget.hasAttribute("data-loaded") && this.hasSrcValue && this.srcValue) {
      this.loading ??= this.load().finally(() => (this.loading = null))
      if (!(await this.loading) || this.release) return
      if (!this.element.matches(":hover") && !this.element.querySelector(":focus-visible")) return
    }
    this.element.toggleAttribute("data-open", true)
    this.release = liftToTopLayer(this.contentTarget, this.triggerTarget)
    this.unregister = registerDismissable({
      type: "hovercard",
      element: this.element,
      isOpen: () => this.element.hasAttribute("data-open"),
      close: () => this.close({ immediate: true }),
    })
  }

  // Only the page's own origin can fill the card.
  async load() {
    const url = new URL(this.srcValue, window.location.href)
    if (url.origin !== window.location.origin) return false
    try {
      const response = await fetch(url, {
        headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin",
      })
      if (!response.ok) return false
      this.contentTarget.innerHTML = await response.text()
      this.untab()
      this.contentTarget.toggleAttribute("data-loaded", true)
      return true
    } catch {
      return false
    }
  }

  // The card is a preview: its links stay clickable but out of the tab order.
  untab() {
    for (const element of this.contentTarget.querySelectorAll(
      "a, button, input, select, textarea, [tabindex]",
    )) {
      element.setAttribute("tabindex", "-1")
    }
  }

  close({ immediate = false } = {}) {
    this.element.toggleAttribute("data-open", false)
    this.release?.({ immediate })
    this.release = null
    this.unregister?.()
    this.unregister = null
  }

  cancelTimers() {
    clearTimeout(this.opening)
    clearTimeout(this.closing)
    this.opening = null
  }
}
