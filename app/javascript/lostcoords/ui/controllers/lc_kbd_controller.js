import { Controller } from "@hotwired/stimulus"
import { formatShortcut } from "lostcoords/ui/helpers/shortcuts"

// Shows a key hint in the platform's own notation: "mod+k" reads ⌘ K on
// Apple platforms. The server renders the Ctrl form, which stays without JS.
export default class extends Controller {
  static values = { keys: String }

  keysValueChanged() {
    if (this.keysValue) this.element.textContent = formatShortcut(this.keysValue)
  }
}
