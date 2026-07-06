"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { useAuth } from "@/hooks/use-auth"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
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
import { Store, Tag, UserCheck, Eye } from "lucide-react"

interface Owner {
  id: string
  email: string
  name: string
  is_active: boolean
  restaurant_count: number
  offer_count: number
  created_at: string
}

const PER_PAGE = 10

function OwnersContent() {
  const [owners, setOwners] = useState<Owner[]>([])
  const [loading, setLoading] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)
  const [impersonatingId, setImpersonatingId] = useState<string | null>(null)
  const { impersonate } = useAuth()

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({ page: String(page), per_page: String(PER_PAGE) })
      const res = await api.get<{ data: Owner[]; pagination: { total: number } }>(`/admin/owners?${params}`)
      setOwners(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setOwners([])
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => { load() }, [load])

  const toggleActive = async (owner: Owner) => {
    try {
      await api.put(`/users/${owner.id}`, { is_active: !owner.is_active })
      notify(owner.is_active ? "Owner deactivated" : "Owner activated", "success")
      load()
    } catch {
      notify("Failed to update owner status", "error")
    }
  }

  const handleSwitch = async (owner: Owner) => {
    setImpersonatingId(owner.id)
    try {
      await impersonate(owner.id)
      notify(`Switched to ${owner.name}`, "success")
    } catch {
      notify("Failed to switch user", "error")
      setImpersonatingId(null)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Owners</h1>
          <p className="text-sm text-muted-foreground">Manage restaurant owners</p>
        </div>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base font-medium">All Owners</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-center"><Store className="size-3.5 inline mr-1" />Restaurants</TableHead>
                <TableHead className="text-center"><Tag className="size-3.5 inline mr-1" />Offers</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableSkeleton columns={6} />
              ) : owners.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6}>
                    <EmptyState icon={<UserCheck className="size-10 text-muted-foreground/50" />} title="No owners found" description="There are no restaurant owners yet." />
                  </TableCell>
                </TableRow>
              ) : (
                owners.map((owner) => (
                  <TableRow key={owner.id}>
                    <TableCell className="font-medium">{owner.name}</TableCell>
                    <TableCell className="text-muted-foreground">{owner.email}</TableCell>
                    <TableCell>
                      <Badge variant={owner.is_active ? "default" : "secondary"}>
                        {owner.is_active ? "Active" : "Suspended"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-center">{owner.restaurant_count}</TableCell>
                    <TableCell className="text-center">{owner.offer_count}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-2">
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button
                              size="sm"
                              variant="outline"
                              disabled={impersonatingId === owner.id}
                            >
                              <Eye className="size-3.5 mr-1" />
                              Switch
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>Switch to {owner.name}</AlertDialogTitle>
                              <AlertDialogDescription>
                                You will see their dashboard with their restaurants and offers.
                                Click &quot;Back to Admin&quot; in the banner to return.
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction onClick={() => handleSwitch(owner)}>
                                Switch
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button
                              variant={owner.is_active ? "outline" : "default"}
                              size="sm"
                            >
                              {owner.is_active ? "Suspend" : "Activate"}
                            </Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>{owner.is_active ? "Suspend" : "Activate"} {owner.name}</AlertDialogTitle>
                              <AlertDialogDescription>
                                {owner.is_active
                                  ? `Suspend ${owner.name}? They will lose access to the dashboard.`
                                  : `Activate ${owner.name}? They will regain access to the dashboard.`}
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction onClick={() => toggleActive(owner)}>
                                {owner.is_active ? "Suspend" : "Activate"}
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                      </div>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
          {!loading && owners.length > 0 && (
            <PaginationBar page={page} total={total} perPage={PER_PAGE} onPageChange={setPage} />
          )}
        </CardContent>
      </Card>
    </div>
  )
}

export default function OwnersPage() {
  return (
    <ErrorBoundary>
      <OwnersContent />
    </ErrorBoundary>
  )
}
