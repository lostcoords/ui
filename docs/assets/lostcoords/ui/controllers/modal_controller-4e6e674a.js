import { Controller } from "@hotwired/stimulus"
import { registerDialog } from "helpers/dialog"

// Opens a dialog whose body is a Turbo frame fetched on open. It reloads on every
// open, so what it shows is never staler than the page that opened it.
export default class extends Controller {
  static targets = ["dialog", "frame"]

  disconnect() {
    this.unregisterDialog?.()
  }

  open(event) {
    event?.preventDefault()
    if (this.hasFrameTarget) {
      if (this.frameTarget.src) this.frameTarget.reload()
      else this.frameTarget.src = this.frameTarget.dataset.src
    }
    if (!this.dialogTarget.open) this.dialogTarget.showModal()

    this.unregisterDialog = registerDialog(this.dialogTarget)
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }
}
