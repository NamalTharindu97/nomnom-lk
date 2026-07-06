"use client"

import { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from "react"
import { useRouter } from "next/navigation"
import { api, ApiError } from "@/lib/api"

interface User {
  id: string
  email: string
  name: string
  role: string
}

interface AuthContext {
  user: User | null
  token: string | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  isLoading: boolean
  isAdmin: boolean
  isOwner: boolean
}

const AuthCtx = createContext<AuthContext | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const storedToken = localStorage.getItem("token")
    const storedUser = localStorage.getItem("user")
    if (storedToken && storedUser) {
      setToken(storedToken)
      setUser(JSON.parse(storedUser))
    }
    setIsLoading(false)
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.post<{ access_token: string; user: User }>("/auth/login", {
      email,
      password,
    })

    const { access_token, user: userData } = res

    if (userData.role !== "admin" && userData.role !== "restaurant_owner") {
      throw new Error("Access restricted to administrators and restaurant owners only.")
    }

    localStorage.setItem("token", access_token)
    localStorage.setItem("user", JSON.stringify(userData))
    document.cookie = `token=${access_token}; path=/; max-age=86400; SameSite=Lax`
    document.cookie = `user=${JSON.stringify(userData)}; path=/; max-age=86400; SameSite=Lax`
    setToken(access_token)
    setUser(userData)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem("token")
    localStorage.removeItem("user")
    document.cookie = "token=; path=/; max-age=0"
    document.cookie = "user=; path=/; max-age=0"
    setToken(null)
    setUser(null)
    router.push("/login")
  }, [router])

  const isAdmin = user?.role === "admin"
  const isOwner = user?.role === "restaurant_owner"

  return (
    <AuthCtx.Provider value={{ user, token, login, logout, isLoading, isAdmin, isOwner }}>
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
