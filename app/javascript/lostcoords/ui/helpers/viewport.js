const SHEET_QUERY = "(width < 40rem)"
const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)"

export const TEXT_ENTRY =
  "textarea, [contenteditable]:not([contenteditable=false]), input:not([type=button], [type=submit], [type=reset], [type=checkbox], [type=radio], [type=range], [type=color], [type=file], [type=image], [type=hidden])"

export function isSheetViewport() {
  return window.matchMedia(SHEET_QUERY).matches
}

export function prefersReducedMotion() {
  return window.matchMedia(REDUCED_MOTION_QUERY).matches
}
