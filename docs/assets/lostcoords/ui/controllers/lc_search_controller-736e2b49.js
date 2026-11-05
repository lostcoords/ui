import { Controller } from "@hotwired/stimulus"
import { registerDialog } from "lostcoords/ui/helpers/dialog"
import { prefersReducedMotion } from "lostcoords/ui/helpers/viewport"

// Full-screen search. Each query dispatches lc-search:query with { query, results }; a listener
// that calls preventDefault fills results itself. Otherwise the controller asks the server
// (src) for the results HTML, or filters the rows already rendered by their text.
export default class extends Controller {
  static targets = [
    "trigger",
    "dialog",
    "stack",
    "bar",
    "glyph",
    "input",
    "clear",
    "cancel",
    "panel",
    "results",
    "result",
    "empty",
    "status",
  ]
  static values = { src: String, param: { type: String, default: "q" }, one: String, other: String }

  connect() {
    this.animations = []
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.resultsTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer.disconnect()
    clearTimeout(this.timeout)
    this.request?.abort()
    this.returnFocus = null
    this.reset()
  }

  // ⌘K / Ctrl+K comes from lc-shortcut: it presses the trigger while search is closed
  // and refocuses the field while it is open.
  open() {
    if (this.closing) return
    if (this.dialogTarget.open) return this.inputTarget.focus()
    this.returnFocus =
      document.activeElement === document.body ? this.triggerTarget : document.activeElement
    this.element.dataset.open = ""
    this.dialogTarget.showModal()
    this.unregisterDialog = registerDialog(this.dialogTarget, { close: () => this.close() })
    this.inputTarget.focus({ preventScroll: true })
    this.inputTarget.select()
    if (this.searched !== this.query) this.search()
    this.refresh()
    this.grow()
  }

  close() {
    if (!this.dialogTarget.open || this.closing) return
    this.closing = true
    this.fade()
    Promise.allSettled(this.animations.map((animation) => animation.finished)).then(() =>
      this.reset(),
    )
  }

  // Also runs before Turbo caches the page, so a restored page never shows search open.
  reset() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    this.dialogTarget.close()
    this.unregisterDialog?.()
    this.unregisterDialog = null
    this.closing = false
    delete this.element.dataset.open
  }

  closed() {
    this.reset()
    this.returnFocus?.focus({ preventScroll: true })
    this.returnFocus = null
  }

  // A click on the backdrop closes search, and so does choosing a result, which matters for
  // links within the page and Turbo visits that keep it.
  dismiss(event) {
    if (event.target.hasAttribute("data-lc-search-dismiss")) this.close()
    else if (event.target.closest?.("[data-slot=search-result]")) this.close()
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.input()
  }

  input(event) {
    if (event?.isComposing) return
    this.clearTarget.hidden = !this.inputTarget.value
    clearTimeout(this.timeout)
    // The server answers each query, so it waits for a pause in typing.
    if (this.srcValue) this.timeout = setTimeout(() => this.search(), 150)
    else this.search()
  }

  submit(event) {
    event.preventDefault()
    this.openFirst()
  }

  navigate(event) {
    if (event.isComposing || event.keyCode === 229) return
    if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return
    event.preventDefault()
    const items = [this.inputTarget, ...this.visibleResults()]
    const index = items.indexOf(document.activeElement)
    const step = event.key === "ArrowDown" ? 1 : -1
    items[Math.min(Math.max(index + step, 0), items.length - 1)].focus()
  }

  get query() {
    return this.inputTarget.value.normalize("NFKC").trim()
  }

  search() {
    const query = this.query
    this.searched = query
    const event = this.dispatch("query", {
      detail: { query, results: this.resultsTarget },
      cancelable: true,
    })
    if (event.defaultPrevented) return
    if (this.srcValue) this.load(query)
    else this.filter(query)
  }

  load(query) {
    this.request?.abort()
    const request = new AbortController()
    this.request = request
    const url = new URL(this.srcValue, location.href)
    url.searchParams.set(this.paramValue, query)
    this.loading = fetch(url, { headers: { Accept: "text/html" }, signal: request.signal })
      .then((response) => {
        if (!response.ok) throw new Error(`${url} answered ${response.status}`)
        return response.text()
      })
      .then((html) => {
        if (this.request !== request) return
        this.resultsTarget.innerHTML = html
        this.loaded = query
      })
      .catch((error) => {
        if (error.name !== "AbortError") console.error(error)
      })
    return this.loading
  }

  filter(query) {
    const words = query.toLowerCase().split(/\s+/).filter(Boolean)
    for (const result of this.resultTargets) {
      const text = `${result.dataset.lcSearchKeywords ?? ""} ${result.textContent}`
        .normalize("NFKC")
        .toLowerCase()
      result.hidden = !words.every((word) => text.includes(word))
    }
    this.refresh()
  }

  // Enter in the field opens the top result; while the server is still answering a newer
  // query, it waits for that answer.
  openFirst() {
    clearTimeout(this.timeout)
    if (this.srcValue && this.loaded !== this.query) {
      const query = this.query
      if (this.searched !== query) this.search()
      this.loading?.then(() => this.loaded === query && this.openFirst())
      return
    }
    this.visibleResults()[0]?.click()
  }

  visibleResults() {
    return this.resultTargets.filter((result) => result.checkVisibility())
  }

  // Groups without a visible result hide, the empty note shows for a query with no results,
  // and the status announces the count.
  refresh() {
    for (const group of this.resultsTarget.querySelectorAll("[data-slot=search-group]")) {
      group.hidden = ![...group.querySelectorAll("[data-slot=search-result]")].some(
        (result) => !result.hidden,
      )
    }
    const count = this.resultTargets.filter(
      (result) => !result.hidden && !result.closest("[hidden]"),
    ).length
    const query = this.query
    this.emptyTarget.hidden = count > 0 || !query
    this.panelTarget.hidden = count === 0 && this.emptyTarget.hidden
    this.statusTarget.textContent = query
      ? (count === 1 ? this.oneValue : this.otherValue).replace("%{count}", count)
      : ""
  }

  // The bar grows out of the trigger and the glyph slides from the trigger's icon to its
  // place in the field; the rest fades in behind it.
  grow() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    if (prefersReducedMotion()) return
    const from = this.triggerTarget.getBoundingClientRect()
    const to = this.barTarget.getBoundingClientRect()
    const glyph = this.glyphTarget.getBoundingClientRect()
    const icon = this.triggerTarget.querySelector("svg").getBoundingClientRect()
    const insetY = Math.max((to.height - from.height) / 2, 0)
    const shiftY = from.top + from.height / 2 - (to.top + to.height / 2)
    const timing = { duration: 420, easing: "cubic-bezier(0.16, 1, 0.3, 1)", fill: "both" }
    const fade = [
      { opacity: 0, translate: "0 -0.5rem" },
      { opacity: 1, translate: "0 0" },
    ]
    this.animations = [
      this.barTarget.animate(
        [
          {
            clipPath: `inset(${insetY}px ${Math.max(to.right - from.right, 0)}px ${insetY}px ${Math.max(from.left - to.left, 0)}px round 999px)`,
            translate: `0 ${shiftY}px`,
          },
          { clipPath: "inset(-1.5rem round 999px)", translate: "0 0" },
        ],
        timing,
      ),
      this.glyphTarget.animate(
        [
          { translate: `${icon.left + (icon.width - glyph.width) / 2 - glyph.left}px 0` },
          { translate: "0 0" },
        ],
        timing,
      ),
      this.inputTarget.animate([{ opacity: 0 }, { opacity: 1 }], { ...timing, delay: 120 }),
      this.panelTarget.animate(fade, { ...timing, delay: 60 }),
      this.cancelTarget.animate(fade, timing),
      this.dialogTarget.animate([{ opacity: 0 }, { opacity: 1 }], {
        ...timing,
        pseudoElement: "::backdrop",
      }),
    ]
  }

  // Closing doesn't play the opening back into the trigger: the overlay just fades.
  fade() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    if (prefersReducedMotion()) return
    const timing = { duration: 160, easing: "ease-out", fill: "both" }
    this.animations = [
      this.stackTarget.animate([{ opacity: 1 }, { opacity: 0 }], timing),
      this.dialogTarget.animate([{ opacity: 1 }, { opacity: 0 }], {
        ...timing,
        pseudoElement: "::backdrop",
      }),
    ]
  }
}
