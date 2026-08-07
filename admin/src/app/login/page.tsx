"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import { UtensilsCrossed, Sun, Moon, Monitor, Eye, EyeOff, Compass, ShieldCheck } from "lucide-react"
import { useAuth } from "@/hooks/use-auth"
import { useTheme } from "@/contexts/theme-context"

const themeOptions = [
  { value: "light" as const, icon: Sun, label: "Light" },
  { value: "dark" as const, icon: Moon, label: "Dark" },
  { value: "system" as const, icon: Monitor, label: "System" },
]

export default function LoginPage() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState("")
  const [demoError, setDemoError] = useState("")
  const [loading, setLoading] = useState(false)
  const [demoLoading, setDemoLoading] = useState(false)
  const { login, demoLogin } = useAuth()
  const { setTheme, resolvedTheme } = useTheme()
  const router = useRouter()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError("")
    setDemoError("")
    setLoading(true)

    try {
      await login(email, password)
      router.push("/")
    } catch (err) {
      const msg = err instanceof Error ? err.message : ""
      if (msg.includes("suspended")) {
        setError("Your account has been suspended. Contact an administrator.")
      } else {
        setError(msg || "Invalid credentials")
      }
    } finally {
      setLoading(false)
    }
  }

  async function handleDemoLogin() {
    setError("")
    setDemoError("")
    setDemoLoading(true)
    try {
      await demoLogin()
      router.push("/dashboard")
    } catch (err) {
      setDemoError(err instanceof Error ? err.message : "The recruiter demo is temporarily unavailable.")
    } finally {
      setDemoLoading(false)
    }
  }

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-start overflow-x-hidden px-4 py-6 md:justify-center">
      <div className="absolute inset-0 bg-gradient-to-b from-sidebar via-background to-background" />
      <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-primary/5 blur-3xl" />
      <div className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-primary/5 blur-3xl" />

      <div className="relative grid w-full max-w-3xl gap-4 md:grid-cols-[1fr_0.9fr]">
      <Card className="border-border/50 shadow-lg backdrop-blur-sm">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-3 flex size-12 items-center justify-center rounded-xl bg-primary">
            <UtensilsCrossed className="size-6 text-primary-foreground" />
          </div>
          <CardTitle className="text-xl">NomNom LK</CardTitle>
          <CardDescription>Sign in to your dashboard</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-4">
            <div className="grid gap-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoFocus
                required
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>
            {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
            <Button type="submit" disabled={loading || demoLoading} className="w-full">
              {loading ? "Signing in..." : "Sign in"}
            </Button>
          </form>
        </CardContent>
      </Card>

      <Card className="overflow-hidden border-primary/30 bg-primary/5 shadow-lg backdrop-blur-sm">
        <CardHeader className="pb-3">
          <div className="mb-2 flex size-10 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Compass className="size-5" aria-hidden="true" />
          </div>
          <CardTitle className="text-xl">Recruiter Demo</CardTitle>
          <CardDescription className="text-sm leading-relaxed">
            Explore the product, data model, and responsive dashboard without entering credentials.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-start gap-2 rounded-lg border border-primary/20 bg-background/70 p-3 text-sm">
            <ShieldCheck className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true" />
            <p><strong>Read only.</strong> Demo data can be viewed and filtered, but nothing can be created, edited, or deleted.</p>
          </div>
           <Button
            type="button"
            variant="outline"
            className="w-full border-primary/40 bg-background hover:bg-primary/10"
            onClick={handleDemoLogin}
            disabled={loading || demoLoading}
          >
            <Compass className="mr-2 size-4" aria-hidden="true" />
             {demoLoading ? "Opening demo..." : "Explore read-only demo"}
           </Button>
          {demoError && <p role="alert" className="text-sm text-destructive">{demoError}</p>}
          <p className="text-center text-xs text-muted-foreground">No credentials required. A short-lived demo session opens only when selected.</p>
        </CardContent>
      </Card>
      </div>

      <div className="relative mt-4 flex items-center gap-1 rounded-lg bg-background/50 border border-border p-1 backdrop-blur-sm">
        {themeOptions.map((opt) => {
          const Icon = opt.icon
          const active = resolvedTheme === opt.value
          return (
            <button
              key={opt.value}
              onClick={() => setTheme(opt.value)}
              className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-colors ${
                active
                  ? "bg-primary text-primary-foreground shadow-sm"
                  : "text-muted-foreground hover:text-foreground"
              }`}
              aria-pressed={active}
            >
              <Icon className="size-3.5" />
              {opt.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
