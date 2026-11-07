import { Controller } from "@hotwired/stimulus"

// Hides the dock while the on-screen keyboard is open, so it doesn't cover the field being typed in.
export default class extends Controller {
  connect() {
    this.viewportHandler = () => this.keyboard()
    window.visualViewport?.addEventListener("resize", this.viewportHandler)
  }

  disconnect() {
    window.visualViewport?.removeEventListener("resize", this.viewportHandler)
  }

  keyboard() {
    const typing = document.activeElement?.matches(
      "input, textarea, select, [contenteditable]:not([contenteditable=false])",
    )
    const inset = window.innerHeight - (window.visualViewport?.height ?? window.innerHeight)
    this.element.toggleAttribute("data-keyboard", Boolean(typing) && inset > 150)
  }
}
