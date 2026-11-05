import { showContextDialog } from "lostcoords/ui/helpers/context_dialog"
import { registerDialog } from "lostcoords/ui/helpers/dialog"

const SHEET_ID = "lc-confirm-sheet"
const SHORT_LABEL = 24
const DESTRUCTIVE =
  "[data-turbo-confirm-tone=destructive], [data-variant=destructive], [data-tone=destructive]"
const MENU = "[data-lc-menu-target~=popover]"

// Turbo.config.forms.confirm = confirm. The submitter, then the form, can set
// data-turbo-confirm-description, data-turbo-confirm-accept and data-turbo-confirm-tone.
// Without an accept label, a short submitter label replaces "Confirm".
export function confirm(message, element, submitter) {
  const nodes = [submitter, element].filter((node) => node instanceof Element)
  const read = (name) => nodes.map((node) => node.dataset[name]).find(Boolean) || null
  const label = (submitter || element)?.textContent?.trim().replace(/\s+/g, " ")
  return ask(message, {
    description: read("turboConfirmDescription"),
    accept: read("turboConfirmAccept") || (label && label.length <= SHORT_LABEL ? label : null),
    destructive: nodes.some((node) => node.matches(DESTRUCTIVE)),
    anchor: nodes[0]?.closest(MENU),
  })
}

// anchor: on desktop the sheet opens beside this element, as a menu's follow-up does.
export function ask(
  message,
  { description = null, accept = null, destructive = false, anchor = null } = {},
) {
  const dialog = document.getElementById(SHEET_ID)
  if (!dialog) return Promise.resolve(window.confirm(message))
  if (dialog.open) return Promise.resolve(false)

  dialog.querySelector("[data-slot=confirm-sheet-message]").textContent = message
  const details = dialog.querySelector("[data-slot=confirm-sheet-description]")
  details.textContent = description || ""
  details.hidden = !description
  for (const button of dialog.querySelectorAll("[data-slot=confirm-sheet-accept]")) {
    const shown = (button.dataset.variant === "destructive") === destructive
    button.hidden = !shown
    button.dataset.defaultLabel ??= button.textContent.trim()
    button.textContent = (shown && accept) || button.dataset.defaultLabel
  }

  return new Promise((resolve) => {
    dialog.returnValue = ""
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), {
      once: true,
    })
    dialog.style.removeProperty("--lc-dialog-origin")
    showContextDialog(dialog, anchor)
    registerDialog(dialog, { lockScroll: false })
    // showModal focuses Cancel, and a confirm raised while typing would hand it the field's focus ring.
    // The sheet itself takes focus; Tab still reaches both buttons.
    dialog.focus({ preventScroll: true })
  })
}
