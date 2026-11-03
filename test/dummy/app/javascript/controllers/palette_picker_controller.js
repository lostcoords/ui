import { FloatingPanel } from "helpers/floating_panel"

export default class extends FloatingPanel {
  open(opener) {
    super.open(opener)
    this.popoverTarget.querySelector("input:checked").focus({ preventScroll: true })
  }
}
