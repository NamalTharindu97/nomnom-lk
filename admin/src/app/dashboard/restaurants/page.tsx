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

export default function RestaurantsPage() {
  const [restaurants, setRestaurants] = useState<Restaurant[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [showDialog, setShowDialog] = useState(false)
  const [editing, setEditing] = useState<Restaurant | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Restaurant[]; pagination: { total: number } }>(
        `/restaurants?page=${page}&per_page=${PER_PAGE}`
      )
      setRestaurants(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setRestaurants([])
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => { load() }, [load])

  async function updateStatus(id: string, action: "approve" | "reject") {
    try {
      await api.post(`/restaurants/${id}/${action}`)
      notify(`Restaurant ${action}d`, "success")
      load()
    } catch {}
  }

  async function handleDelete(id: string) {
    if (!confirm("Are you sure you want to delete this restaurant?")) return
    try {
      await api.delete(`/restaurants/${id}`)
      notify("Restaurant deleted", "success")
      load()
    } catch {}
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
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Restaurants</h1>
          <p className="text-muted-foreground">Manage restaurant listings</p>
        </div>
        <Button onClick={() => { setEditing(null); setShowDialog(true) }}>
          <Plus className="mr-2 size-4" />
          New Restaurant
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Restaurants</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Cuisine</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">
                    Loading...
                  </TableCell>
                </TableRow>
              ) : restaurants.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">
                    No restaurants found
                  </TableCell>
                </TableRow>
              ) : (
                restaurants.map((r) => (
                  <TableRow key={r.id}>
                    <TableCell>
                      <div className="font-medium">{r.name}</div>
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
                        <Button size="icon" variant="ghost" onClick={() => handleDelete(r.id)}>
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
                        {r.status === "pending" && (
                          <>
                            <Button size="sm" onClick={() => updateStatus(r.id, "approve")}>
                              Approve
                            </Button>
                            <Button size="sm" variant="destructive" onClick={() => updateStatus(r.id, "reject")}>
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

      <RestaurantDialog
        open={showDialog}
        onClose={() => setShowDialog(false)}
        onSaved={load}
        restaurant={editing}
      />
    </div>
  )
}
