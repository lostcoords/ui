import { Controller } from "@hotwired/stimulus"
import { registerDialog, showDialog } from "lostcoords/ui/helpers/dialog"

// Opens a dialog whose body is a Turbo frame fetched on open. It reloads on every
// open, so what it shows is never staler than the page that opened it.
export default class extends Controller {
  static targets = ["dialog", "frame"]

  disconnect() {
    this.unregisterDialog?.()
  }

  // A stream that replaces an open dialog sends no close event, and the page would stay locked.
  dialogTargetDisconnected() {
    this.unregisterDialog?.()
    this.unregisterDialog = null
  }

  open(event) {
    event?.preventDefault()
    if (this.hasFrameTarget) {
      if (this.frameTarget.src) this.frameTarget.reload()
      else this.frameTarget.src = this.frameTarget.dataset.src
    }
    showDialog(this.dialogTarget)

    this.unregisterDialog = registerDialog(this.dialogTarget)
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }
}
