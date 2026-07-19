"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import { Checkbox } from "@/components/ui/checkbox"
import { useBulk } from "@/hooks/use-bulk"
import { BulkActionBar } from "@/components/bulk-action-bar"
import { csvExport } from "@/lib/csv-export"
import { useAuth } from "@/hooks/use-auth"
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
import Link from "next/link"
import { Plus, Pencil, Trash2, Search, Store, Download } from "lucide-react"
import RestaurantDialog from "./_restaurant-dialog"

interface Restaurant {
  id: string
  name: string
  slug: string
  address: string
  cuisine_tags: string[]
  status: string
  owner_id: string
}

const PER_PAGE = 10
const STATUSES = ["all", "approved", "pending", "rejected"]

export default function RestaurantsPage() {
  const { isAdmin, isOwner } = useAuth()
  const [restaurants, setRestaurants] = useState<Restaurant[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [showDialog, setShowDialog] = useState(false)
  const [editing, setEditing] = useState<Restaurant | null>(null)
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [deleteTarget, setDeleteTarget] = useState<Restaurant | null>(null)
  const { selected, toggle, toggleAll, clear } = useBulk()

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(PER_PAGE),
        status: statusFilter,
      })
      if (search.trim()) params.set("q", search.trim())
      const res = await api.get<{ data: Restaurant[]; pagination: { total: number } }>(
        `/dashboard/restaurants?${params}`
      )
      setRestaurants(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setRestaurants([])
    } finally {
      setLoading(false)
    }
  }, [page, search, statusFilter])

  useEffect(() => { load() }, [load])

  useEffect(() => { setPage(1) }, [search, statusFilter])

  async function updateStatus(id: string, action: "approve" | "reject") {
    try {
      await api.post(`/restaurants/${id}/${action}`)
      notify(`Restaurant ${action}d`, "success")
      load()
    } catch { notify("Failed to approve/reject restaurant") }
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await api.delete(`/dashboard/restaurants/${deleteTarget.id}`)
      notify("Restaurant deleted", "success")
      setDeleteTarget(null)
      load()
    } catch { notify("Failed to delete restaurant") }
  }

  async function handleBulk(action: string) {
    const ids = Array.from(selected)
    try {
      await api.post("/admin/restaurants/bulk", { action, ids })
      notify(`${ids.length} restaurant(s) ${action}d`, "success")
      clear()
      load()
    } catch { notify("Failed to bulk action restaurants") }
  }

  async function handleBulkDelete() {
    const ids = Array.from(selected)
    try {
      await api.post("/admin/restaurants/bulk", { action: "delete", ids })
      notify(`${ids.length} restaurant(s) deleted`, "success")
      clear()
      load()
    } catch { notify("Failed to bulk delete restaurants") }
  }

  const statusBadge = (status: string) => {
    const variants: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
      approved: "default",
      pending: "secondary",
      rejected: "destructive",
    }
    return <Badge variant={variants[status] || "outline"}>{status}</Badge>
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Restaurants</h1>
            <p className="text-muted-foreground">{isOwner ? "Manage your restaurants" : "Manage restaurant listings"}</p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" onClick={() => csvExport("restaurants", ["Name", "Address", "Cuisine", "Status"], restaurants.map(r => [r.name, r.address || "", (r.cuisine_tags || []).join("; "), r.status]))} disabled={restaurants.length === 0}>
              <Download className="mr-2 size-4" />
              Export CSV
            </Button>
            <Button onClick={() => { setEditing(null); setShowDialog(true) }}>
              <Plus className="mr-2 size-4" />
              {isOwner ? "New Restaurant" : "New Restaurant"}
            </Button>
          </div>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <CardTitle>{isOwner ? "My Restaurants" : "All Restaurants"}</CardTitle>
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    placeholder="Search by name..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-48 pl-8"
                  />
                </div>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-32">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {STATUSES.map((s) => (
                      <SelectItem key={s} value={s}>{s === "all" ? "All Status" : s.charAt(0).toUpperCase() + s.slice(1)}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            {isAdmin && selected.size > 0 && (
              <BulkActionBar
                count={selected.size}
                actions={[
                  { label: "Approve All", onClick: () => handleBulk("approve"), confirmMessage: `Approve ${selected.size} selected restaurant(s)?` },
                  { label: "Reject All", variant: "destructive", onClick: () => handleBulk("reject"), confirmMessage: `Reject ${selected.size} selected restaurant(s)?` },
                ]}
                deleteAction={handleBulkDelete}
                deleteLabel="Delete All"
                onClear={clear}
              />
            )}
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  {isAdmin && (
                    <TableHead className="w-10">
                      <Checkbox
                        checked={!loading && restaurants.length > 0 && selected.size === restaurants.length}
                        onCheckedChange={() => toggleAll(restaurants.map((r) => r.id))}
                      />
                    </TableHead>
                  )}
                  <TableHead>Name</TableHead>
                  <TableHead>Cuisine</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableSkeleton columns={isAdmin ? 5 : 4} />
                ) : restaurants.length === 0 ? (
                  <EmptyState
                    icon={<Store className="size-10 text-muted-foreground/50" />}
                    title="No restaurants found"
                    description={search || statusFilter !== "all" ? "Try adjusting your search or filters." : "No restaurants have been created yet."}
                    action={
                      search || statusFilter !== "all" ? undefined : (
                        <Button size="sm" onClick={() => { setEditing(null); setShowDialog(true) }}>
                          <Plus className="mr-1 size-3" />
                          Add Restaurant
                        </Button>
                      )
                    }
                  />
                ) : (
                  restaurants.map((r) => (
                    <TableRow key={r.id}>
                      {isAdmin && (
                        <TableCell>
                          <Checkbox
                            checked={selected.has(r.id)}
                            onCheckedChange={() => toggle(r.id)}
                          />
                        </TableCell>
                      )}
                      <TableCell>
                        <Link href={`/dashboard/restaurants/${r.id}`} className="font-medium hover:text-primary transition-colors">
                          {r.name}
                        </Link>
                        <div className="text-xs text-muted-foreground">{r.slug}</div>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-1 flex-wrap">
                          {r.cuisine_tags?.map((tag) => (
                            <Badge key={tag} variant="outline" className="text-xs">
                              {tag}
                            </Badge>
                          ))}
                        </div>
                      </TableCell>
                      <TableCell>{statusBadge(r.status)}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button size="icon" variant="ghost" onClick={() => { setEditing(r); setShowDialog(true) }}>
                            <Pencil className="size-4" />
                          </Button>
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button size="icon" variant="ghost" onClick={() => setDeleteTarget(r)}>
                                <Trash2 className="size-4 text-destructive" />
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete Restaurant</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Are you sure you want to delete <strong>{r.name}</strong>? This action cannot be undone.
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
                          {isAdmin && r.status === "pending" && (
                            <>
                              <AlertDialog>
                                <AlertDialogTrigger asChild>
                                  <Button size="sm">
                                    Approve
                                  </Button>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                  <AlertDialogHeader>
                                    <AlertDialogTitle>Approve {r.name}</AlertDialogTitle>
                                    <AlertDialogDescription>
                                      Approve this restaurant? It will be visible to all users.
                                    </AlertDialogDescription>
                                  </AlertDialogHeader>
                                  <AlertDialogFooter>
                                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                                    <AlertDialogAction onClick={() => updateStatus(r.id, "approve")}>
                                      Approve
                                    </AlertDialogAction>
                                  </AlertDialogFooter>
                                </AlertDialogContent>
                              </AlertDialog>
                              <AlertDialog>
                                <AlertDialogTrigger asChild>
                                  <Button size="sm" variant="destructive">
                                    Reject
                                  </Button>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                  <AlertDialogHeader>
                                    <AlertDialogTitle>Reject {r.name}</AlertDialogTitle>
                                    <AlertDialogDescription>
                                      Reject this restaurant? It will not be listed for users.
                                    </AlertDialogDescription>
                                  </AlertDialogHeader>
                                  <AlertDialogFooter>
                                    <AlertDialogCancel>Cancel</AlertDialogCancel>
                                    <AlertDialogAction onClick={() => updateStatus(r.id, "reject")}>
                                      Reject
                                    </AlertDialogAction>
                                  </AlertDialogFooter>
                                </AlertDialogContent>
                              </AlertDialog>
                            </>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>

            <PaginationBar page={page} perPage={PER_PAGE} total={total} onPageChange={setPage} />
          </CardContent>
        </Card>

        <RestaurantDialog
          open={showDialog}
          onClose={() => setShowDialog(false)}
          onSaved={load}
          restaurant={editing}
        />
      </div>
    </ErrorBoundary>
  )
}
