"use client"

import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { useAuth } from "@/hooks/use-auth"
import { useTheme } from "@/contexts/theme-context"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { ImpersonationBanner } from "@/components/impersonation-banner"
import {
  LayoutDashboard,
  Store,
  Tag,
  Bell,
  Users,
  LogOut,
  Menu,
  UtensilsCrossed,
  Sun,
  Moon,
  Monitor,
  ScrollText,
  Settings,
  FileText,
  Ticket,
  Folder,
  UserCheck,
  Image as ImageIcon,
} from "lucide-react"
import { useEffect, useState } from "react"

const adminNavItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/restaurants", label: "Restaurants", icon: Store },
  { href: "/dashboard/offers", label: "Offers", icon: Tag },
  { href: "/dashboard/users", label: "Users", icon: Users },
  { href: "/dashboard/owners", label: "Owners", icon: UserCheck },
  { href: "/dashboard/notifications", label: "Push Notifications", icon: Bell },
  { href: "/dashboard/notification-templates", label: "Templates", icon: FileText },
  { href: "/dashboard/coupons", label: "Coupons", icon: Ticket },
  { href: "/dashboard/categories", label: "Categories", icon: Folder },
  { href: "/dashboard/banners", label: "Banners", icon: ImageIcon },
  { href: "/dashboard/audit-log", label: "Audit Log", icon: ScrollText },
  { href: "/dashboard/settings", label: "Settings", icon: Settings },
]

const ownerNavItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/dashboard/restaurants", label: "My Restaurants", icon: Store },
  { href: "/dashboard/offers", label: "My Offers", icon: Tag },
  { href: "/dashboard/banners", label: "My Banners", icon: ImageIcon },
  { href: "/dashboard/settings", label: "Settings", icon: Settings },
]

const themeOptions = [
  { value: "light" as const, icon: Sun, label: "Light" },
  { value: "dark" as const, icon: Moon, label: "Dark" },
  { value: "system" as const, icon: Monitor, label: "System" },
]

function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  const pathname = usePathname()
  const { user, logout, isImpersonating, impersonatedUser } = useAuth()
  const { theme, setTheme } = useTheme()

  const navItems = user?.role === "admin" ? adminNavItems : ownerNavItems

  return (
    <>
      {open && <div className="fixed inset-0 z-40 bg-foreground/20 lg:hidden" onClick={onClose} />}
      <aside
        className={`fixed top-0 left-0 z-50 flex h-full w-64 flex-col bg-sidebar border-r border-sidebar-border transition-transform duration-200 lg:static lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        } ${isImpersonating ? "border-l-4 border-l-primary" : ""}`}
      >
        <div className="flex h-14 items-center gap-2 px-6 border-b border-sidebar-border">
          <UtensilsCrossed className="size-5 text-sidebar-primary" />
          <span className="font-semibold text-sidebar-foreground">NomNom LK</span>
        </div>

        <nav className="flex-1 overflow-y-auto p-3 space-y-0.5">
          {navItems.map((item) => {
            const Icon = item.icon
            const active = pathname === item.href
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                  active
                    ? "bg-sidebar-primary text-sidebar-primary-foreground"
                    : "text-sidebar-foreground/80 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
                }`}
              >
                <Icon className="size-4 shrink-0" />
                {item.label}
              </Link>
            )
          })}
        </nav>

        <Separator className="bg-sidebar-border" />

        <div className="p-3">
          <div className="flex items-center gap-1 rounded-lg bg-sidebar-accent/50 p-1">
            {themeOptions.map((opt) => {
              const Icon = opt.icon
              const active = theme === opt.value
              return (
                <button
                  key={opt.value}
                  onClick={() => setTheme(opt.value)}
                  className={`flex flex-1 items-center justify-center gap-1.5 rounded-md px-2 py-1.5 text-xs font-medium transition-colors ${
                    active
                      ? "bg-sidebar-primary text-sidebar-primary-foreground shadow-sm"
                      : "text-sidebar-foreground/60 hover:text-sidebar-foreground"
                  }`}
                >
                  <Icon className="size-3.5" />
                  <span className="hidden sm:inline">{opt.label}</span>
                </button>
              )
            })}
          </div>
        </div>

        {isImpersonating && impersonatedUser && (
          <>
            <Separator className="bg-sidebar-border" />
            <div className="p-3">
              <div className="flex items-center gap-2 rounded-lg bg-primary/10 px-3 py-2">
                <UserCheck className="size-4 text-primary shrink-0" />
                <div className="text-xs text-sidebar-foreground min-w-0">
                  <p className="font-medium text-primary truncate">Viewing as</p>
                  <p className="truncate text-sidebar-foreground/70">{impersonatedUser.name}</p>
                </div>
              </div>
            </div>
          </>
        )}

        <Separator className="bg-sidebar-border" />

        <div className="p-3 flex items-center justify-between gap-2">
          <div className="flex items-center gap-3 min-w-0">
            <Avatar className="size-8 shrink-0">
              <AvatarFallback className="bg-sidebar-primary text-sidebar-primary-foreground text-xs">
                {user?.name?.charAt(0)?.toUpperCase() || "A"}
              </AvatarFallback>
            </Avatar>
            <div className="text-sm text-sidebar-foreground min-w-0">
              <p className="font-medium truncate">{user?.name}</p>
              <p className="text-xs text-sidebar-foreground/60 capitalize truncate">{user?.role}</p>
            </div>
          </div>
          <Button variant="ghost" size="icon" onClick={logout} className="text-sidebar-foreground/60 hover:text-destructive shrink-0">
            <LogOut className="size-4" />
          </Button>
        </div>
      </aside>
    </>
  )
}

const adminOnlyPaths = [
  "/dashboard/users",
  "/dashboard/owners",
  "/dashboard/notifications",
  "/dashboard/notification-templates",
  "/dashboard/coupons",
  "/dashboard/categories",
  "/dashboard/audit-log",
]

function DashboardLayoutInner({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth()
  const pathname = usePathname()
  const router = useRouter()
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const isForbiddenPath = Boolean(
    user && user.role !== "admin" && adminOnlyPaths.some((p) => pathname.startsWith(p))
  )

  useEffect(() => {
    if (!isLoading && !user) {
      router.push("/login")
      return
    }

    if (isForbiddenPath) {
      router.replace("/dashboard")
    }
  }, [user, isLoading, router, isForbiddenPath])

  if (isLoading || !user || isForbiddenPath) return null

  return (
    <div className="flex min-h-screen">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex-1 flex flex-col min-w-0">
          <header className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background px-4 lg:px-6">
            <Button
              variant="ghost"
              size="icon"
              className="lg:hidden"
              onClick={() => setSidebarOpen(true)}
            >
              <Menu className="size-5" />
            </Button>
            <div className="flex-1" />
          </header>
          <ImpersonationBanner />
          <main className="flex-1 overflow-y-auto p-4 lg:p-6">{children}</main>
      </div>
    </div>
  )
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return <DashboardLayoutInner>{children}</DashboardLayoutInner>
}
