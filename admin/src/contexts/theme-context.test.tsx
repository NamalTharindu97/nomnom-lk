import { describe, it, expect, beforeEach, vi } from "vitest"
import { renderHook, act } from "@testing-library/react"
import { ReactNode } from "react"
import { ThemeProvider, useTheme } from "./theme-context"

const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: vi.fn((key: string) => store[key] ?? null),
    setItem: vi.fn((key: string, value: string) => { store[key] = value }),
    removeItem: vi.fn((key: string) => { delete store[key] }),
    clear: () => { store = {} },
  }
})()

beforeEach(() => {
  localStorageMock.clear()
  vi.clearAllMocks()
  vi.stubGlobal("localStorage", localStorageMock)
  vi.stubGlobal("matchMedia", vi.fn(() => ({
    matches: false,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  })))
  document.documentElement.classList.remove("dark")
})

describe("ThemeContext", () => {
  function wrapper({ children }: { children: ReactNode }) {
    return <ThemeProvider>{children}</ThemeProvider>
  }

  it("defaults to system when localStorage is empty", () => {
    const { result } = renderHook(() => useTheme(), { wrapper })
    expect(result.current.theme).toBe("system")
  })

  it("switches to dark theme", () => {
    const { result } = renderHook(() => useTheme(), { wrapper })
    act(() => result.current.setTheme("dark"))
    expect(result.current.resolvedTheme).toBe("dark")
    expect(document.documentElement.classList.contains("dark")).toBe(true)
  })

  it("switches back to light from dark", () => {
    const { result } = renderHook(() => useTheme(), { wrapper })
    act(() => result.current.setTheme("dark"))
    act(() => result.current.setTheme("light"))
    expect(result.current.resolvedTheme).toBe("light")
    expect(document.documentElement.classList.contains("dark")).toBe(false)
  })
})
