import { Controller } from "@hotwired/stimulus"
import { registerDialog } from "lostcoords/ui/helpers/dialog"
import { prefersReducedMotion } from "lostcoords/ui/helpers/viewport"
import MiniSearch from "minisearch"

const PER_GROUP = 6
const SEARCH = {
  boost: { title: 4, keywords: 2, detail: 1.5 },
  combineWith: "AND",
  // The last word may still be half typed; longer words forgive a typo or two.
  prefix: (_term, index, terms) => index === terms.length - 1,
  fuzzy: (term) => (term.length > 3 ? 0.2 : false),
}

export default class extends Controller {
  static targets = [
    "dialog",
    "stack",
    "trigger",
    "input",
    "bar",
    "glyph",
    "cancel",
    "results",
    "list",
    "result",
    "groupTemplate",
    "resultTemplate",
    "empty",
    "clear",
    "summary",
  ]
  static values = { url: String }

  // ⌘K / Ctrl+K comes from lc-shortcut: it presses the trigger while search is
  // closed and refocuses the field while it is open.
  // The index downloads and builds while the page is idle, so the first open has it ready.
  connect() {
    this.animations = []
    this.idle = (window.requestIdleCallback ?? setTimeout)(() => this.prepare().catch(() => {}))
  }

  disconnect() {
    ;(window.cancelIdleCallback ?? clearTimeout)(this.idle)
    this.returnFocus = null
    this.reset()
  }

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
    this.filter()
    this.animate()
  }

  close() {
    if (!this.dialogTarget.open || this.closing) return
    this.closing = true
    this.fadeOut()
    Promise.allSettled(this.animations.map((animation) => animation.finished)).then(() =>
      this.reset(),
    )
  }

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

  dismiss(event) {
    if (event.target.hasAttribute("data-search-dismiss")) this.close()
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  prepare() {
    this.preparing ??= fetch(this.urlValue)
      .then((response) => {
        if (!response.ok) throw new Error(`${this.urlValue} answered ${response.status}`)
        return response.json()
      })
      .then(({ icons, documents }) => {
        this.icons = icons
        this.documents = documents.map((document, id) => ({ ...document, id }))
        this.index = new MiniSearch({ fields: ["title", "keywords", "detail", "text"] })
        this.index.addAll(this.documents)
      })
      .catch((error) => {
        this.preparing = null
        throw error
      })
    return this.preparing
  }

  filter(event) {
    if (event?.isComposing) return
    this.clearTarget.hidden = !this.inputTarget.value
    if (!this.index) {
      this.prepare()
        .then(() => this.dialogTarget.open && this.filter())
        .catch((error) => {
          this.summaryTarget.textContent = "Search could not load. Try again."
          console.error(error)
        })
      return
    }
    const query = this.inputTarget.value.normalize("NFKC").trim()
    const matches = query
      ? this.index
          .search(query, {
            ...SEARCH,
            boostDocument: (id) => titleBoost(this.documents[id].title, query),
          })
          .map((match) => ({ match, ...this.documents[match.id] }))
      : this.documents.filter((document) => document.featured)
    // Matches arrive best first, so each group appears where its best match ranks.
    const names = query
      ? [...new Set(matches.map((document) => document.group))]
      : Object.keys(this.icons)
    const groups = names.map((name) => [
      name,
      matches.filter((document) => document.group === name).slice(0, PER_GROUP),
    ])
    this.listTarget.replaceChildren(
      ...groups
        .filter(([, documents]) => documents.length)
        .map(([name, documents]) => this.renderGroup(name, documents)),
    )
    const count = groups.reduce((sum, [, documents]) => sum + documents.length, 0)
    this.emptyTarget.hidden = count > 0
    this.summaryTarget.textContent = query
      ? `${count} ${count === 1 ? "result" : "results"} for “${query}”`
      : ""
  }

  renderGroup(name, documents) {
    const group = this.groupTemplateTarget.content.firstElementChild.cloneNode(true)
    group.setAttribute("aria-label", name)
    group.querySelector("[data-field=name]").textContent = name
    group.append(...documents.map((document) => this.renderResult(document)))
    return group
  }

  // A result found by its text shows where the words appear; otherwise its one-line description.
  renderResult(document) {
    const result = this.resultTemplateTarget.content.firstElementChild.cloneNode(true)
    result.href = document.url
    result
      .querySelector("[data-field=icon]")
      .setAttribute("href", `#docs-search-${this.icons[document.group]}`)
    result.querySelector("[data-field=title]").textContent = document.title
    const fields = Object.values(document.match?.terms ? document.match.match : {}).flat()
    const detail = result.querySelector("[data-field=detail]")
    if (fields.includes("text") && !fields.includes("title")) {
      detail.replaceChildren(...excerpt(document.text, document.match.terms))
    } else {
      detail.textContent = document.detail
    }
    return result
  }

  navigate(event) {
    if (event.isComposing || event.keyCode === 229) return
    const results = this.resultTargets
    const items = [this.inputTarget, ...results]
    const index = items.indexOf(document.activeElement)
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      items[Math.min(Math.max(index + step, 0), items.length - 1)].focus()
    } else if (event.key === "Enter" && document.activeElement === this.inputTarget) {
      event.preventDefault()
      results[0]?.click()
    }
  }

  // Closing doesn't play the opening back into the trigger: the overlay just fades.
  fadeOut() {
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

  // The bar grows out of the trigger and the glyph slides from the trigger's icon
  // to its place in the field; the rest fades in behind it.
  animate() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    if (prefersReducedMotion()) return
    const from = this.triggerTarget.getBoundingClientRect()
    const to = this.barTarget.getBoundingClientRect()
    const glyph = this.glyphTarget.getBoundingClientRect()
    const icon = this.triggerTarget.querySelector("svg").getBoundingClientRect()
    const insetY = Math.max((to.height - from.height) / 2, 0)
    const shiftY = from.top + from.height / 2 - (to.top + to.height / 2)
    const timing = {
      duration: 420,
      easing: "cubic-bezier(0.16, 1, 0.3, 1)",
      fill: "both",
    }
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
      this.inputTarget.animate([{ opacity: 0 }, { opacity: 1 }], {
        ...timing,
        delay: 120,
      }),
      this.resultsTarget.animate(fade, { ...timing, delay: 60 }),
      this.cancelTarget.animate(fade, timing),
      this.dialogTarget.animate([{ opacity: 0 }, { opacity: 1 }], {
        ...timing,
        pseudoElement: "::backdrop",
      }),
    ]
  }
}

// A title that is the query, or starts with it, outranks pages that only mention it.
function titleBoost(title, query) {
  const [name, words] = [title, query].map((text) =>
    text.toLowerCase().replace(/[_-]+/g, " ").trim(),
  )
  if (name === words) return 4
  return name.startsWith(words) ? 2 : 1
}

// About a line of text around the matched words, with every one of them marked.
function excerpt(text, terms) {
  const pattern = new RegExp(`(${terms.map(escapeRegExp).join("|")})`, "giu")
  // Prefer the spot where the words appear together, as typed.
  const phrase = new RegExp(terms.map(escapeRegExp).join("\\W+"), "iu")
  const first = terms.length > 1 && phrase.test(text) ? text.search(phrase) : text.search(pattern)
  const from = first > 50 ? text.lastIndexOf(" ", first - 40) + 1 : 0
  const to = text.indexOf(" ", first + 120)
  const slice = `${from > 0 ? "…" : ""}${text.slice(from, to === -1 ? undefined : to)}${to === -1 ? "" : "…"}`
  return slice.split(pattern).map((part, index) => {
    if (index % 2 === 0) return part
    const mark = document.createElement("mark")
    mark.textContent = part
    return mark
  })
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}
