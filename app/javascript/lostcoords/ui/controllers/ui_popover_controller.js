import { FloatingPanel } from "helpers/floating_panel"

export default class extends FloatingPanel {
  toggle(event) {
    super.toggle(event)
    if (this.isOpen && event.detail === 0) {
      const selected = this.popoverTarget.querySelector(
        'input[type="radio"]:checked:not(:disabled)',
      )
      const first = this.popoverTarget.querySelector(
        'button:not(:disabled), input:not([type="hidden"]):not(:disabled), select:not(:disabled), textarea:not(:disabled), a[href], [tabindex="0"]:not(input[type="hidden"])',
      )
      const target = selected || first || this.popoverTarget
      target.focus({ preventScroll: true })
    }
  }
}
