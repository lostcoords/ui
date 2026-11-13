import { Controller } from "@hotwired/stimulus"

const BREAKPOINTS = { md: "48rem", lg: "64rem", xl: "80rem", "2xl": "96rem" }

// Folds lc_sidebar to an icon rail and back, and keeps the choice in a cookie so the server renders the
// next page the same way. Below its data-rail-below breakpoint it is a rail unless the reader expanded it.
export default class extends Controller {
  static targets = ["toggle"]
  static values = { cookie: String, collapseLabel: String, expandLabel: String }

  connect() {
    const width = BREAKPOINTS[this.element.dataset.railBelow]
    this.query = width ? matchMedia(`(width < ${width})`) : null
    this.sync = () => this.label()
    this.query?.addEventListener("change", this.sync)
    this.label()
  }

  disconnect() {
    this.query?.removeEventListener("change", this.sync)
  }

  toggle() {
    const collapse = !this.rail
    this.element.toggleAttribute("data-collapsed", collapse)
    this.element.toggleAttribute("data-expanded", !collapse)
    // biome-ignore lint/suspicious/noDocumentCookie: the server reads this cookie to render the next page the same way
    document.cookie = `${encodeURIComponent(this.cookieValue)}=${collapse ? "collapsed" : "expanded"}; path=/; max-age=31536000; samesite=lax`
    this.label()
    this.dispatch("toggle", { detail: { collapsed: collapse } })
  }

  get rail() {
    if (this.element.hasAttribute("data-collapsed")) return true
    if (this.element.hasAttribute("data-expanded")) return false
    return Boolean(this.query?.matches)
  }

  label() {
    const rail = this.rail
    const label = rail ? this.expandLabelValue : this.collapseLabelValue
    for (const toggle of this.toggleTargets) {
      toggle.setAttribute("aria-label", label)
      toggle.setAttribute("title", label)
      toggle.setAttribute("aria-expanded", String(!rail))
    }
  }
}
