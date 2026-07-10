"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import { useAuth } from "@/hooks/use-auth"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select"
import { Plus, Pencil, Trash2, Image as ImageIcon, CheckCircle, XCircle } from "lucide-react"

interface Banner {
  id: string
  image: string
  link_type: string
  link_value: string
  title: string
  sponsor_name: string
  sort_order: number
  status: "pending" | "approved" | "rejected"
  click_count: number
  start_date: string | null
  end_date: string | null
  owner_id: string | null
  offer_id: string | null
  created_at: string
}

interface Offer {
  id: string
  title: string
}

export default function BannersPage() {
  const { user } = useAuth()
  const isAdmin = user?.role === "admin"
  const [banners, setBanners] = useState<Banner[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Banner | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Banner | null>(null)
  const [saving, setSaving] = useState(false)

  const [image, setImage] = useState("")
  const [linkType, setLinkType] = useState("offer")
  const [linkValue, setLinkValue] = useState("")
  const [title, setTitle] = useState("")
  const [sponsorName, setSponsorName] = useState("")
  const [sortOrder, setSortOrder] = useState(0)
  const [startDate, setStartDate] = useState("")
  const [endDate, setEndDate] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")

  const [myOffers, setMyOffers] = useState<Offer[]>([])
  const [selectedOffer, setSelectedOffer] = useState("")

  const endpoint = isAdmin ? "/admin/banners" : "/dashboard/banners"

  const loadBanners = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Banner[] }>(endpoint)
      setBanners(res.data || [])
    } catch { setBanners([]) }
    finally { setLoading(false) }
  }, [endpoint])

  const loadMyOffers = useCallback(async () => {
    if (isAdmin) return
    try {
      const res = await api.get<{ data: Offer[] }>("/dashboard/offers")
      const list = res.data || []
      setMyOffers(list)
    } catch { setMyOffers([]) }
  }, [isAdmin])

  useEffect(() => { loadBanners() }, [loadBanners])
  useEffect(() => { loadMyOffers() }, [loadMyOffers])

  function resetForm() {
    setImage("")
    setLinkType("offer")
    setLinkValue("")
    setTitle("")
    setSponsorName("")
    setSortOrder(0)
    setStartDate("")
    setEndDate("")
    setSelectedOffer("")
  }

  function startCreate() {
    setEditing(null)
    resetForm()
  }

  function startEdit(b: Banner) {
    setEditing(b)
    setImage(b.image)
    setLinkType(b.link_type)
    setLinkValue(b.link_value)
    setTitle(b.title || "")
    setSponsorName(b.sponsor_name || "")
    setSortOrder(b.sort_order)
    setStartDate(b.start_date ? b.start_date.slice(0, 10) : "")
    setEndDate(b.end_date ? b.end_date.slice(0, 10) : "")
    setSelectedOffer(b.offer_id || "")
  }

  async function handleSave() {
    if (!image.trim()) { notify("Image URL is required", "error"); return }

    if (!isAdmin && !selectedOffer) {
      notify("Please select an offer", "error")
      return
    }

    if (!isAdmin && !editing) {
      await handleOwnerCreate()
      return
    }

    setSaving(true)
    try {
      const body: Record<string, unknown> = {
        image: image.trim(),
        link_type: linkType,
        link_value: linkValue,
        title: title.trim(),
        sponsor_name: sponsorName.trim(),
        sort_order: sortOrder,
      }
      if (startDate) body.start_date = startDate
      if (endDate) body.end_date = endDate
      if (selectedOffer) body.offer_id = selectedOffer

      if (editing) {
        await api.put(`/admin/banners/${editing.id}`, body)
        notify("Banner updated", "success")
      } else {
        await api.post("/admin/banners", body)
        notify("Banner created", "success")
      }
      startCreate()
      loadBanners()
    } catch { notify("Failed to save banner", "error") }
    setSaving(false)
  }

  async function handleOwnerCreate() {
    setSaving(true)
    try {
      await api.post("/dashboard/banners", {
        offer_id: selectedOffer,
        image: image.trim(),
        title: title.trim(),
      })
      notify("Banner submitted for approval", "success")
      startCreate()
      loadBanners()
    } catch { notify("Failed to create banner", "error") }
    setSaving(false)
  }

  async function handleOwnerUpdate() {
    if (!editing) return
    setSaving(true)
    try {
      await api.put(`/dashboard/banners/${editing.id}`, {
        offer_id: selectedOffer || editing.offer_id,
        image: image.trim(),
        title: title.trim(),
      })
      notify("Banner updated", "success")
      setEditing(null)
      resetForm()
      loadBanners()
    } catch { notify("Failed to update banner", "error") }
    setSaving(false)
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await api.delete(`${endpoint}/${deleteTarget.id}`)
      notify("Banner deleted", "success")
      setDeleteTarget(null)
      loadBanners()
    } catch { notify("Failed to delete banner", "error") }
  }

  async function handleApprove(id: string) {
    try {
      await api.post(`/admin/banners/${id}/approve`)
      notify("Banner approved", "success")
      loadBanners()
    } catch { notify("Failed to approve banner", "error") }
  }

  async function handleReject(id: string) {
    try {
      await api.post(`/admin/banners/${id}/reject`)
      notify("Banner rejected", "success")
      loadBanners()
    } catch { notify("Failed to reject banner", "error") }
  }

  const filteredBanners = statusFilter === "all"
    ? banners
    : banners.filter(b => b.status === statusFilter)

  function statusBadge(status: string) {
    switch (status) {
      case "approved": return <span className="inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800 dark:bg-green-900 dark:text-green-200">Approved</span>
      case "rejected": return <span className="inline-flex items-center rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-800 dark:bg-red-900 dark:text-red-200">Rejected</span>
      default: return <span className="inline-flex items-center rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200">Pending</span>
    }
  }

  async function handleImageUpload() {
    const input = document.createElement("input")
    input.type = "file"
    input.accept = "image/*"
    input.onchange = async () => {
      const file = input.files?.[0]
      if (!file) return
      const formData = new FormData()
      formData.append("file", file)
      try {
        const res = await api.upload<{ data: { url: string } }>("/upload?folder=banners", formData)
        setImage(res.data.url)
        notify("Image uploaded", "success")
      } catch { notify("Upload failed", "error") }
    }
    input.click()
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">
              {isAdmin ? "Banners" : "My Banners"}
            </h1>
            <p className="text-muted-foreground">
              {isAdmin ? "Manage promotional banners" : "Create banners linked to your offers"}
            </p>
          </div>
          <Button onClick={startCreate}><Plus className="mr-2 size-4" />New Banner</Button>
        </div>

        {/* Create/Edit Dialog */}
        {(editing || editing === null) && (image || title || editing !== null) && false ? null : null}
        <Card className={editing || image || title ? "hidden" : "block"}>
          {/* For simplicity, we use a modal-like approach with state */}
        </Card>

        {(editing || editing === null) && (
          <Card className="border-primary/20">
            <CardContent className="pt-6 space-y-4">
              <h3 className="font-semibold">{editing ? "Edit Banner" : "New Banner"}</h3>

              {!isAdmin && !editing && (
                <div className="grid gap-2">
                  <Label>Select Offer</Label>
                  <Select value={selectedOffer} onValueChange={setSelectedOffer}>
                    <SelectTrigger><SelectValue placeholder="Choose an offer..." /></SelectTrigger>
                    <SelectContent>
                      {myOffers.map(o => (
                        <SelectItem key={o.id} value={o.id}>{o.title}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              <div className="grid gap-2">
                <Label>Image</Label>
                <div className="flex gap-2">
                  <Input value={image} onChange={e => setImage(e.target.value)} placeholder="Image URL" className="flex-1" />
                  <Button variant="outline" onClick={handleImageUpload}>Upload</Button>
                </div>
              </div>

              <div className="grid gap-2">
                <Label>Title</Label>
                <Input value={title} onChange={e => setTitle(e.target.value)} placeholder="e.g. Weekend Special!" />
              </div>

              {isAdmin && (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label>Link Type</Label>
                      <Select value={linkType} onValueChange={setLinkType}>
                        <SelectTrigger><SelectValue /></SelectTrigger>
                        <SelectContent>
                          <SelectItem value="offer">Offer</SelectItem>
                          <SelectItem value="restaurant">Restaurant</SelectItem>
                          <SelectItem value="external">External URL</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    <div className="grid gap-2">
                      <Label>Link Value</Label>
                      <Input value={linkValue} onChange={e => setLinkValue(e.target.value)} placeholder={linkType === "external" ? "https://..." : "UUID"} />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label>Sponsor Name</Label>
                      <Input value={sponsorName} onChange={e => setSponsorName(e.target.value)} placeholder="Restaurant name" />
                    </div>
                    <div className="grid gap-2">
                      <Label>Sort Order</Label>
                      <Input type="number" value={sortOrder} onChange={e => setSortOrder(Number(e.target.value))} />
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label>Start Date</Label>
                      <Input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} />
                    </div>
                    <div className="grid gap-2">
                      <Label>End Date</Label>
                      <Input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} />
                    </div>
                  </div>
                </>
              )}

              <div className="flex gap-2">
                <Button onClick={editing && !isAdmin ? handleOwnerUpdate : handleSave} disabled={saving}>
                  {saving ? "Saving..." : editing ? "Update" : isAdmin ? "Create" : "Submit for Approval"}
                </Button>
                {editing && <Button variant="outline" onClick={() => { setEditing(null); resetForm() }}>Cancel</Button>}
              </div>

              {editing && editing.owner_id && editing.status === "pending" && isAdmin && (
                <p className="text-xs text-muted-foreground">Owner-created banner awaiting admin approval</p>
              )}
              {editing && editing.status === "rejected" && !isAdmin && (
                <p className="text-xs text-amber-600">Not approved. Edit and resubmit.</p>
              )}
            </CardContent>
          </Card>
        )}

        {/* Filter */}
        {isAdmin && (
          <div className="flex items-center gap-2">
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
              </SelectContent>
            </Select>
          </div>
        )}

        {/* Table */}
        <Card>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-16">Image</TableHead>
                  <TableHead>Title</TableHead>
                  {isAdmin && <TableHead>Sponsor</TableHead>}
                  {isAdmin && <TableHead>Owner</TableHead>}
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right w-20">Clicks</TableHead>
                  <TableHead className="text-right w-32">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {loading ? <TableSkeleton columns={isAdmin ? 7 : 5} /> :
                  filteredBanners.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={isAdmin ? 7 : 5} className="text-center py-8">
                        <EmptyState icon={<ImageIcon className="size-10 text-muted-foreground/50" />} title="No banners" description="Create your first banner to get started." />
                      </TableCell>
                    </TableRow>
                  ) : filteredBanners.map(b => (
                    <TableRow key={b.id}>
                      <TableCell>
                        <div className="size-12 rounded overflow-hidden bg-muted">
                          {b.image ? <img src={b.image} alt="" className="size-full object-cover" /> : <div className="size-full flex items-center justify-center text-muted-foreground/30"><ImageIcon className="size-5" /></div>}
                        </div>
                      </TableCell>
                      <TableCell className="font-medium max-w-40 truncate">{b.title || "-"}</TableCell>
                      {isAdmin && <TableCell className="text-sm text-muted-foreground">{b.sponsor_name || "-"}</TableCell>}
                      {isAdmin && <TableCell className="text-sm text-muted-foreground">{b.owner_id ? "Owner" : "Global"}</TableCell>}
                      <TableCell>{statusBadge(b.status)}</TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">{b.click_count}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          {isAdmin && b.status === "pending" && b.owner_id && (
                            <>
                              <Button size="icon" variant="ghost" onClick={() => handleApprove(b.id)} title="Approve"><CheckCircle className="size-4 text-green-600" /></Button>
                              <Button size="icon" variant="ghost" onClick={() => handleReject(b.id)} title="Reject"><XCircle className="size-4 text-red-600" /></Button>
                            </>
                          )}
                          <Button size="icon" variant="ghost" onClick={() => startEdit(b)} disabled={!isAdmin && b.status === "approved"}><Pencil className="size-4" /></Button>
                          <AlertDialog>
                            <AlertDialogTrigger asChild><Button size="icon" variant="ghost" onClick={() => setDeleteTarget(b)}><Trash2 className="size-4 text-destructive" /></Button></AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader><AlertDialogTitle>Delete Banner</AlertDialogTitle><AlertDialogDescription>Delete <strong>{b.title || "this banner"}</strong>? This cannot be undone.</AlertDialogDescription></AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel onClick={() => setDeleteTarget(null)}>Cancel</AlertDialogCancel>
                                <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">Delete</AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </ErrorBoundary>
  )
}
