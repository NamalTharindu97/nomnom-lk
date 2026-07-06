"use client"

import { useAuth } from "@/hooks/use-auth"
import { AccessDenied } from "@/components/access-denied"

interface RoleGuardProps {
  allowedRoles: string[]
  children: React.ReactNode
}

export function RoleGuard({ allowedRoles, children }: RoleGuardProps) {
  const { user } = useAuth()

  if (!user || !allowedRoles.includes(user.role)) {
    return <AccessDenied />
  }

  return <>{children}</>
}
