import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "panel", "indicator", "status", "projects", "notes", "draft"]

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.placeIndicator())
    this.linkTargets.forEach((link) => this.resizeObserver.observe(link))
    this.onViewportResize = () => this.keyboard()
    window.visualViewport?.addEventListener("resize", this.onViewportResize)
    this.placeIndicator()
  }

  disconnect() {
    this.resizeObserver.disconnect()
    window.visualViewport?.removeEventListener("resize", this.onViewportResize)
  }

  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.hash.slice(1))
  }

  home(event) {
    event.preventDefault()
    this.show("projects")
  }

  show(id) {
    for (const link of this.linkTargets) {
      if (link.hash === `#${id}`) link.setAttribute("aria-current", "page")
      else link.removeAttribute("aria-current")
    }
    for (const panel of this.panelTargets) panel.hidden = panel.id !== id
    this.placeIndicator()
  }

  placeIndicator() {
    const active = this.linkTargets.find((link) => link.getAttribute("aria-current") === "page")
    this.indicatorTarget.style.translate = `${active.offsetLeft}px 0`
    this.indicatorTarget.style.width = `${active.offsetWidth}px`
  }

  add({ params: { destination } }) {
    const draft = this.draftTarget.content.cloneNode(true)
    const title = destination === "projects" ? "Untitled project" : "A new thought"
    draft.querySelector("[data-draft-title]").textContent = title
    const list = destination === "projects" ? this.projectsTarget : this.notesTarget
    list.prepend(draft)
    this.show(destination)
    this.statusTarget.textContent = `${title} added. Your next idea starts here.`
  }

  keyboard() {
    const typing = document.activeElement?.matches("input, textarea, [contenteditable=true]")
    const inset = window.innerHeight - (window.visualViewport?.height ?? window.innerHeight)
    this.element.toggleAttribute("data-keyboard", typing && inset > 150)
  }
}
