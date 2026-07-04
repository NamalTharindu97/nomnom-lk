"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Trash2, Search, Users, Plus } from "lucide-react"
import UserDialog from "./_user-dialog"

interface User {
  id: string
  email: string
  name: string
  role: string
  is_active: boolean
  created_at: string
}

const PER_PAGE = 10
const ROLES = ["user", "restaurant_owner", "admin"]
const ROLE_FILTERS = ["all", "user", "restaurant_owner", "admin"]

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [search, setSearch] = useState("")
  const [roleFilter, setRoleFilter] = useState("all")
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null)
  const [showUserDialog, setShowUserDialog] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(PER_PAGE),
      })
      if (search.trim()) params.set("email", search.trim())
      if (roleFilter !== "all") params.set("role", roleFilter)
      const res = await api.get<{ data: User[]; pagination: { total: number } }>(
        `/users?${params}`
      )
      setUsers(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setUsers([])
    } finally {
      setLoading(false)
    }
  }, [page, search, roleFilter])

  useEffect(() => { load() }, [load])
  useEffect(() => { setPage(1) }, [search, roleFilter])

  async function handleRoleChange(userId: string, newRole: string) {
    try {
      await api.put(`/users/${userId}`, { role: newRole })
      notify("User role updated", "success")
      load()
    } catch {}
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await api.delete(`/users/${deleteTarget.id}`)
      notify("User deleted", "success")
      setDeleteTarget(null)
      load()
    } catch {}
  }

  const roleBadge = (role: string) => {
    const variants: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
      admin: "default",
      restaurant_owner: "secondary",
      user: "outline",
    }
    return <Badge variant={variants[role] || "outline"}>{role}</Badge>
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Users</h1>
            <p className="text-muted-foreground">Manage platform users</p>
          </div>
          <Button onClick={() => setShowUserDialog(true)}>
            <Plus className="mr-2 size-4" />
            New User
          </Button>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <CardTitle>All Users</CardTitle>
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    placeholder="Search by email..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-48 pl-8"
                  />
                </div>
                <Select value={roleFilter} onValueChange={setRoleFilter}>
                  <SelectTrigger className="w-32">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {ROLE_FILTERS.map((r) => (
                      <SelectItem key={r} value={r}>{r === "all" ? "All Roles" : r.charAt(0).toUpperCase() + r.slice(1)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Role</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableSkeleton columns={6} />
                ) : users.length === 0 ? (
                  <EmptyState
                    icon={<Users className="size-10 text-muted-foreground/50" />}
                    title="No users found"
                    description={search ? "Try adjusting your search." : "No users have registered yet."}
                  />
                ) : (
                  users.map((u) => (
                    <TableRow key={u.id}>
                      <TableCell className="font-medium">{u.name}</TableCell>
                      <TableCell>{u.email}</TableCell>
                      <TableCell>
                        <Select
                          value={u.role}
                          onValueChange={(v) => handleRoleChange(u.id, v)}
                        >
                          <SelectTrigger className="h-8 w-36">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {ROLES.map((r) => (
                              <SelectItem key={r} value={r}>{r}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                      <TableCell>
                        <Badge variant={u.is_active ? "default" : "destructive"}>
                          {u.is_active ? "Active" : "Disabled"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {new Date(u.created_at).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button size="icon" variant="ghost" onClick={() => setDeleteTarget(u)}>
                              <Trash2 className="size-4 text-destructive" />
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Delete User</AlertDialogTitle>
                              <AlertDialogDescription>
                                Are you sure you want to delete <strong>{u.name}</strong> ({u.email})? This action cannot be undone.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel onClick={() => setDeleteTarget(null)}>Cancel</AlertDialogCancel>
                              <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                                Delete
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
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
      <UserDialog
        open={showUserDialog}
        onClose={() => setShowUserDialog(false)}
        onSaved={load}
      />
    </ErrorBoundary>
  )
}
