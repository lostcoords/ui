import { Controller } from "@hotwired/stimulus"
import { isEditable } from "lostcoords/ui/helpers/roving_focus"
import { ariaKeyShortcuts, registerShortcut } from "lostcoords/ui/helpers/shortcuts"

// Binds page-wide keys to the element: a field takes focus and selects its
// text, anything else is clicked. The element announces its keys through
// aria-keyshortcuts. See helpers/shortcuts.js for the key syntax.
export default class extends Controller {
  static values = { keys: String }

  // Stimulus keeps values across a reconnect (a moved or permanent element)
  // without calling keysValueChanged again, so connect registers too.
  connect() {
    this.register()
  }

  keysValueChanged() {
    if (this.connected) this.register()
  }

  register() {
    this.connected = true
    this.unregister?.()
    this.unregister = null
    if (!this.keysValue) return

    this.element.setAttribute("aria-keyshortcuts", ariaKeyShortcuts(this.keysValue))
    this.unregister = registerShortcut(this.element, this.keysValue, () => this.run())
  }

  disconnect() {
    this.connected = false
    this.unregister?.()
    this.unregister = null
  }

  run() {
    if (isEditable(this.element)) {
      this.element.focus()
      this.element.select?.()
    } else {
      this.element.click()
    }
  }
}
