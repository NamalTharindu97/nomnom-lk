"use client"

import { Eye } from "lucide-react"
import { useAuth } from "@/hooks/use-auth"

export function ReadOnlyBanner() {
  const { isViewer, isReadOnly } = useAuth()
  if (!isViewer || !isReadOnly) return null

  return (
    <div
      role="status"
      aria-label="Recruiter demo read-only mode"
      className="flex items-center gap-2 border-b border-primary/30 bg-primary/10 px-4 py-2 text-sm text-foreground lg:px-6"
    >
      <Eye className="size-4 shrink-0 text-primary" aria-hidden="true" />
      <strong>Recruiter Demo - Read only</strong>
      <span className="hidden text-muted-foreground sm:inline">Explore the portfolio safely. Changes are disabled.</span>
    </div>
  )
}
