import { Controller } from "@hotwired/stimulus"

// The palette picker. Opening fans one diagonal band per palette in from the
// side, each showing a copy of the page in that palette. The cuts stay fixed
// while the page scrolls under them. Choosing a band widens it over the
// viewport and applies its palette; cancelling folds the bands away again.
const SCROLL_TIMELINE = CSS.supports("animation-timeline: scroll()")
// Hovering widens a band and, less, its neighbours, like the component picker.
const HOVER_GROWTH = 1.1
const HOVER_FALLOFF = [1, 0.4, 0.19, 0.08, 0.02]

export default class extends Controller {
  static targets = ["dialog", "band", "copy", "trigger"]

  connect() {
    this.state = "closed"
    this.onScroll = () => this.syncScroll()
    this.onResize = () => this.measure()
  }

  disconnect() {
    this.teardown()
  }

  open() {
    if (this.state === "closing") return
    if (this.state !== "closed") return this.cancel()

    this.paintBands()
    this.copyPage()
    this.layout()
    this.setFates(() => "folded")
    this.dialogTarget.showModal()
    document.documentElement.toggleAttribute("data-palette-split-open", true)
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.measure()
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onResize)

    // measure() laid the bands out folded, so this change transitions.
    this.setState("opening")
    this.setFates(() => "open")
    // The current palette takes focus so the keyboard starts there, but it
    // only lights up once the pointer or the arrow keys pick a band.
    this.focusShown = false
    this.pointer = null
    this.currentChoice().focus()
    this.settle().then((settled) => {
      if (!settled) return
      this.setState("open")
      // The bands drew in under the pointer, so look again at what it rests on.
      this.layout(this.pointer ? this.bandUnder(this.pointer) : this.hovered)
    })
  }

  // Hover follows the band under the pointer only when the pointer moves.
  // Resizing slides the edges under a resting pointer, and following those
  // crossings would hand hover back and forth between neighbours.
  point({ clientX, clientY }) {
    if (this.pointer?.x === clientX && this.pointer?.y === clientY) return
    this.pointer = { x: clientX, y: clientY }
    this.hover(this.bandUnder(this.pointer))
  }

  // Hit-testing sees where the bands were before they started drawing in, so
  // while they do, the pointer's band comes from their columns instead. Each
  // edge leans by the slant, so undoing the lean at the pointer's height
  // leaves a straight split to compare with the column edges.
  bandUnder({ x, y }) {
    if (this.state === "opening") {
      const { width, height } = this.dialogTarget.getBoundingClientRect()
      const slant = Number.parseFloat(
        getComputedStyle(this.dialogTarget).getPropertyValue("--split-slant"),
      )
      const position = ((x - slant * (1 - (2 * y) / height)) / width) * 100
      return this.edges.filter((edge) => edge <= position).length
    }
    const band = document.elementFromPoint(x, y)?.closest(".palette-split-band")
    return band ? this.bandTargets.indexOf(band) : undefined
  }

  focus({ currentTarget }) {
    if (this.focusShown) this.hover(this.choiceTargets().indexOf(currentTarget))
  }

  unhover() {
    this.pointer = null
    this.hover(undefined)
  }

  // While the bands are still drawing in, hovering marks the band without
  // resizing it, so its frost and label respond at once.
  hover(index) {
    if (index === this.hovered) return
    if (this.state === "open") this.layout(index)
    else if (this.state === "opening") this.markHovered(index)
  }

  choose({ currentTarget }) {
    if (this.state !== "open" && this.state !== "opening") return
    const choices = this.choiceTargets()
    const chosen = choices.indexOf(currentTarget)
    this.setState("choosing")
    this.setFates((index) => (index < chosen ? "left" : index > chosen ? "right" : "chosen"))
    // The bands already cover the page, so the palette can change underneath.
    // Restyling the page is heavy, so it waits until the bands and label have
    // started moving.
    const id = choices[chosen].value
    requestAnimationFrame(() =>
      requestAnimationFrame(() => this.dispatch("choose", { detail: { id } })),
    )
    this.settle().then((settled) => settled && this.finish())
  }

  cancel(event) {
    event?.preventDefault()
    if (this.state !== "open" && this.state !== "opening") return
    this.setState("closing")
    this.setFates(() => "folded")
    this.settle().then((settled) => settled && this.finish())
  }

  navigate(event) {
    const choices = this.choiceTargets()
    const index = choices.indexOf(event.currentTarget)
    const next = {
      ArrowRight: index + 1,
      ArrowDown: index + 1,
      ArrowLeft: index - 1,
      ArrowUp: index - 1,
      Home: 0,
      End: choices.length - 1,
    }[event.key]
    if (next === undefined) return
    event.preventDefault()
    this.focusShown = true
    choices[(next + choices.length) % choices.length].focus()
  }

  finish() {
    this.dialogTarget.close()
    this.teardown()
    this.triggerTarget.focus()
  }

  teardown() {
    this.state = "closed"
    this.hovered = undefined
    delete this.dialogTarget.dataset.state
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onResize)
    document.documentElement.removeAttribute("data-palette-split-open")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    for (const copy of this.copyTargets) copy.replaceChildren()
    for (const band of this.bandTargets) band.removeAttribute("style")
    this.setFates(() => "folded")
  }

  // Resolves once every band transition ends, or false if another state
  // change took over meanwhile.
  async settle() {
    const state = this.state
    const transitions = this.dialogTarget
      .getAnimations({ subtree: true })
      .filter((animation) => animation instanceof CSSTransition)
    await Promise.all(transitions.map((transition) => transition.finished.catch(() => {})))
    return this.state === state
  }

  setState(state) {
    this.state = state
    this.dialogTarget.dataset.state = state
  }

  // Lays the bands out side by side, widening the hovered one. The outer
  // edges sit a slant beyond the viewport so the end bands reach its corners.
  layout(hovered) {
    const weights = this.bandTargets.map((_, index) =>
      hovered === undefined
        ? 1
        : 1 + HOVER_GROWTH * (HOVER_FALLOFF[Math.abs(index - hovered)] ?? 0),
    )
    const total = weights.reduce((sum, weight) => sum + weight, 0)
    const last = this.bandTargets.length - 1
    let start = 0
    this.edges = []
    this.bandTargets.forEach((band, index) => {
      const end = start + (weights[index] / total) * 100
      if (index < last) this.edges.push(end)
      band.style.setProperty("--from", index === 0 ? "calc(-1 * var(--split-slant))" : `${start}%`)
      band.style.setProperty("--to", index === last ? "calc(100% + var(--split-slant))" : `${end}%`)
      band.style.setProperty("--center", `${(start + end) / 2}%`)
      start = end
    })
    this.markHovered(hovered)
  }

  markHovered(hovered) {
    this.hovered = hovered
    this.bandTargets.forEach((band, index) => {
      band.toggleAttribute("data-hovered", index === hovered)
    })
  }

  setFates(fate) {
    this.bandTargets.forEach((band, index) => {
      band.dataset.fate = fate(index)
    })
  }

  choiceTargets() {
    return this.bandTargets.map((band) => band.querySelector(".palette-split-choice"))
  }

  currentChoice() {
    const current = document.documentElement.dataset.palette || "original"
    return (
      this.choiceTargets().find((choice) => choice.value === current) || this.choiceTargets()[0]
    )
  }

  // Each band gets the resolved tokens of its palette, read from the root
  // with that palette applied, so dark mode and the library default come out
  // exactly as they would on the real page.
  paintBands() {
    const root = document.documentElement
    const saved = root.dataset.palette
    const readings = this.choiceTargets().map((choice) => {
      if (choice.value === "original") delete root.dataset.palette
      else root.dataset.palette = choice.value
      const style = getComputedStyle(root)
      const tokens = new Map()
      for (const name of style)
        if (name.startsWith("--")) tokens.set(name, style.getPropertyValue(name))
      return tokens
    })
    if (saved) root.dataset.palette = saved
    else delete root.dataset.palette

    const names = [...readings[0].keys()].filter((name) =>
      readings.some((tokens) => tokens.get(name) !== readings[0].get(name)),
    )
    this.bandTargets.forEach((band, index) => {
      band.style.setProperty("--slot", index)
      for (const name of names) band.style.setProperty(name, readings[index].get(name))
    })
  }

  // Static copies: no controllers, ids, names or focus targets of their own.
  copyPage() {
    const page = document.createElement("div")
    page.className = "palette-split-page"
    let header
    for (const child of document.body.children) {
      if (
        child.matches("script, template, dialog, [role=status]") ||
        child.contains(this.dialogTarget)
      )
        continue
      if (child.matches(".lc-skip-link, [data-slot=skip-link]")) continue
      const copy = child.cloneNode(true)
      if (!header && child.matches("header")) {
        header = copy
        header.classList.add("palette-split-header")
      } else page.append(copy)
    }
    const fragment = document.createDocumentFragment()
    if (header) fragment.append(header)
    fragment.append(page)
    for (const element of fragment.querySelectorAll("*")) {
      for (const name of ["id", "name", "data-controller", "data-action", "autofocus", "popover"])
        element.removeAttribute(name)
    }
    for (const copy of this.copyTargets) copy.replaceChildren(fragment.cloneNode(true))
  }

  measure() {
    const root = document.documentElement
    const header = document.querySelector("body > header")
    const style = this.dialogTarget.style
    style.setProperty("--split-max", `${root.scrollHeight - root.clientHeight}px`)
    style.setProperty("--split-header", `${header?.offsetHeight ?? 0}px`)
    this.syncScroll()
  }

  syncScroll() {
    if (!SCROLL_TIMELINE) this.dialogTarget.style.setProperty("--split-y", `${-scrollY}px`)
    const scrolled = document.querySelector("body > header")?.hasAttribute("data-scrolled")
    for (const header of this.dialogTarget.querySelectorAll(".palette-split-header"))
      header.toggleAttribute("data-scrolled", Boolean(scrolled))
  }
}
