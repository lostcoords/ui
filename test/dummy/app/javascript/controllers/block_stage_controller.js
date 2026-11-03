import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "width"]

  resize({ currentTarget }) {
    const mobile = currentTarget.dataset.width === "mobile"
    this.frameTarget.style.maxWidth = mobile ? "390px" : ""
    for (const button of this.widthTargets) {
      button.setAttribute("aria-pressed", String(button === currentTarget))
    }
  }
}
