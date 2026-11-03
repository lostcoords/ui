import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  toggle() {
    const expanded = this.element.toggleAttribute("data-expanded")
    this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    this.toggleTarget.textContent = expanded ? "Show less code" : "Show all code"
  }

  copyFailed() {
    this.element.toggleAttribute("data-expanded", true)
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "true")
      this.toggleTarget.textContent = "Show less code"
    }
  }
}
