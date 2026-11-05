import { Controller } from "@hotwired/stimulus"
import { confirm } from "lostcoords/ui/helpers/confirm"

// Stands in for Turbo, which calls Turbo.config.forms.confirm before it submits.
export default class extends Controller {
  async submit(event) {
    event.preventDefault()
    const accepted = await confirm(this.element.dataset.turboConfirm, this.element, event.submitter)
    this.element.dataset.confirmed = accepted
  }
}
