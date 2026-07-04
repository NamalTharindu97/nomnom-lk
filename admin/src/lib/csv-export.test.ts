import { describe, it, expect, vi, beforeEach } from "vitest"
import { csvExport } from "./csv-export"

describe("csvExport", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it("creates a CSV blob and triggers download", () => {
    const createObjectURL = vi.fn(() => "blob:test")
    const revokeObjectURL = vi.fn()
    const click = vi.fn()
    const anchor = { href: "", download: "", click } as unknown as HTMLAnchorElement

    vi.stubGlobal("URL", { createObjectURL, revokeObjectURL })
    vi.spyOn(document, "createElement").mockReturnValue(anchor)

    csvExport("test", ["Name", "Email"], [
      ["John", "john@test.com"],
      ["Jane", "jane@test.com"],
    ])

    expect(createObjectURL).toHaveBeenCalled()
    expect(click).toHaveBeenCalled()
    expect(anchor.download).toContain("test-")
    expect(revokeObjectURL).toHaveBeenCalledWith("blob:test")
  })

  it("escapes double quotes in values", () => {
    const createObjectURL = vi.fn(() => "blob:test")
    const revokeObjectURL = vi.fn()
    const click = vi.fn()
    const anchor = { href: "", download: "", click } as unknown as HTMLAnchorElement

    vi.stubGlobal("URL", { createObjectURL, revokeObjectURL })
    vi.spyOn(document, "createElement").mockReturnValue(anchor)

    csvExport("test", ["Name"], [['He said "hello"']])

    expect(click).toHaveBeenCalled()
  })

  it("handles empty data", () => {
    const createObjectURL = vi.fn(() => "blob:test")
    const revokeObjectURL = vi.fn()
    const click = vi.fn()
    const anchor = { href: "", download: "", click } as unknown as HTMLAnchorElement

    vi.stubGlobal("URL", { createObjectURL, revokeObjectURL })
    vi.spyOn(document, "createElement").mockReturnValue(anchor)

    csvExport("test", ["Col"], [])

    expect(click).toHaveBeenCalled()
  })
})
