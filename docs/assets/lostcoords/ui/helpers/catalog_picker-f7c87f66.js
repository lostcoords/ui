import { holdDocumentScroll } from "helpers/dismiss_stack"
import { FloatingPanel } from "helpers/floating_panel"
import { SHEET_TIMING, sheetDuration } from "helpers/sheet_motion"
import { isSheetViewport } from "helpers/viewport"

const catalogs = new Map()
const MAX_RESULTS = 250

export class CatalogPicker extends FloatingPanel {
  static targets = [
    "body",
    "searchInput",
    "empty",
    "tabs",
    "tab",
    "results",
    "resultsGrid",
    "resultsCount",
    "preview",
  ]
  static values = { catalogUrl: String }

  static optionKey = "value"
  static previewTargets = []

  connect() {
    super.connect()
    this.entries = []
    this.onBodyScroll = this.onBodyScroll.bind(this)
    this.defaultPreview = this.previewFields.map((field) => field?.textContent.trim() ?? "")
  }

  disconnect() {
    this.releaseScroll?.()
    this.removeSheetGuard()
    this.disconnectObserver()
    super.disconnect()
  }

  show() {
    this.popoverTarget.hidden = false
    super.show()
    this.syncOptions()
    this.resetPreview()
    this.loadPopover()

    if (this.isSheet) {
      this.showSheet()
      this.releaseScroll ??= holdDocumentScroll()
      this.addSheetGuard()
    } else {
      this.resetPopoverPosition()
      this.positionPopover()
      this.focusSearch()
    }
  }

  close() {
    if (!this.isOpen || this.sheetClosing) return
    this.sheetClosing = true
    this.slideSheetOut(() => {
      this.sheetClosing = false
      this.closeNow()
    })
  }

  hide() {
    this.popoverTarget.style.transition = ""
    this.popoverTarget.style.transform = ""
    super.hide()
  }

  afterClose() {
    this.hideSheet()
    this.removeSheetGuard()
    this.releaseScroll?.()
    this.releaseScroll = null
    this.resetPopoverPosition()
    this.resetSearch()
    this.resetPreview()
    this.disconnectObserver()
  }

  // Slid out from JS so the close animates on every path (backdrop tap, Escape,
  // selection) and in browsers that don't honor the CSS `allow-discrete` close.
  slideSheetOut(done) {
    const pop = this.popoverTarget
    const { duration, transition, offscreen } = this.sheetMotion

    if (
      !this.isSheet ||
      !duration ||
      !this.supportsPopover ||
      !pop.matches(":popover-open") ||
      this.alreadySlidOff(pop)
    ) {
      done()
      return
    }

    let settled = false
    const finish = () => {
      if (settled) return
      settled = true
      pop.removeEventListener("transitionend", onEnd)
      done()
    }
    const onEnd = (event) => {
      if (event.target === pop && event.propertyName === "transform") finish()
    }

    pop.addEventListener("transitionend", onEnd)
    pop.style.transition = transition
    window.requestAnimationFrame(() => {
      pop.style.transform = offscreen
    })
    window.setTimeout(finish, duration + 100)
  }

  runAfterSheetClose(fn) {
    const delay = this.isSheet && this.supportsPopover ? this.sheetMotion.settle : 0
    delay ? window.setTimeout(fn, delay) : fn()
  }

  alreadySlidOff(pop) {
    const transform = window.getComputedStyle(pop).transform
    if (transform === "none") return false
    try {
      return new DOMMatrixReadOnly(transform).m42 > 8
    } catch {
      return false
    }
  }

  showSheet() {
    if (!this.supportsPopover) return

    if (this.popoverTarget.getAttribute("popover") !== "manual") {
      this.popoverTarget.setAttribute("popover", "manual")
    }
    try {
      if (!this.popoverTarget.matches(":popover-open")) this.popoverTarget.showPopover()
    } catch {}
  }

  hideSheet() {
    if (this.supportsPopover && this.popoverTarget.matches(":popover-open")) {
      try {
        this.popoverTarget.hidePopover()
      } catch {}
    } else {
      this.popoverTarget.hidden = true
    }
  }

  // A non-modal popover's ::backdrop doesn't block input, so a tap in the dimmed
  // area would activate whatever sits behind the sheet. Swallow it and close.
  addSheetGuard() {
    this.sheetGuard = (event) => {
      if (this.popoverTarget.contains(event.target)) return
      event.stopPropagation()
      if (event.type === "click") {
        event.preventDefault()
        this.close()
      }
    }
    document.addEventListener("pointerdown", this.sheetGuard, true)
    document.addEventListener("click", this.sheetGuard, true)
  }

  removeSheetGuard() {
    if (!this.sheetGuard) return
    document.removeEventListener("pointerdown", this.sheetGuard, true)
    document.removeEventListener("click", this.sheetGuard, true)
    this.sheetGuard = null
  }

  filter() {
    this.applyFilter(this.searchQuery)
  }

  onSearchKeydown(event) {
    if (event.key !== "Escape" || !this.searchQuery) return

    event.preventDefault()
    event.stopPropagation()
    this.searchInputTarget.value = ""
    this.applyFilter("")
  }

  applyFilter(query) {
    const normalizedQuery = query.toString().trim().toLocaleLowerCase()
    this.popoverTarget.toggleAttribute("data-searching", !!normalizedQuery)

    if (!normalizedQuery) {
      if (this.hasResultsTarget) this.resultsTarget.hidden = true
      if (this.hasEmptyTarget) this.emptyTarget.hidden = true
      return
    }

    const matches = []
    for (const entry of this.entries) {
      const score = this.score(entry, normalizedQuery)
      if (score > 0) matches.push({ entry, score })
    }
    matches.sort(
      (a, b) =>
        b.score - a.score ||
        Number(b.entry.popular) - Number(a.entry.popular) ||
        a.entry.name.length - b.entry.name.length,
    )

    const buttons = matches.slice(0, MAX_RESULTS).map(({ entry }) => this.resultButton(entry))
    this.resultsGridTarget.replaceChildren(...buttons)
    this.resultsCountTarget.textContent = matches.length
    this.resultsTarget.hidden = matches.length === 0
    if (this.hasEmptyTarget) this.emptyTarget.hidden = matches.length > 0
    this.bodyTarget.scrollTop = 0
  }

  score(entry, query) {
    let score = 0
    if (entry.name === query || entry.labels.includes(query)) score = 100
    else if (entry.name.startsWith(query)) score = 80
    else if (entry.labels.some((label) => label.startsWith(query))) score = 65
    else if (entry.words.some((word) => word.startsWith(query))) score = 50
    else if (entry.search.includes(query)) score = 20

    if (score > 0 && entry.popular) score += 30
    return score
  }

  focusSearch() {
    if (!this.hasSearchInputTarget) return

    window.requestAnimationFrame(() => {
      if (this.isOpen) this.searchInputTarget.focus({ preventScroll: true })
    })
  }

  resetSearch() {
    if (this.hasSearchInputTarget) this.searchInputTarget.value = ""
    this.popoverTarget.removeAttribute("data-searching")
    if (this.hasResultsTarget) this.resultsTarget.hidden = true
    if (this.hasEmptyTarget) this.emptyTarget.hidden = true
  }

  async loadPopover() {
    const existing = this.catalogElement
    if (existing) {
      this.activateCatalog(existing)
      return
    }
    if (this.loadingCatalog || !this.hasCatalogUrlValue) return

    this.loadingCatalog = true
    try {
      await this.fetchCatalog()
      const template = catalogs.get(this.catalogUrlValue)?.template
      if (!template || !this.isOpen) return

      const catalog = document.createElement("div")
      catalog.className = this.constructor.catalogClass
      catalog.dataset.pickerCatalog = ""
      catalog.appendChild(template.content.cloneNode(true))

      if (this.catalogAnchor) {
        this.catalogAnchor.insertAdjacentElement("afterend", catalog)
      } else {
        this.bodyTarget.prepend(catalog)
      }

      this.activateCatalog(catalog)
    } finally {
      this.loadingCatalog = false
    }
  }

  activateCatalog(catalog) {
    if (this.entries.length === 0) this.indexCatalog(catalog)
    this.syncOptions()
    this.observeSections()
    this.applyFilter(this.searchQuery)
  }

  indexCatalog(catalog) {
    const buttons = catalog.querySelectorAll(this.optionSelector)
    const index = catalogs.get(this.catalogUrlValue)?.index || []
    this.entries = index.map((row, i) => ({ ...row, button: buttons[i] }))
  }

  indexOption(button) {
    const key = button.dataset[this.constructor.optionKey]
    const search = (button.dataset.search || key).toLocaleLowerCase()
    return {
      key,
      name: key.toLocaleLowerCase(),
      labels: (button.dataset.searchLabels || "").toLocaleLowerCase().split("|").filter(Boolean),
      search,
      words: search.split(/\s+/).filter(Boolean),
      popular: button.dataset.popular === "true",
    }
  }

  preloadCatalog() {
    if (!this.hasCatalogUrlValue || catalogs.has(this.catalogUrlValue)) return

    catalogs.set(this.catalogUrlValue, {})
    const preload = () => this.fetchCatalog()

    if ("requestIdleCallback" in window) {
      window.requestIdleCallback(preload, { timeout: 2500 })
    } else {
      window.setTimeout(preload, 1200)
    }
  }

  fetchCatalog() {
    const url = this.catalogUrlValue
    const catalog = catalogs.get(url) || {}
    catalogs.set(url, catalog)

    catalog.request ||= fetch(url, {
      headers: { Accept: "text/html" },
      credentials: "same-origin",
    })
      .then((response) => (response.ok ? response.text() : null))
      .then((html) => {
        if (!html) return
        const template = document.createElement("template")
        template.innerHTML = html
        catalog.index = Array.from(
          template.content.querySelectorAll(this.optionSelector),
          (button) => this.indexOption(button),
        )
        catalog.template = template
      })
    return catalog.request
  }

  jumpTo(event) {
    const key = event.currentTarget.dataset.targetSection
    const section = this.bodyTarget.querySelector(`[data-section="${key}"]`)
    if (!section) return

    this.bodyTarget.scrollTop = section.offsetTop
    this.setActiveTab(key)
  }

  observeSections() {
    this.disconnectObserver()
    this.bodyTarget.addEventListener("scroll", this.onBodyScroll, { passive: true })
    this.updateActiveSectionFromScroll()
  }

  disconnectObserver() {
    if (this.hasBodyTarget) this.bodyTarget.removeEventListener("scroll", this.onBodyScroll)
    if (this.scrollFrame) window.cancelAnimationFrame(this.scrollFrame)
    this.scrollFrame = null
  }

  onBodyScroll() {
    if (this.scrollFrame) return

    this.scrollFrame = window.requestAnimationFrame(() => {
      this.scrollFrame = null
      this.updateActiveSectionFromScroll()
    })
  }

  updateActiveSectionFromScroll() {
    if (!this.hasBodyTarget || this.popoverTarget.hasAttribute("data-searching")) return

    const scrollTop = this.bodyTarget.scrollTop
    const sections = Array.from(this.bodyTarget.querySelectorAll("[data-section]")).filter(
      (section) => section.offsetParent !== null,
    )
    if (sections.length === 0) return

    const current =
      sections.findLast((section) => section.offsetTop <= scrollTop + 8) || sections[0]
    this.setActiveTab(current.dataset.section)
  }

  setActiveTab(key) {
    if (!this.hasTabTarget) return
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.targetSection === key
      if (active) tab.setAttribute("aria-current", "true")
      else tab.removeAttribute("aria-current")
      if (active) tab.scrollIntoView({ block: "nearest", inline: "nearest" })
    })
  }

  preview(event) {
    const button = event.target.closest(this.optionSelector)
    if (!button || !this.popoverTarget.contains(button)) return

    this.setPreview(this.previewFor(button))
  }

  setPreview(texts) {
    this.previewFields.forEach((field, i) => {
      if (field) field.textContent = texts[i]
    })
  }

  resetPreview() {
    this.setPreview(this.defaultPreview)
  }

  syncOptions() {}

  get catalogAnchor() {
    return null
  }

  get catalogElement() {
    return this.bodyTarget.querySelector("[data-picker-catalog]")
  }

  get optionSelector() {
    return `button[data-${this.constructor.optionKey}]`
  }

  get previewFields() {
    return this.constructor.previewTargets.map((name) => this.targets.find(name))
  }

  get sheetMotion() {
    const duration = sheetDuration()
    return {
      duration,
      settle: duration,
      transition: `transform ${SHEET_TIMING}`,
      offscreen: "translateY(var(--sheet-offscreen))",
    }
  }

  get isSheet() {
    return isSheetViewport()
  }

  get lifts() {
    return this.liftValue && !this.isSheet
  }

  get supportsPopover() {
    return typeof this.popoverTarget.showPopover === "function"
  }

  get searchQuery() {
    return this.hasSearchInputTarget ? this.searchInputTarget.value : ""
  }
}
