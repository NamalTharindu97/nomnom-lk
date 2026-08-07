import { act, renderHook, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"
import { api } from "@/lib/api"
import { AuthProvider, useAuth } from "./use-auth"

const push = vi.fn()
const replace = vi.fn()

vi.mock("next/navigation", () => ({
  useRouter: () => ({ push, replace }),
}))

vi.mock("@/lib/api", () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const viewer = {
  id: "viewer-id",
  email: "recruiter-demo@nomnomlk.com",
  name: "Recruiter Demo",
  role: "portfolio_viewer" as const,
}

describe("AuthProvider recruiter demo", () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it("derives explicit viewer and read-only state from the browser session", async () => {
    vi.mocked(api.get).mockResolvedValue({ user: viewer, read_only: true })

    const { result } = renderHook(() => useAuth(), { wrapper: AuthProvider })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(result.current.user).toEqual(viewer)
    expect(result.current.isViewer).toBe(true)
    expect(result.current.isReadOnly).toBe(true)
    expect(result.current.isAdmin).toBe(false)
    expect(result.current.isOwner).toBe(false)
  })

  it("starts a demo session without credentials and preserves logout", async () => {
    vi.mocked(api.get).mockRejectedValue(new Error("No session"))
    vi.mocked(api.post)
      .mockResolvedValueOnce({ user: viewer, expires_in: 1800 })
      .mockResolvedValueOnce(undefined)

    const { result } = renderHook(() => useAuth(), { wrapper: AuthProvider })
    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await act(() => result.current.demoLogin())
    expect(api.post).toHaveBeenNthCalledWith(1, "/auth/browser/demo")
    expect(result.current.isViewer).toBe(true)
    expect(result.current.isReadOnly).toBe(true)

    await act(() => result.current.logout())
    expect(api.post).toHaveBeenNthCalledWith(2, "/auth/browser/logout")
    expect(result.current.user).toBeNull()
    expect(push).toHaveBeenCalledWith("/login")
  })

  it("does not let a stale anonymous session check clear a completed demo login", async () => {
    let rejectSession!: (reason: Error) => void
    vi.mocked(api.get).mockReturnValue(new Promise((_, reject) => {
      rejectSession = reject
    }))
    vi.mocked(api.post).mockResolvedValue({ user: viewer, expires_in: 1800 })

    const { result } = renderHook(() => useAuth(), { wrapper: AuthProvider })

    await act(() => result.current.demoLogin())
    await act(async () => rejectSession(new Error("Anonymous session finished late")))

    expect(result.current.user).toEqual(viewer)
    expect(result.current.isViewer).toBe(true)
    expect(result.current.isReadOnly).toBe(true)
    expect(result.current.isLoading).toBe(false)
  })
})
