"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { ScrollText } from "lucide-react"

interface AuditEntry {
  id: string
  admin_name: string
  action: string
  entity_type: string
  entity_id: string
  details: string
  created_at: string
}

const PER_PAGE = 20

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: AuditEntry[]; pagination: { total: number } }>(
        `/admin/audit-log?page=${page}&per_page=${PER_PAGE}`
      )
      setLogs(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setLogs([])
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => { load() }, [load])

  const actionBadge = (action: string) => {
    const colors: Record<string, string> = {
      create: "text-green-600",
      update: "text-blue-600",
      delete: "text-destructive",
      approve: "text-green-600",
      reject: "text-destructive",
    }
    return <span className={`font-medium ${colors[action] || "text-muted-foreground"}`}>{action}</span>
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Audit Log</h1>
          <p className="text-muted-foreground">Track admin actions across the platform</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Activity History</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Admin</TableHead>
                  <TableHead>Action</TableHead>
                  <TableHead>Entity</TableHead>
                  <TableHead>Details</TableHead>
                  <TableHead>Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableSkeleton columns={5} />
                ) : logs.length === 0 ? (
                  <EmptyState
                    icon={<ScrollText className="size-10 text-muted-foreground/50" />}
                    title="No audit logs"
                    description="Admin actions will appear here."
                  />
                ) : (
                  logs.map((l) => (
                    <TableRow key={l.id}>
                      <TableCell className="font-medium">{l.admin_name}</TableCell>
                      <TableCell>{actionBadge(l.action)}</TableCell>
                      <TableCell className="text-sm">
                        {l.entity_type}
                        {l.entity_id && <span className="text-muted-foreground ml-1">#{l.entity_id.slice(0, 8)}</span>}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                        {l.details || "-"}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {new Date(l.created_at).toLocaleString()}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>

            <PaginationBar page={page} perPage={PER_PAGE} total={total} onPageChange={setPage} />
          </CardContent>
        </Card>
      </div>
    </ErrorBoundary>
  )
}
