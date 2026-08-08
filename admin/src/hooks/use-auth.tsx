"use client"

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from "react"
import { useRouter } from "next/navigation"
import { api } from "@/lib/api"

interface User {
  id: string
  email: string
  name: string
  role: string
}

type ImpersonationUser = User

interface SessionResponse {
  user: User
  impersonated_by?: string
}

interface AuthContext {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  isLoading: boolean
  isAdmin: boolean
  isOwner: boolean
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
  const router = useRouter()

  useEffect(() => {
    let active = true
    api.get<SessionResponse>("/auth/browser/session")
      .then((session) => {
        if (!active) return
        setUser(session.user)
        setImpersonatedBy(session.impersonated_by || null)
        setImpersonatedUser(session.impersonated_by ? session.user : null)
      })
      .catch(() => {
        if (!active) return
        setUser(null)
        setImpersonatedBy(null)
        setImpersonatedUser(null)
      })
      .finally(() => {
        if (active) setIsLoading(false)
      })
    return () => {
      active = false
    }
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.post<{ user: User }>("/auth/browser/login", { email, password })
    setUser(res.user)
    setImpersonatedBy(null)
    setImpersonatedUser(null)
  }, [])

  const logout = useCallback(async () => {
    try {
      await api.post<void>("/auth/browser/logout")
    } finally {
      setUser(null)
      setImpersonatedBy(null)
      setImpersonatedUser(null)
      router.push("/login")
    }
  }, [router])

  const impersonate = useCallback(async (userId: string) => {
    const res = await api.post<{ user: User; impersonated_by: string }>("/admin/impersonate", {
      user_id: userId,
    })
    setUser(res.user)
    setImpersonatedBy(res.impersonated_by)
    setImpersonatedUser(res.user)
    router.replace("/dashboard")
  }, [router])

  const stopImpersonating = useCallback(async () => {
    const res = await api.post<{ user: User }>("/admin/impersonate/stop")
    setUser(res.user)
    setImpersonatedBy(null)
    setImpersonatedUser(null)
    router.replace("/dashboard")
  }, [router])

  const isAdmin = user?.role === "admin" && !impersonatedBy
  const isOwner = user?.role === "restaurant_owner"

  return (
    <AuthCtx.Provider
      value={{
        user,
        login,
        logout,
        isLoading,
        isAdmin,
        isOwner,
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
