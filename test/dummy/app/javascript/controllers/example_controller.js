import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "toggle", "copy", "status"]

  disconnect() {
    clearTimeout(this.copyTimer)
  }

  preventSubmit(event) {
    if (event.target.method !== "dialog") event.preventDefault()
  }

  toggle() {
    this.codeTarget.hidden = !this.codeTarget.hidden
    this.toggleTarget.setAttribute("aria-expanded", String(!this.codeTarget.hidden))
  }

  copy() {
    this.copyText(this.codeTarget.textContent, this.copyTarget)
  }

  copyBehavior({ currentTarget }) {
    this.copyText(
      currentTarget.closest("details").querySelector("pre code").textContent,
      currentTarget,
    )
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
      this.codeTarget.hidden = false
      this.toggleTarget.setAttribute("aria-expanded", "true")
      this.statusTarget.textContent = "Select the code to copy it."
    }
  }
}
