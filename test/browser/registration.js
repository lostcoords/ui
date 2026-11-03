async function _verifyRegistration(page) {
  return page.evaluate(async () => {
    const { registerControllers } = await import("lostcoords/ui")
    const calls = []
    const application = {
      register: (identifier, controller) => calls.push({ identifier, controller }),
    }
    try {
      registerControllers(application, { only: ["lc-copy", "unknown"] })
      throw new Error("Unknown controller accepted")
    } catch (error) {
      if (!error.message.includes("Unknown lostcoords-ui controller")) throw error
    }
    if (calls.length) throw new Error("Invalid selection partially registered")
    registerControllers(application, { only: ["lc-copy"] })
    if (calls.length !== 1 || calls[0].identifier !== "lc-copy")
      throw new Error("Selection ignored")
    registerControllers(application, { only: ["lc-copy"] })
    if (calls.length !== 1) throw new Error("Repeated registration replaced an override")
    registerControllers(application)
    const imports = JSON.parse(
      document.querySelector('script[type="importmap"]').textContent,
    ).imports
    const expected = Object.entries(imports)
      .filter(
        ([key, url]) =>
          key.startsWith("controllers/") && url.includes("lostcoords/ui/controllers/"),
      )
      .map(([key]) =>
        key
          .replace(/^controllers\//, "")
          .replace(/_controller$/, "")
          .replaceAll("_", "-")
          .replaceAll("/", "--"),
      )
      .sort()
    const actual = calls.map(({ identifier }) => identifier).sort()
    if (JSON.stringify(actual) !== JSON.stringify(expected))
      throw new Error(`Incomplete registry: ${actual}`)
    registerControllers(application)
    if (calls.length !== expected.length) throw new Error("Default registration repeated")
    return { registered: actual, selectedOnly: true, atomicValidation: true, idempotent: true }
  })
}
