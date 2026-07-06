"use client"

import { useEffect, useState, useCallback, useRef } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { ScrollText, Search, X } from "lucide-react"
import { Button } from "@/components/ui/button"

interface AuditEntry {
  id: string
  admin_name: string
  admin_role: string
  action: string
  entity_type: string
  entity_id: string
  details: string
  created_at: string
}

const PER_PAGE = 20

interface ActionOption { value: string; label: string }
const ACTION_OPTIONS: ActionOption[] = [
  { value: "all", label: "All Actions" },
  { value: "auth", label: "Auth" },
  { value: "restaurant", label: "Restaurant" },
  { value: "offer", label: "Offer" },
  { value: "user", label: "User" },
  { value: "notification", label: "Notification" },
  { value: "impersonate", label: "Switch Account" },
  { value: "create", label: "Create" },
  { value: "update", label: "Update" },
  { value: "delete", label: "Delete" },
  { value: "approve", label: "Approve" },
  { value: "reject", label: "Reject" },
  { value: "expire", label: "Expire" },
  { value: "bulk", label: "Bulk" },
  { value: "password_changed", label: "Password Changed" },
  { value: "login", label: "Login / Logout" },
  { value: "register", label: "Register" },
]
const ENTITY_OPTIONS = ["all", "restaurant", "offer", "user", "notification", "coupon", "category", "template", "device", "upload"]
const ROLE_OPTIONS = ["all", "admin", "restaurant_owner"]

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)

  const [actionFilter, setActionFilter] = useState("all")
  const [entityFilter, setEntityFilter] = useState("all")
  const [roleFilter, setRoleFilter] = useState("all")
  const [searchFilter, setSearchFilter] = useState("")
  const [fromDate, setFromDate] = useState("")
  const [toDate, setToDate] = useState("")

  const [searchInput, setSearchInput] = useState("")
  const debounceRef = useRef<ReturnType<typeof setTimeout>>(undefined)

  useEffect(() => {
    if (searchInput === searchFilter) return
    debounceRef.current = setTimeout(() => {
      setSearchFilter(searchInput)
      setPage(1)
    }, 300)
    return () => clearTimeout(debounceRef.current)
  }, [searchInput, searchFilter])

  const hasFilters = actionFilter !== "all" || entityFilter !== "all" || roleFilter !== "all" || searchFilter !== "" || fromDate !== "" || toDate !== ""

  const buildQuery = useCallback(() => {
    const params = new URLSearchParams({ page: String(page), per_page: String(PER_PAGE) })
    if (actionFilter !== "all") params.set("action", actionFilter)
    if (entityFilter !== "all") params.set("entity_type", entityFilter)
    if (roleFilter !== "all") params.set("role", roleFilter)
    if (searchFilter) params.set("search", searchFilter)
    if (fromDate) params.set("from", fromDate)
    if (toDate) params.set("to", toDate)
    return params.toString()
  }, [page, actionFilter, entityFilter, roleFilter, searchFilter, fromDate, toDate])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: AuditEntry[]; pagination: { total: number } }>(
        `/admin/audit-log?${buildQuery()}`
      )
      setLogs(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setLogs([])
    } finally {
      setLoading(false)
    }
  }, [buildQuery])

  useEffect(() => { load() }, [load])

  const clearFilters = () => {
    setActionFilter("all")
    setEntityFilter("all")
    setRoleFilter("all")
    setSearchInput("")
    setSearchFilter("")
    setFromDate("")
    setToDate("")
    setPage(1)
  }

  const actionBadge = (action: string) => {
    const colors: Record<string, string> = {
      create: "text-success",
      update: "text-info",
      delete: "text-destructive",
      approve: "text-success",
      reject: "text-destructive",
      expire: "text-amber-500",
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
            <div className="flex flex-wrap gap-3 mt-2">
              <Select value={actionFilter} onValueChange={(v) => { setActionFilter(v); setPage(1) }}>
                <SelectTrigger className="w-44">
                  <SelectValue placeholder="Action" />
                </SelectTrigger>
                <SelectContent>
                  {ACTION_OPTIONS.map((a) => (
                    <SelectItem key={a.value} value={a.value}>{a.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={entityFilter} onValueChange={(v) => { setEntityFilter(v); setPage(1) }}>
                <SelectTrigger className="w-36">
                  <SelectValue placeholder="Entity" />
                </SelectTrigger>
                <SelectContent>
                  {ENTITY_OPTIONS.map((e) => (
                    <SelectItem key={e} value={e}>{e === "all" ? "All Entities" : e.charAt(0).toUpperCase() + e.slice(1)}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={roleFilter} onValueChange={(v) => { setRoleFilter(v); setPage(1) }}>
                <SelectTrigger className="w-36">
                  <SelectValue placeholder="Role" />
                </SelectTrigger>
                <SelectContent>
                  {ROLE_OPTIONS.map((r) => (
                    <SelectItem key={r} value={r}>{r === "all" ? "All Roles" : r === "admin" ? "Admin" : "Owner"}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search all logs..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  className="w-44 pl-8"
                />
              </div>
              <Input
                type="date"
                value={fromDate}
                onChange={(e) => { setFromDate(e.target.value); setPage(1) }}
                className="w-36"
                placeholder="From"
              />
              <Input
                type="date"
                value={toDate}
                onChange={(e) => { setToDate(e.target.value); setPage(1) }}
                className="w-36"
                placeholder="To"
              />
              {hasFilters && (
                <Button variant="ghost" size="sm" onClick={clearFilters} className="h-9">
                  <X className="size-4 mr-1" />
                  Clear
                </Button>
              )}
            </div>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="whitespace-nowrap">Admin</TableHead>
                  <TableHead className="w-20 whitespace-nowrap">Role</TableHead>
                  <TableHead className="whitespace-nowrap">Action</TableHead>
                  <TableHead className="whitespace-nowrap">Entity</TableHead>
                  <TableHead className="whitespace-nowrap">Details</TableHead>
                  <TableHead className="whitespace-nowrap">Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableSkeleton columns={6} />
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
                      <TableCell className="text-sm text-muted-foreground capitalize">{l.admin_role || "—"}</TableCell>
                      <TableCell>{actionBadge(l.action)}</TableCell>
                      <TableCell className="text-sm">
                        {l.entity_type}
                        {l.entity_id && <span className="text-muted-foreground ml-1">#{l.entity_id.slice(0, 8)}</span>}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground min-w-[200px] max-w-md whitespace-normal break-words">
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
            </div>

            <PaginationBar page={page} perPage={PER_PAGE} total={total} onPageChange={setPage} />
          </CardContent>
        </Card>
      </div>
    </ErrorBoundary>
  )
}
