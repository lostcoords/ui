import { Controller } from "@hotwired/stimulus"
import { showContextDialog } from "lostcoords/ui/helpers/context_dialog"
import { registerDialog } from "lostcoords/ui/helpers/dialog"

export default class extends Controller {
  static targets = ["dialog"]

  disconnect() {
    this.unregisterDialog?.()
  }

  open(event) {
    event.preventDefault()

    const dialog = this.findDialog(event.params.name)
    if (!dialog || dialog.open) return

    this.activeDialog = dialog
    if (dialog.matches(".lc-dialog-context")) {
      showContextDialog(dialog, this.element.querySelector("[data-lc-menu-target='popover']"))
    } else {
      dialog.showModal()
    }
    this.unregisterDialog?.()
    this.unregisterDialog = registerDialog(dialog)
  }

  close(event) {
    event?.preventDefault()
    const dialog = event?.target?.closest("dialog") || this.activeDialog
    dialog?.close()
  }

  findDialog(name) {
    if (!name) return this.dialogTarget

    return this.dialogTargets.find((dialog) => dialog.dataset.confirmDialogName === name)
  }
}
