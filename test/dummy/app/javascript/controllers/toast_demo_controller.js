import { Controller } from "@hotwired/stimulus"

// Stands in for a Turbo Stream that appends a toast to the region.
export default class extends Controller {
  static values = { template: String, region: String }

  show() {
    const template = document.getElementById(this.templateValue)
    document.getElementById(this.regionValue)?.append(template.content.cloneNode(true))
  }
}
