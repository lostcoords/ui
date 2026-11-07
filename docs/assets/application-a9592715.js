import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

// Pages come from a static site, so the bar can show sooner than the 500ms default.
Turbo.config.drive.progressBarDelay = 100

// Turbo 8 visits and re-renders the page for a link to an anchor on the same page, which drops state
// such as a search query or an open sheet. The browser scrolls to those anchors on its own.
document.addEventListener("turbo:click", (event) => {
  const url = new URL(event.detail.url)
  if (url.hash && url.pathname === location.pathname && url.search === location.search) {
    event.preventDefault()
  }
})
