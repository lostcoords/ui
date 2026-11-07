import { Controller } from "@hotwired/stimulus"

// The preview's sections are panels on one page, so the dock's links switch panels instead of visiting pages.
export default class extends Controller {
  static targets = ["panel", "status", "projects", "notes", "draft"]

  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.hash.slice(1))
  }

  home(event) {
    event.preventDefault()
    this.open("projects")
  }

  // Clicking the dock link moves its indicator and shows the panel.
  open(id) {
    this.element.querySelector(`[data-slot=dock] a[href="#${id}"]`)?.click()
  }

  show(id) {
    for (const panel of this.panelTargets) panel.hidden = panel.id !== id
  }

  add({ params: { destination } }) {
    const draft = this.draftTarget.content.cloneNode(true)
    const title = destination === "projects" ? "Untitled project" : "A new thought"
    draft.querySelector("[data-draft-title]").textContent = title
    const list = destination === "projects" ? this.projectsTarget : this.notesTarget
    list.prepend(draft)
    this.open(destination)
    this.statusTarget.textContent = `${title} added. Your next idea starts here.`
  }
}
