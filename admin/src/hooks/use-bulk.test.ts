import { describe, it, expect } from "vitest"
import { renderHook, act } from "@testing-library/react"
import { useBulk } from "./use-bulk"

describe("useBulk", () => {
  it("starts with empty selection", () => {
    const { result } = renderHook(() => useBulk())
    expect(result.current.selected.size).toBe(0)
  })

  it("toggles individual items", () => {
    const { result } = renderHook(() => useBulk())
    act(() => result.current.toggle("a"))
    expect(result.current.selected.has("a")).toBe(true)
    act(() => result.current.toggle("a"))
    expect(result.current.selected.has("a")).toBe(false)
  })

  it("selects all items", () => {
    const { result } = renderHook(() => useBulk())
    act(() => result.current.toggleAll(["a", "b", "c"]))
    expect(result.current.selected.size).toBe(3)
    expect(result.current.selected.has("b")).toBe(true)
  })

  it("deselects all when already fully selected", () => {
    const { result } = renderHook(() => useBulk())
    act(() => result.current.toggleAll(["a", "b"]))
    expect(result.current.selected.size).toBe(2)
    act(() => result.current.toggleAll(["a", "b"]))
    expect(result.current.selected.size).toBe(0)
  })

  it("clears selection", () => {
    const { result } = renderHook(() => useBulk())
    act(() => result.current.toggleAll(["a", "b"]))
    act(() => result.current.clear())
    expect(result.current.selected.size).toBe(0)
  })
})
