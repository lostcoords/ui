import { Controller } from "@hotwired/stimulus"

// Escape hides a visible tooltip without moving the pointer or focus. It shows
// again after the pointer leaves or focus moves away.
export default class extends Controller {
  dismiss(event) {
    if (event.key !== "Escape" || !this.element.matches(":hover, :focus-within")) return
    this.element.dataset.dismissed = ""
  }

  reset() {
    delete this.element.dataset.dismissed
  }
}
