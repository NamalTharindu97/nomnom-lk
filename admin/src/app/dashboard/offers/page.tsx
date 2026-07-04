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
import { Plus, Pencil, Trash2, Search, Tag } from "lucide-react"
import OfferDialog from "./_offer-dialog"

interface Offer {
  id: string
  title: string
  status: string
  original_price: number
  offer_price: number
  end_date: string
  restaurant: { name: string }
  restaurant_id: string
  description: string
  start_date: string
  image_urls: string[]
}

const PER_PAGE = 10
const STATUSES = ["all", "approved", "pending", "rejected", "expired"]

export default function OffersPage() {
  const [offers, setOffers] = useState<Offer[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [showDialog, setShowDialog] = useState(false)
  const [editing, setEditing] = useState<Offer | null>(null)
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [deleteTarget, setDeleteTarget] = useState<Offer | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page: String(page),
        per_page: String(PER_PAGE),
        status: statusFilter,
      })
      if (search.trim()) params.set("q", search.trim())
      const res = await api.get<{ data: Offer[]; pagination: { total: number } }>(
        `/offers?${params}`
      )
      setOffers(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setOffers([])
    } finally {
      setLoading(false)
    }
  }, [page, search, statusFilter])

  useEffect(() => { load() }, [load])
  useEffect(() => { setPage(1) }, [search, statusFilter])

  async function updateStatus(id: string, action: "approve" | "reject") {
    try {
      await api.post(`/offers/${id}/${action}`)
      notify(`Offer ${action}d`, "success")
      load()
    } catch {}
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await api.delete(`/offers/${deleteTarget.id}`)
      notify("Offer deleted", "success")
      setDeleteTarget(null)
      load()
    } catch {}
  }

  const statusBadge = (status: string) => {
    const variants: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
      approved: "default",
      pending: "secondary",
      rejected: "destructive",
      expired: "outline",
    }
    return <Badge variant={variants[status] || "outline"}>{status}</Badge>
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Offers</h1>
            <p className="text-muted-foreground">Manage food offers</p>
          </div>
          <Button onClick={() => { setEditing(null); setShowDialog(true) }}>
            <Plus className="mr-2 size-4" />
            New Offer
          </Button>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <CardTitle>All Offers</CardTitle>
              <div className="flex items-center gap-2">
                <div className="relative">
                  <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    placeholder="Search by title..."
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
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Restaurant</TableHead>
                  <TableHead>Price</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>End Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? (
                  <TableSkeleton columns={6} />
                ) : offers.length === 0 ? (
                  <EmptyState
                    icon={<Tag className="size-10 text-muted-foreground/50" />}
                    title="No offers found"
                    description={search || statusFilter !== "all" ? "Try adjusting your search or filters." : "No offers have been created yet."}
                    action={
                      search || statusFilter !== "all" ? undefined : (
                        <Button size="sm" onClick={() => { setEditing(null); setShowDialog(true) }}>
                          <Plus className="mr-1 size-3" />
                          Add Offer
                        </Button>
                      )
                    }
                  />
                ) : (
                  offers.map((o) => (
                    <TableRow key={o.id}>
                      <TableCell className="font-medium">{o.title}</TableCell>
                      <TableCell>{o.restaurant?.name}</TableCell>
                      <TableCell>
                        <span className="line-through text-muted-foreground text-xs">
                          LKR {o.original_price}
                        </span>{" "}
                        <span className="text-green-600 font-semibold">LKR {o.offer_price}</span>
                      </TableCell>
                      <TableCell>{statusBadge(o.status)}</TableCell>
                      <TableCell className="text-xs">
                        {new Date(o.end_date).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button size="icon" variant="ghost" onClick={() => { setEditing(o); setShowDialog(true) }}>
                            <Pencil className="size-4" />
                          </Button>
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button size="icon" variant="ghost" onClick={() => setDeleteTarget(o)}>
                                <Trash2 className="size-4 text-destructive" />
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete Offer</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Are you sure you want to delete <strong>{o.title}</strong>? This action cannot be undone.
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
                          {o.status === "pending" && (
                            <>
                              <Button size="sm" onClick={() => updateStatus(o.id, "approve")}>
                                Approve
                              </Button>
                              <Button size="sm" variant="destructive" onClick={() => updateStatus(o.id, "reject")}>
                                Reject
                              </Button>
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

        <OfferDialog
          open={showDialog}
          onClose={() => setShowDialog(false)}
          onSaved={load}
          offer={editing}
        />
      </div>
    </ErrorBoundary>
  )
}
