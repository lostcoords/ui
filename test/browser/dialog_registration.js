async function _verifyDialogRegistration(page) {
  return page.evaluate(async () => {
    const { registerDialog } = await import("lostcoords/ui/helpers/dialog")
    const closed = () =>
      new Promise((resolve) => dialog.addEventListener("close", resolve, { once: true }))
    const pressEscape = () =>
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))

    const opener = document.createElement("button")
    const dialog = document.createElement("dialog")
    dialog.style.padding = "40px"
    dialog.innerHTML = "<p>Body</p>"
    document.body.append(opener, dialog)

    let keepOpen = true
    let closes = 0
    let restored = 0
    const close = () => {
      closes++
      if (keepOpen) return false
      dialog.close()
    }
    dialog.showModal()
    const unregister = registerDialog(dialog, {
      close,
      priority: 25,
      lockScroll: false,
      restoreFocus: () => restored++,
    })
    if (registerDialog(dialog, { close }) !== unregister)
      throw new Error("A second registration replaced the first")

    pressEscape()
    if (closes !== 1 || !dialog.open || restored !== 0)
      throw new Error("close returning false did not keep the dialog open")
    if (document.body.dataset.modalScrollLock) throw new Error("lockScroll: false locked the page")

    const box = dialog.getBoundingClientRect()
    dialog.dispatchEvent(
      new MouseEvent("click", { bubbles: true, clientX: box.left + 5, clientY: box.top + 5 }),
    )
    if (closes !== 1) throw new Error("A click on the dialog's padding closed it")

    keepOpen = false
    const firstClose = closed()
    dialog.dispatchEvent(
      new MouseEvent("click", { bubbles: true, clientX: box.right + 10, clientY: box.bottom + 10 }),
    )
    if (closes !== 2 || dialog.open) throw new Error("A backdrop click did not close the dialog")
    await firstClose

    dialog.showModal()
    const again = registerDialog(dialog, { close, restoreFocus: () => restored++ })
    if (again === unregister) throw new Error("A closed dialog kept its old registration")
    const secondClose = closed()
    pressEscape()
    if (closes !== 3 || dialog.open || restored !== 1)
      throw new Error("A reopened dialog did not close and restore focus")
    await secondClose

    // Back restores a snapshot of the page taken while the dialog was open and locking scroll.
    dialog.showModal()
    const locked = registerDialog(dialog)
    const snapshot = document.body.cloneNode(true)
    document.dispatchEvent(
      new CustomEvent("turbo:before-render", { detail: { newBody: snapshot } }),
    )
    const restoredDialog = snapshot.querySelector("dialog")
    if (restoredDialog.open || "lcDialog" in restoredDialog.dataset)
      throw new Error("A restored snapshot kept its dialog open outside the top layer")
    if (snapshot.dataset.modalScrollLock || snapshot.style.position)
      throw new Error("A restored snapshot kept the page pinned")
    if (!dialog.open || !document.body.dataset.modalScrollLock)
      throw new Error("Cleaning a snapshot touched the live page")
    locked()
    dialog.close()
    if ("lcDialog" in dialog.dataset) throw new Error("An unregistered dialog kept its mark")

    // A caller that removes its dialog as it closes unregisters before the close event fires.
    // Safari doesn't focus a button on click, so nothing has focus when the dialog opens.
    document.activeElement?.blur()
    opener.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }))
    dialog.showModal()
    const removed = registerDialog(dialog)
    dialog.close()
    dialog.remove()
    removed()
    if (document.activeElement !== opener)
      throw new Error("A dialog removed as it closed did not return focus to the pressed control")

    opener.remove()
    return {
      removedDialogReturnsFocus: true,
      closeCanRefuse: true,
      paddingIgnored: true,
      backdropCloses: true,
      reopenRegisters: true,
      snapshotRestoresClosed: true,
    }
  })
}
