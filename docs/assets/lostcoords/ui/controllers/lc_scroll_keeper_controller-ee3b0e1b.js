import { Controller } from "@hotwired/stimulus"

// Keeps a scroll container's position across Turbo visits and reloads, such as
// a sidebar that every page renders again. Positions live in sessionStorage
// under the key value, so containers that share a key share a position.
// Without a saved position, the current link scrolls into view instead.
export default class extends Controller {
  static values = { key: String }

  connect() {
    this.save = () => this.store()
    document.addEventListener("turbo:before-render", this.save)
    window.addEventListener("pagehide", this.save)

    const saved = Number.parseFloat(this.read())
    if (Number.isFinite(saved)) this.element.scrollTop = saved
    else this.reveal(this.element.querySelector('[aria-current="page"]'))
  }

  disconnect() {
    document.removeEventListener("turbo:before-render", this.save)
    window.removeEventListener("pagehide", this.save)
  }

  // scrollIntoView would also scroll the page, so only the container moves.
  reveal(link) {
    if (!link) return
    const frame = this.element.getBoundingClientRect()
    const box = link.getBoundingClientRect()
    if (box.top >= frame.top && box.bottom <= frame.bottom) return
    this.element.scrollTop += box.top - frame.top - (frame.height - box.height) / 2
  }

  get storageKey() {
    return `lostcoords-ui:scroll:${this.keyValue || this.element.id || "default"}`
  }

  read() {
    try {
      return sessionStorage.getItem(this.storageKey)
    } catch {
      return null
    }
  }

  store() {
    // A hidden container reports 0 and would overwrite the visible one's position.
    if (!this.element.offsetParent) return
    try {
      sessionStorage.setItem(this.storageKey, String(this.element.scrollTop))
    } catch {}
  }
}
