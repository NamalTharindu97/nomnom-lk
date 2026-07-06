"use client"

import { useAuth } from "@/hooks/use-auth"
import { Button } from "@/components/ui/button"
import { UserCheck, LogOut } from "lucide-react"

export function ImpersonationBanner() {
  const { isImpersonating, impersonatedUser, stopImpersonating } = useAuth()

  if (!isImpersonating || !impersonatedUser) return null

  return (
    <div className="flex items-center justify-between gap-4 border-b border-primary/20 bg-primary/5 px-4 py-2 lg:px-6">
      <div className="flex items-center gap-2 text-sm">
        <UserCheck className="size-4 text-primary" />
        <span>
          Viewing as <strong>{impersonatedUser.name}</strong> ({impersonatedUser.email})
        </span>
      </div>
      <Button variant="outline" size="sm" onClick={stopImpersonating} className="gap-1.5">
        <LogOut className="size-3.5" />
        Back to Admin
      </Button>
    </div>
  )
}
