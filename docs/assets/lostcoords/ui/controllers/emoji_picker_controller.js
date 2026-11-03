import { CatalogPicker } from "helpers/catalog_picker"
import { prefersReducedMotion } from "helpers/viewport"

const TONE_MODIFIERS = ["", "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"]
const TONE_STORAGE_KEY = "lostcoords_ui:emoji-picker:tone"

function markCurrent(element, current) {
  element.setAttribute("aria-current", String(current))
}

export default class extends CatalogPicker {
  static targets = [
    "input",
    "recent",
    "previewEmoji",
    "previewName",
    "tones",
    "toneToggle",
    "toneMenu",
  ]
  static values = {
    autoSubmit: Boolean,
    recentLimit: { type: Number, default: 12 },
    recentScope: String,
  }

  static optionKey = "emoji"
  static catalogClass = "emoji-picker__catalog"
  static previewTargets = ["previewEmoji", "previewName"]

  connect() {
    super.connect()
    this.tone = this.readTone()
    this.syncTones()
    this.preloadCatalog()
  }

  disconnect() {
    this.clearPopover()
    super.disconnect()
  }

  show() {
    this.refreshRecent()
    super.show()
  }

  afterClose() {
    super.afterClose()
    this.closeTones()
  }

  select(event) {
    const button = event.target.closest("button[data-emoji]")
    if (!button || !this.element.contains(button)) return

    event.preventDefault()
    event.stopPropagation()

    this.value = this.tonedValue(button)
    this.rememberRecent(this.value)
    this.defaultPreview = [this.value, button.dataset.searchName || this.value]
    this.syncOptions()
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.dispatch("changed", { detail: { value: this.value, button } })
    this.close()

    if (this.autoSubmitValue) {
      this.runAfterSheetClose(() => this.element.closest("form")?.requestSubmit())
    }
  }

  syncOptions() {
    this.inputTarget.value = this.value
    this.element.querySelectorAll("button[data-emoji]").forEach((button) => {
      markCurrent(button, this.tonedValue(button) === this.value)
    })

    const quickButton = this.quickButtons.find((button) => button.dataset.emoji === this.value)
    this.triggerTarget.textContent = quickButton
      ? this.triggerTarget.dataset.defaultLabel
      : this.value
    this.triggerTarget.dataset.value = this.value
    markCurrent(this.triggerTarget, !quickButton)
  }

  resultButton(entry) {
    const button = document.createElement("button")
    button.type = "button"
    button.dataset.emoji = entry.key
    if (entry.tone) button.dataset.tone = "true"
    button.dataset.searchName = entry.button.dataset.searchName || entry.key
    button.textContent = entry.tone ? this.applyTone(entry.key, this.tone) : entry.key
    button.title = button.dataset.searchName
    button.setAttribute("aria-label", button.dataset.searchName)
    markCurrent(button, this.tonedValue(button) === this.value)
    return button
  }

  activateCatalog(catalog) {
    super.activateCatalog(catalog)
    if (!this.isSheet && this.isOpen) this.positionPopover()
  }

  indexCatalog(catalog) {
    super.indexCatalog(catalog)
    this.applyToneToCatalog()
  }

  indexOption(button) {
    return {
      ...super.indexOption(button),
      name: (button.dataset.searchName || "").toLocaleLowerCase(),
      tone: button.dataset.tone === "true",
    }
  }

  clearPopover() {
    this.catalogElement?.remove()
    this.entries = []
  }

  observeSections() {
    this.disconnectObserver()
    if (!("IntersectionObserver" in window)) return

    this.sectionObserver = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) this.activeSection = entry.target.dataset.section
        }
        if (this.activeSection) this.setActiveTab(this.activeSection)
      },
      { root: this.bodyTarget, rootMargin: "0px 0px -80% 0px", threshold: 0 },
    )

    this.bodyTarget.querySelectorAll("[data-section]").forEach((section) => {
      this.sectionObserver.observe(section)
    })
  }

  disconnectObserver() {
    this.sectionObserver?.disconnect()
    this.sectionObserver = null
  }

  setActiveTab(key) {
    if (!this.hasTabTarget) return
    this.tabTargets.forEach((tab) => {
      markCurrent(tab, tab.dataset.targetSection === key)
    })
  }

  toggleTones(event) {
    event.preventDefault()
    event.stopPropagation()
    const open = this.toneMenuTarget.hidden
    this.toneMenuTarget.hidden = !open
    this.toneToggleTarget.setAttribute("aria-expanded", String(open))
    if (open) this.syncTones()
  }

  selectTone(event) {
    event.preventDefault()
    event.stopPropagation()
    this.tone = Number(event.currentTarget.dataset.toneIndex) || 0
    this.storeTone(this.tone)
    this.syncTones()
    this.applyToneToCatalog()
    this.retoneResults()
    this.syncOptions()
    this.closeTones()
  }

  closeTones() {
    if (!this.hasToneMenuTarget) return
    this.toneMenuTarget.hidden = true
    this.toneToggleTarget.setAttribute("aria-expanded", "false")
  }

  syncTones() {
    if (this.hasToneToggleTarget) {
      this.toneToggleTarget.textContent = `✋${TONE_MODIFIERS[this.tone]}`
    }
    if (this.hasToneMenuTarget) {
      this.toneMenuTarget.querySelectorAll("[data-tone-index]").forEach((button) => {
        markCurrent(button, Number(button.dataset.toneIndex) === this.tone)
      })
    }
  }

  applyToneToCatalog() {
    for (const entry of this.entries) {
      if (entry.tone) entry.button.textContent = this.applyTone(entry.key, this.tone)
    }
  }

  retoneResults() {
    if (!this.hasResultsGridTarget) return
    this.resultsGridTarget.querySelectorAll("button[data-tone='true']").forEach((button) => {
      button.textContent = this.applyTone(button.dataset.emoji, this.tone)
    })
  }

  tonedValue(button) {
    return this.tone && button.dataset.tone === "true"
      ? this.applyTone(button.dataset.emoji, this.tone)
      : button.dataset.emoji
  }

  applyTone(emoji, tone) {
    if (!tone) return emoji

    const codepoints = Array.from(emoji)
    const base = codepoints[0]
    const rest = codepoints.slice(1).filter((point) => point !== "️")
    return base + TONE_MODIFIERS[tone] + rest.join("")
  }

  readTone() {
    try {
      return Number(window.localStorage.getItem(TONE_STORAGE_KEY)) || 0
    } catch {
      return 0
    }
  }

  storeTone(tone) {
    try {
      window.localStorage.setItem(TONE_STORAGE_KEY, String(tone))
    } catch {}
  }

  previewFor(button) {
    const emoji = button.textContent.trim()
    return [emoji, button.dataset.searchName || emoji]
  }

  rememberRecent(emoji) {
    if (!this.recentStorageKey) return

    const recent = [emoji, ...this.recentEmojis.filter((value) => value !== emoji)].slice(
      0,
      this.recentLimitValue,
    )
    this.storeRecent(recent)
    this.renderRecent(recent)
  }

  refreshRecent() {
    if (!this.hasRecentTarget) return
    this.renderRecent(this.recentEmojis)
  }

  renderRecent(emojis) {
    if (!this.hasRecentTarget) return

    const grid = this.recentTarget.querySelector(".emoji-picker__grid")
    const count = this.recentTarget.querySelector(".count")
    if (!grid) return

    grid.replaceChildren(...emojis.map((emoji) => this.recentButton(emoji)))
    if (count) count.textContent = emojis.length
  }

  recentButton(emoji) {
    const button = document.createElement("button")
    button.type = "button"
    button.dataset.emoji = emoji
    button.dataset.search = emoji
    button.dataset.searchName = emoji
    button.title = emoji
    button.setAttribute("aria-label", emoji)
    button.textContent = emoji
    markCurrent(button, emoji === this.value)
    return button
  }

  storeRecent(emojis) {
    try {
      window.localStorage.setItem(this.recentStorageKey, JSON.stringify(emojis))
    } catch {}
  }

  positionPopover() {
    const margin = 16
    const anchorRect = this.popoverTarget.offsetParent?.getBoundingClientRect()
    if (!anchorRect) return

    const popoverWidth = this.popoverTarget.offsetWidth
    let inlineOffset = 0
    const desiredLeft = anchorRect.left
    const desiredRight = desiredLeft + popoverWidth

    if (desiredLeft < margin) inlineOffset += margin - desiredLeft
    if (desiredRight > window.innerWidth - margin)
      inlineOffset -= desiredRight - (window.innerWidth - margin)

    this.popoverTarget.style.insetInlineStart = `${inlineOffset}px`
    this.popoverTarget.style.insetInlineEnd = "auto"
  }

  resetPopoverPosition() {
    this.popoverTarget.style.insetInlineStart = ""
    this.popoverTarget.style.insetInlineEnd = ""
  }

  get value() {
    return this.inputTarget.value
  }

  set value(value) {
    this.inputTarget.value = value
  }

  get catalogAnchor() {
    return this.hasRecentTarget ? this.recentTarget : null
  }

  get sheetMotion() {
    const duration = prefersReducedMotion() ? 0 : 260
    return {
      duration,
      settle: duration && 280,
      transition: "transform 260ms var(--ease-out-expo, ease-out)",
      offscreen: "translateY(100%)",
    }
  }

  get quickButtons() {
    return Array.from(this.element.querySelectorAll(":scope > button[data-emoji]"))
  }

  get recentEmojis() {
    return [...this.storedRecent, ...this.initialRecent]
      .filter((emoji, index, emojis) => emoji && emojis.indexOf(emoji) === index)
      .slice(0, this.recentLimitValue)
  }

  get initialRecent() {
    if (!this.initialRecentValue) {
      this.initialRecentValue = this.hasRecentTarget
        ? Array.from(this.recentTarget.querySelectorAll("button[data-emoji]")).map(
            (button) => button.dataset.emoji,
          )
        : []
    }
    return this.initialRecentValue
  }

  get storedRecent() {
    if (!this.recentStorageKey) return []

    try {
      const parsed = JSON.parse(window.localStorage.getItem(this.recentStorageKey) || "[]")
      return Array.isArray(parsed) ? parsed.filter((value) => typeof value === "string") : []
    } catch {
      return []
    }
  }

  get recentStorageKey() {
    if (!this.hasRecentScopeValue || !this.recentScopeValue) return null
    return `lostcoords_ui:emoji-picker:${this.recentScopeValue}`
  }
}
