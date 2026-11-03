import { prefersReducedMotion } from "lostcoords/ui/helpers/viewport"
// The sheet beat lives in CSS (--lc-sheet-duration, --lc-ease-sheet) so CSS- and
// JS-driven slides can't drift apart. Inline transitions use the variables
// directly; timers need the duration in milliseconds.
export const SHEET_TIMING = "var(--lc-sheet-duration) var(--lc-ease-sheet)"

export function sheetDuration() {
  if (prefersReducedMotion()) return 0
  const value = getComputedStyle(document.documentElement)
    .getPropertyValue("--lc-sheet-duration")
    .trim()
  return value.endsWith("ms") ? parseFloat(value) : parseFloat(value) * 1000
}
