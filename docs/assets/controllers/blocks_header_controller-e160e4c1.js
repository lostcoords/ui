import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scroll()
  }

  scroll() {
    this.element.toggleAttribute("data-scrolled", window.scrollY > 8)
  }
}
