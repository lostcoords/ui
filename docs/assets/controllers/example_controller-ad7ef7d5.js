import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "toggle", "copy", "status"]

  disconnect() {
    clearTimeout(this.copyTimer)
  }

  toggle() {
    const expanded = this.element.toggleAttribute("data-expanded")
    this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    this.toggleTarget.textContent = expanded ? "Show less code" : "Show all code"
  }

  copy() {
    this.copyText(this.codeTarget.textContent, this.copyTarget)
  }

  async copyText(text, button) {
    try {
      await navigator.clipboard.writeText(text)
      if (this.copiedButton) this.copiedButton.textContent = "Copy"
      this.copiedButton = button
      button.textContent = "Copied"
      this.statusTarget.textContent = "Code copied to clipboard."
      clearTimeout(this.copyTimer)
      this.copyTimer = setTimeout(() => {
        button.textContent = "Copy"
      }, 2000)
    } catch {
      this.element.toggleAttribute("data-expanded", true)
      if (this.hasToggleTarget) {
        this.toggleTarget.setAttribute("aria-expanded", "true")
        this.toggleTarget.textContent = "Show less code"
      }
      this.statusTarget.textContent = "Select the code to copy it."
    }
  }
}
