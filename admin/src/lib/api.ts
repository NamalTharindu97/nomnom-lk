export const API_BASE = process.env.NEXT_PUBLIC_API_URL || "/api/v1"

export class ApiError extends Error {
  status: number
  code?: string
  details?: unknown

  constructor(status: number, message: string, details?: unknown, code?: string) {
    super(message)
    this.status = status
    this.code = code
    this.details = details
  }
}

let refreshPromise: Promise<boolean> | null = null

function readCookie(name: string) {
  if (typeof document === "undefined") return null
  const prefix = `${encodeURIComponent(name)}=`
  const value = document.cookie.split("; ").find((cookie) => cookie.startsWith(prefix))
  return value ? decodeURIComponent(value.slice(prefix.length)) : null
}

function redirectToLogin() {
  if (typeof window !== "undefined" && window.location.pathname !== "/login") {
    window.location.href = "/login"
  }
}

async function parseError(res: Response) {
  const body = await res.json().catch(() => ({}))
  const code = body.error?.code
  const message = code === "PORTFOLIO_DEMO_READ_ONLY"
    ? "This recruiter demo is read only. Explore freely without changing data."
    : body.error?.message || res.statusText
  return new ApiError(
    res.status,
    message,
    body.error?.details,
    code
  )
}

async function refreshBrowserSession() {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      const csrfToken = readCookie("nomnom_csrf")
      if (!csrfToken) return false
      const res = await fetch(`${API_BASE}/auth/browser/refresh`, {
        method: "POST",
        credentials: "include",
        headers: { "X-CSRF-Token": csrfToken },
      })
      return res.ok
    })().finally(() => {
      refreshPromise = null
    })
  }
  return refreshPromise
}

async function request<T>(path: string, options: RequestInit = {}, canRetry = true): Promise<T> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  }

  if (options.body instanceof FormData) {
    delete headers["Content-Type"]
  }

  const method = (options.method || "GET").toUpperCase()
  if (!["GET", "HEAD", "OPTIONS"].includes(method)) {
    const csrfToken = readCookie("nomnom_csrf")
    if (csrfToken) headers["X-CSRF-Token"] = csrfToken
  }

  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    credentials: "include",
    headers,
  })

  const isBrowserAuth = path.startsWith("/auth/browser/")
  if (res.status === 401 && canRetry && !["/auth/browser/login", "/auth/browser/demo", "/auth/browser/refresh"].includes(path)) {
    if (await refreshBrowserSession()) {
      return request<T>(path, options, false)
    }
    redirectToLogin()
    throw new ApiError(401, "Session expired. Please login again.")
  }

  if (!res.ok) {
    const error = await parseError(res)
    if (error.status === 401 && !isBrowserAuth) redirectToLogin()
    throw error
  }

  if (res.status === 204) return undefined as T
  return res.json()
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "POST", body: body === undefined ? undefined : JSON.stringify(body) }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PUT", body: body === undefined ? undefined : JSON.stringify(body) }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
  upload: <T>(path: string, formData: FormData) =>
    request<T>(path, { method: "POST", body: formData }),
}
