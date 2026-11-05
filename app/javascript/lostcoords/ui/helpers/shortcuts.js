import { topModalElement } from "lostcoords/ui/helpers/dismiss_stack"
import { isEditable } from "lostcoords/ui/helpers/roving_focus"

// Page-wide keyboard shortcuts. A shortcut is written as keys joined by "+",
// with "mod" for ⌘ on Apple platforms and Ctrl elsewhere: "mod+k", "/",
// "shift+?", "alt+n". Several shortcuts for one element are separated by spaces.
//
// A shortcut without mod, ctrl or alt never fires while focus is in a text
// field, so typing "/" in a field types it. While a modal dialog is open, only
// elements inside it respond. When two visible elements claim the same keys,
// the first in document order wins and the page logs a warning.

const bindings = new Set()
const warned = new Set()

export const isApple = /mac|iphone|ipad|ipod/i.test(
  navigator.userAgentData?.platform || navigator.platform || navigator.userAgent,
)

export function parseShortcuts(text) {
  return text
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((combo) => {
      const parts = combo.toLowerCase().split("+")
      const key = parts.pop() || "+"
      const modifiers = new Set(parts)
      return {
        text: combo,
        key,
        mod: modifiers.has("mod"),
        ctrl: modifiers.has("ctrl"),
        meta: modifiers.has("meta"),
        alt: modifiers.has("alt"),
        shift: modifiers.has("shift"),
      }
    })
}

export function matchesShortcut(shortcut, event) {
  const meta = shortcut.meta || (shortcut.mod && isApple)
  const ctrl = shortcut.ctrl || (shortcut.mod && !isApple)
  if (event.metaKey !== meta || event.ctrlKey !== ctrl || event.altKey !== shortcut.alt)
    return false

  // Option on a Mac turns letters into other characters (Option+N is a dead key),
  // so alt shortcuts on letters and digits match the physical key.
  if (shortcut.alt && /^[a-z0-9]$/.test(shortcut.key))
    return event.shiftKey === shortcut.shift && event.code === physicalKey(shortcut.key)

  const key = event.key.toLowerCase()
  // Shifted punctuation such as "?" already reports the shifted key.
  if (key.length === 1 && !/[a-z0-9]/.test(key)) return key === shortcut.key
  return event.shiftKey === shortcut.shift && key === shortcut.key
}

const physicalKey = (key) => (/\d/.test(key) ? `Digit${key}` : `Key${key.toUpperCase()}`)

// Shift shows unless the key is a symbol it already produces, such as "?".
const showsShift = (shortcut) => shortcut.shift && !/^[^a-z0-9]$/.test(shortcut.key)

const KEY_NAMES = {
  escape: "Esc",
  arrowup: "↑",
  arrowdown: "↓",
  arrowleft: "←",
  arrowright: "→",
  enter: "↵",
}

// "mod+k" reads "⌘ K" on Apple platforms and "Ctrl K" elsewhere.
export function formatShortcut(text) {
  return parseShortcuts(text)
    .map((shortcut) => {
      const keys = []
      if (shortcut.ctrl || (shortcut.mod && !isApple)) keys.push(isApple ? "⌃" : "Ctrl")
      if (shortcut.alt) keys.push(isApple ? "⌥" : "Alt")
      if (showsShift(shortcut)) keys.push(isApple ? "⇧" : "Shift")
      if (shortcut.meta || (shortcut.mod && isApple)) keys.push(isApple ? "⌘" : "Meta")
      keys.push(
        KEY_NAMES[shortcut.key] ||
          (shortcut.key.length === 1 ? shortcut.key.toUpperCase() : shortcut.key),
      )
      return keys.join(" ")
    })
    .join(" / ")
}

// The aria-keyshortcuts value: "mod+k" becomes "Meta+K" or "Control+K".
export function ariaKeyShortcuts(text) {
  return parseShortcuts(text)
    .map((shortcut) => {
      const keys = []
      if (shortcut.ctrl || (shortcut.mod && !isApple)) keys.push("Control")
      if (shortcut.alt) keys.push("Alt")
      if (shortcut.shift) keys.push("Shift")
      if (shortcut.meta || (shortcut.mod && isApple)) keys.push("Meta")
      keys.push(
        shortcut.key.length === 1
          ? shortcut.key.toUpperCase()
          : shortcut.key[0].toUpperCase() + shortcut.key.slice(1),
      )
      return keys.join("+")
    })
    .join(" ")
}

// Registers element for the shortcuts in text; run is called when one fires.
// Returns a function that removes the binding.
export function registerShortcut(element, text, run) {
  const binding = { element, shortcuts: parseShortcuts(text), run }
  if (bindings.size === 0) document.addEventListener("keydown", handleKeydown)
  bindings.add(binding)

  return () => {
    bindings.delete(binding)
    if (bindings.size === 0) document.removeEventListener("keydown", handleKeydown)
  }
}

function handleKeydown(event) {
  if (event.defaultPrevented || event.isComposing || event.repeat) return

  const typing = isEditable(event.target)
  const matches = [...bindings].filter(
    (binding) =>
      binding.shortcuts.some(
        (shortcut) =>
          matchesShortcut(shortcut, event) &&
          !(typing && !shortcut.mod && !shortcut.ctrl && !shortcut.meta && !shortcut.alt),
      ) && available(binding.element),
  )
  if (matches.length === 0) return

  matches.sort((a, b) =>
    a.element.compareDocumentPosition(b.element) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
  )
  if (matches.length > 1) warnConflict(event, matches)

  event.preventDefault()
  matches[0].run(event)
}

function available(element) {
  if (!element.isConnected || element.disabled || element.closest("[inert]")) return false
  if (element.getClientRects().length === 0) return false

  const modal = topModalElement()
  return !modal || modal.contains(element)
}

function warnConflict(event, matches) {
  const key = `${event.ctrlKey}${event.metaKey}${event.altKey}${event.shiftKey}${event.key}`
  if (warned.has(key)) return

  warned.add(key)
  console.warn(
    `lostcoords-ui: ${matches.length} elements share the shortcut ${event.key}; the first one runs.`,
    matches.map((binding) => binding.element),
  )
}
