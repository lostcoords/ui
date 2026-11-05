import { FloatingPanel } from "lostcoords/ui/helpers/floating_panel"
import {
  focusFirstMenuItem,
  focusLastMenuItem,
  navigateMenu,
} from "lostcoords/ui/helpers/menu_keys"

// The phone dock's action stack lays itself out over the fixed nav, so it
// passes lift: false and stays in place instead of lifting into the top layer.
export default class extends FloatingPanel {
  initialize() {
    super.initialize()
    this.focusOutHandler = this.handleFocusOut.bind(this)
    this.pointerDownHandler = this.handlePointerDown.bind(this)
    this.keydownHandler = (event) => navigateMenu(event, this.popoverTarget)
    this.triggerKeydownHandler = this.handleTriggerKeydown.bind(this)
    this.focusOutSuppressed = false
    this.focusOutSuppressionTimer = null
  }

  connect() {
    super.connect()
    this.triggerTarget.addEventListener("keydown", this.triggerKeydownHandler)
  }

  disconnect() {
    this.triggerTarget.removeEventListener("keydown", this.triggerKeydownHandler)
    this.clearFocusOutSuppression()
    super.disconnect()
  }

  // Arrow Down opens the menu on its first item, Arrow Up on its last.
  handleTriggerKeydown(event) {
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return
    if (event.altKey || event.ctrlKey || event.metaKey) return

    event.preventDefault()
    this.open()
    if (event.key === "ArrowDown") focusFirstMenuItem(this.popoverTarget)
    else focusLastMenuItem(this.popoverTarget)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    if (this.isOpen) return this.close()

    this.open()
    if (event.detail === 0) focusFirstMenuItem(this.popoverTarget)
  }

  check(event) {
    const item = event.currentTarget
    const checked = item.getAttribute("aria-checked") !== "true"
    item.setAttribute("aria-checked", String(checked))
    this.dispatch("check", { target: item, detail: { checked } })
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
