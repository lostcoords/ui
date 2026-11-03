import { FloatingPanel } from "helpers/floating_panel"
import { focusFirstMenuItem, navigateMenu } from "helpers/menu_keys"

// The phone dock's action stack lays itself out over the fixed nav, so it
// passes lift: false and stays in place instead of lifting into the top layer.
export default class extends FloatingPanel {
  initialize() {
    super.initialize()
    this.focusOutHandler = this.handleFocusOut.bind(this)
    this.pointerDownHandler = this.handlePointerDown.bind(this)
    this.keydownHandler = (event) => navigateMenu(event, this.popoverTarget)
    this.focusOutSuppressed = false
    this.focusOutSuppressionTimer = null
  }

  disconnect() {
    this.clearFocusOutSuppression()
    super.disconnect()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.isOpen) return this.close()

    this.open()
    if (event.detail === 0) focusFirstMenuItem(this.popoverTarget)
  }

  toggleFromRow(event) {
    if (this.popoverTarget.contains(event.target)) return
    if (event.target.closest("a, button, input, select, textarea, [data-row-menu-ignore]")) return

    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (this.isOpen) return

    super.open()
    this.element.addEventListener("focusout", this.focusOutHandler)
    this.element.addEventListener("pointerdown", this.pointerDownHandler)
    this.popoverTarget.addEventListener("keydown", this.keydownHandler)
  }

  release(options) {
    super.release(options)
    this.element.removeEventListener("focusout", this.focusOutHandler)
    this.element.removeEventListener("pointerdown", this.pointerDownHandler)
    if (this.hasPopoverTarget)
      this.popoverTarget.removeEventListener("keydown", this.keydownHandler)
  }

  handleFocusOut(event) {
    if (this.element.contains(event.relatedTarget)) return

    queueMicrotask(() => {
      if (this.focusOutSuppressed) return
      if (!this.element.contains(document.activeElement)) this.close()
    })
  }

  handlePointerDown(event) {
    if (!this.element.contains(event.target)) return

    this.clearFocusOutSuppression()
    this.focusOutSuppressed = true
    this.focusOutSuppressionTimer = setTimeout(() => {
      this.focusOutSuppressed = false
      this.focusOutSuppressionTimer = null
    }, 0)
  }

  clearFocusOutSuppression() {
    if (this.focusOutSuppressionTimer) {
      clearTimeout(this.focusOutSuppressionTimer)
      this.focusOutSuppressionTimer = null
    }

    this.focusOutSuppressed = false
  }
}
