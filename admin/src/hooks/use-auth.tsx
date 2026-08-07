"use client"

import { createContext, useContext, useState, useEffect, useCallback, useRef, type ReactNode } from "react"
import { useRouter } from "next/navigation"
import { api } from "@/lib/api"
import { isPortfolioViewer, type DashboardRole } from "@/lib/dashboard-access"

interface User {
  id: string
  email: string
  name: string
  role: DashboardRole
}

type ImpersonationUser = User

interface SessionResponse {
  user: User
  impersonated_by?: string
  read_only?: boolean
}

interface AuthContext {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  demoLogin: () => Promise<void>
  logout: () => Promise<void>
  isLoading: boolean
  isAdmin: boolean
  isOwner: boolean
  isViewer: boolean
  isReadOnly: boolean
  isImpersonating: boolean
  impersonatedBy: string | null
  impersonatedUser: ImpersonationUser | null
  impersonate: (userId: string) => Promise<void>
  stopImpersonating: () => Promise<void>
}

const AuthCtx = createContext<AuthContext | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [impersonatedUser, setImpersonatedUser] = useState<ImpersonationUser | null>(null)
  const [impersonatedBy, setImpersonatedBy] = useState<string | null>(null)
  const [sessionReadOnly, setSessionReadOnly] = useState(false)
  const authVersion = useRef(0)
  const router = useRouter()

  useEffect(() => {
    let active = true
    const version = authVersion.current
    api.get<SessionResponse>("/auth/browser/session")
      .then((session) => {
        if (!active || version !== authVersion.current) return
        setUser(session.user)
        setImpersonatedBy(session.impersonated_by || null)
        setImpersonatedUser(session.impersonated_by ? session.user : null)
        setSessionReadOnly(session.read_only === true)
      })
      .catch(() => {
        if (!active || version !== authVersion.current) return
        setUser(null)
        setImpersonatedBy(null)
        setImpersonatedUser(null)
        setSessionReadOnly(false)
      })
      .finally(() => {
        if (active && version === authVersion.current) setIsLoading(false)
      })
    return () => {
      active = false
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    authVersion.current += 1
    try {
      const res = await api.post<{ user: User }>("/auth/browser/login", { email, password })
      setUser(res.user)
      setImpersonatedBy(null)
      setImpersonatedUser(null)
      setSessionReadOnly(false)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const demoLogin = useCallback(async () => {
    authVersion.current += 1
    try {
      const res = await api.post<{ user: User; expires_in: number }>("/auth/browser/demo")
      setUser(res.user)
      setImpersonatedBy(null)
      setImpersonatedUser(null)
      setSessionReadOnly(true)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(async () => {
    authVersion.current += 1
    try {
      await api.post<void>("/auth/browser/logout")
    } finally {
      setUser(null)
      setImpersonatedBy(null)
      setImpersonatedUser(null)
      setSessionReadOnly(false)
      router.push("/login")
    }
  }, [router])

  const impersonate = useCallback(async (userId: string) => {
    authVersion.current += 1
    const res = await api.post<{ user: User; impersonated_by: string }>("/admin/impersonate", {
      user_id: userId,
    })
    setUser(res.user)
    setImpersonatedBy(res.impersonated_by)
    setImpersonatedUser(res.user)
    setSessionReadOnly(false)
    router.replace("/dashboard")
  }, [router])

  const stopImpersonating = useCallback(async () => {
    authVersion.current += 1
    const res = await api.post<{ user: User }>("/admin/impersonate/stop")
    setUser(res.user)
    setImpersonatedBy(null)
    setImpersonatedUser(null)
    setSessionReadOnly(false)
    router.replace("/dashboard")
  }, [router])

  const isAdmin = user?.role === "admin" && !impersonatedBy
  const isOwner = user?.role === "restaurant_owner"
  const isViewer = isPortfolioViewer(user?.role)
  const isReadOnly = sessionReadOnly || isViewer

  return (
    <AuthCtx.Provider
      value={{
        user,
        login,
        demoLogin,
        logout,
        isLoading,
        isAdmin,
        isOwner,
        isViewer,
        isReadOnly,
        isImpersonating: !!impersonatedBy,
        impersonatedBy,
        impersonatedUser,
        impersonate,
        stopImpersonating,
      }}
    >
      {children}
    </AuthCtx.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthCtx)
  if (!ctx) throw new Error("useAuth must be used within AuthProvider")
  return ctx
}

export function requireAuth(user: User | null, isLoading: boolean) {
  if (isLoading) return true
  return !user
}
