"use client"

import { useState } from "react"
import { useAuth } from "@/hooks/use-auth"
import { Button } from "@/components/ui/button"
import { notify } from "@/components/ui/toast"
import { UserCheck, LogOut, Loader2 } from "lucide-react"

export function ImpersonationBanner() {
  const { isImpersonating, impersonatedUser, stopImpersonating } = useAuth()
  const [stopping, setStopping] = useState(false)

  async function handleStop() {
    setStopping(true)
    try {
      await stopImpersonating()
    } catch (error) {
      notify(error instanceof Error ? error.message : "Failed to return to the admin account", "error")
      setStopping(false)
    }
  }

  if (!isImpersonating || !impersonatedUser) return null

  return (
    <div className="flex items-center justify-between gap-4 border-b border-primary/20 bg-primary/5 px-4 py-2 lg:px-6">
      <div className="flex items-center gap-2 text-sm">
        <UserCheck className="size-4 text-primary" />
        <span>
          Viewing as <strong>{impersonatedUser.name}</strong> ({impersonatedUser.email})
        </span>
      </div>
      <Button variant="outline" size="sm" onClick={handleStop} disabled={stopping} className="gap-1.5">
        {stopping ? <Loader2 className="size-3.5 animate-spin" /> : <LogOut className="size-3.5" />}
        {stopping ? "Returning..." : "Back to Admin"}
      </Button>
    </div>
  )
}
