import { Controller } from "@hotwired/stimulus"

// Fades the header's glass in once the page scrolls.
export default class extends Controller {
  connect() {
    this.scroll()
  }

  // An open modal pins the body, so scrollY reads 0 until it closes; the header keeps the
  // state it had rather than fading the glass out behind the dialog.
  scroll() {
    if (document.body.dataset.modalScrollLock === "true") return
    this.element.toggleAttribute("data-scrolled", window.scrollY > 8)
  }
}
