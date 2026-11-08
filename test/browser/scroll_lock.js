async function _verifyScrollLock(page) {
  return page.evaluate(async () => {
    const { holdDocumentScroll } = await import("lostcoords/ui/helpers/dismiss_stack")
    const measure = () => {
      const rect = document.body.getBoundingClientRect()
      return { width: rect.width, top: rect.top }
    }
    const before = measure()
    const release = holdDocumentScroll()
    let locked
    try {
      locked = measure()
    } finally {
      release()
    }
    const restored = measure()

    if (locked.width !== before.width || locked.top !== before.top)
      throw new Error(`Scroll lock moved the page: ${JSON.stringify({ before, locked })}`)
    if (restored.width !== before.width || restored.top !== before.top)
      throw new Error(`Unlock moved the page: ${JSON.stringify({ before, restored })}`)

    return ["Scroll lock preserves the page width and position through locking and unlocking"]
  })
}
