"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { notify } from "@/components/ui/toast"
import { Plus, Pencil, Trash2 } from "lucide-react"
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

export default function OffersPage() {
  const [offers, setOffers] = useState<Offer[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [showDialog, setShowDialog] = useState(false)
  const [editing, setEditing] = useState<Offer | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Offer[]; pagination: { total: number } }>(
        `/offers?page=${page}&per_page=${PER_PAGE}`
      )
      setOffers(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setOffers([])
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => { load() }, [load])

  async function updateStatus(id: string, action: "approve" | "reject") {
    try {
      await api.post(`/offers/${id}/${action}`)
      notify(`Offer ${action}d`, "success")
      load()
    } catch {}
  }

  async function handleDelete(id: string) {
    if (!confirm("Are you sure you want to delete this offer?")) return
    try {
      await api.delete(`/offers/${id}`)
      notify("Offer deleted", "success")
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
          <CardTitle>All Offers</CardTitle>
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
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                    Loading...
                  </TableCell>
                </TableRow>
              ) : offers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-muted-foreground">
                    No offers found
                  </TableCell>
                </TableRow>
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
                        <Button size="icon" variant="ghost" onClick={() => handleDelete(o.id)}>
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
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
  )
}
