import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  toggle() {
    this.setExpanded(!this.element.hasAttribute("data-expanded"))
  }

  copyFailed() {
    this.setExpanded(true)
  }

  setExpanded(expanded) {
    this.element.toggleAttribute("data-expanded", expanded)
    if (!this.hasToggleTarget) return

    this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    this.toggleTarget.textContent = expanded
      ? this.toggleTarget.dataset.collapseLabel
      : this.toggleTarget.dataset.expandLabel
  }
}
