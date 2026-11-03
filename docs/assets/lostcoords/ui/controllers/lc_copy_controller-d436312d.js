import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]
  static values = { value: String, source: String, resetAfter: Number }

  connect() {
    this.reset()
  }

  disconnect() {
    clearTimeout(this.resetTimer)
    this.request = null
  }

  async copy() {
    if (this.request || this.buttonTarget.disabled) return

    clearTimeout(this.resetTimer)
    this.reset()
    const request = Symbol()
    this.request = request
    this.buttonTarget.setAttribute("aria-busy", "true")

    try {
      let text = this.valueValue
      if (this.hasSourceValue) {
        const source = document.getElementById(this.sourceValue)
        if (!source) throw new Error("Copy source not found")
        text = source.matches("input, textarea") ? source.value : source.textContent
      }
      await navigator.clipboard.writeText(text)
      if (this.request !== request) return
      this.element.dataset.state = "copied"
      this.statusTarget.textContent = this.statusTarget.dataset.copied
      this.dispatch("copied", { detail: { text } })
    } catch (error) {
      if (this.request !== request) return
      this.element.dataset.state = "error"
      this.statusTarget.textContent = this.statusTarget.dataset.error
      this.dispatch("error", { detail: { error } })
    } finally {
      if (this.request === request) {
        this.request = null
        this.buttonTarget.removeAttribute("aria-busy")
        this.resetTimer = setTimeout(() => this.reset(), this.resetAfterValue)
      }
    }
  }

  reset() {
    this.element.dataset.state = "idle"
    this.statusTarget.textContent = ""
    this.buttonTarget.removeAttribute("aria-busy")
  }
}
