"use client"

import { useEffect, useState, useCallback } from "react"
import Image from "next/image"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import { useAuth } from "@/hooks/use-auth"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select"
import { Plus, Pencil, Trash2, Image as ImageIcon, CheckCircle, XCircle, ExternalLink, Tag, Store, Link2 } from "lucide-react"

const bannerSchema = z.object({
  title: z.string().optional(),
  image_url: z.string().min(1, "Image URL is required"),
  link_type: z.enum(["offer", "restaurant", "external"], { message: "Link type is required" }),
  link_value: z.string().min(1, "Link value is required"),
  is_active: z.boolean().optional(),
  cta_text: z.string().optional(),
  display_order: z.number().min(0, "Must be 0 or higher").optional(),
  start_date: z.string().optional(),
  end_date: z.string().optional(),
})

type BannerForm = z.infer<typeof bannerSchema>

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
  restaurant_name?: string
}

interface Restaurant {
  id: string
  name: string
}

export default function BannersPage() {
  const { user, isLoading: authLoading } = useAuth()
  const isAdmin = user?.role === "admin"
  const [banners, setBanners] = useState<Banner[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Banner | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Banner | null>(null)
  const [saving, setSaving] = useState(false)
  const [statusFilter, setStatusFilter] = useState("all")

  const [myOffers, setMyOffers] = useState<Offer[]>([])
  const [selectedOffer, setSelectedOffer] = useState("")
  const [adminOffers, setAdminOffers] = useState<Offer[]>([])
  const [adminRestaurants, setAdminRestaurants] = useState<Restaurant[]>([])

  const endpoint = isAdmin ? "/admin/banners" : "/dashboard/banners"

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<BannerForm>({
    resolver: zodResolver(bannerSchema),
    defaultValues: {
      title: "",
      image_url: "",
      link_type: "offer",
      link_value: "",
      is_active: false,
      cta_text: "",
      display_order: 0,
      start_date: "",
      end_date: "",
    },
  })

  const currentLinkType = watch("link_type")

  const loadBanners = useCallback(async () => {
    if (authLoading || !user) return
    setLoading(true)
    try {
      const res = await api.get<{ data: Banner[] }>(endpoint)
      setBanners(res.data || [])
    } catch { setBanners([]) }
    finally { setLoading(false) }
  }, [endpoint, authLoading, user])

  const loadMyOffers = useCallback(async () => {
    if (authLoading || !user || isAdmin) return
    try {
      const res = await api.get<{ data: Offer[] }>("/dashboard/offers?per_page=100")
      const list = res.data || []
      setMyOffers(list)
    } catch { setMyOffers([]) }
  }, [authLoading, isAdmin, user])

  const loadAdminData = useCallback(async () => {
    if (authLoading || !user || !isAdmin) return
    try {
      const [offersRes, restaurantsRes] = await Promise.all([
        api.get<{ data: Offer[] }>("/offers?per_page=200&status=approved"),
        api.get<{ data: Restaurant[] }>("/restaurants?per_page=200&status=approved"),
      ])
      setAdminOffers(offersRes.data || [])
      setAdminRestaurants(restaurantsRes.data || [])
    } catch { /* ignore */ }
  }, [authLoading, isAdmin, user])

  useEffect(() => { loadBanners() }, [loadBanners])
  useEffect(() => { loadMyOffers() }, [loadMyOffers])
  useEffect(() => { loadAdminData() }, [loadAdminData])

  function resetForm() {
    reset({
      title: "",
      image_url: "",
      link_type: "offer",
      link_value: "",
      is_active: false,
      cta_text: "",
      display_order: 0,
      start_date: "",
      end_date: "",
    })
    setSelectedOffer("")
  }

  function startCreate() {
    setEditing(null)
    setShowForm(true)
    resetForm()
  }

  function startEdit(b: Banner) {
    setEditing(b)
    setShowForm(true)
    reset({
      title: b.title || "",
      image_url: b.image,
      link_type: b.link_type as BannerForm["link_type"],
      link_value: b.link_value,
      is_active: b.status === "approved",
      cta_text: b.sponsor_name || "",
      display_order: b.sort_order,
      start_date: b.start_date ? b.start_date.slice(0, 10) : "",
      end_date: b.end_date ? b.end_date.slice(0, 10) : "",
    })
    setSelectedOffer(b.offer_id || "")
  }

  async function onSave(data: BannerForm) {
    if (!isAdmin && !selectedOffer) {
      notify("Please select an offer", "error")
      return
    }

    if (data.start_date && data.end_date && data.end_date < data.start_date) {
      notify("End date must be on or after start date", "error")
      return
    }

    if (!isAdmin && !editing) {
      await handleOwnerCreate(data)
      return
    }

    if (!isAdmin && editing) {
      await handleOwnerUpdate(data)
      return
    }

    setSaving(true)
    try {
      const body: Record<string, unknown> = {
        image: data.image_url.trim(),
        link_type: data.link_type,
        link_value: data.link_value,
        title: data.title?.trim() || "",
        sponsor_name: data.cta_text?.trim() || "",
        sort_order: data.display_order ?? 0,
      }
      if (data.start_date) body.start_date = data.start_date
      if (data.end_date) body.end_date = data.end_date
      if (data.link_type === "offer") body.offer_id = data.link_value

      if (editing) {
        await api.put(`/admin/banners/${editing.id}`, body)
        notify("Banner updated", "success")
      } else {
        await api.post("/admin/banners", body)
        notify("Banner created", "success")
      }
      setEditing(null)
      setShowForm(false)
      resetForm()
      await loadBanners()
    } catch { notify("Failed to save banner", "error") }
    setSaving(false)
  }

  async function handleOwnerCreate(data: BannerForm) {
    setSaving(true)
    try {
      await api.post("/dashboard/banners", {
        offer_id: selectedOffer,
        image: data.image_url.trim(),
        title: data.title?.trim() || "",
      })
      notify("Banner submitted for approval", "success")
      setEditing(null)
      setShowForm(false)
      resetForm()
      await loadBanners()
    } catch { notify("Failed to create banner", "error") }
    setSaving(false)
  }

  async function handleOwnerUpdate(data: BannerForm) {
    if (!editing) return
    setSaving(true)
    try {
      await api.put(`/dashboard/banners/${editing.id}`, {
        offer_id: selectedOffer || editing.offer_id,
        image: data.image_url.trim(),
        title: data.title?.trim() || "",
      })
      notify("Banner updated", "success")
      setEditing(null)
      setShowForm(false)
      resetForm()
      await loadBanners()
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

  function linkTypeBadge(type: string) {
    switch (type) {
      case "offer": return <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900 dark:text-blue-200"><Tag className="size-3" />Offer</span>
      case "restaurant": return <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 px-2 py-0.5 text-xs font-medium text-purple-800 dark:bg-purple-900 dark:text-purple-200"><Store className="size-3" />Restaurant</span>
      case "external": return <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5 text-xs font-medium text-orange-800 dark:bg-orange-900 dark:text-orange-200"><ExternalLink className="size-3" />External</span>
      default: return <span className="inline-flex items-center gap-1 rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-900 dark:text-gray-200"><Link2 className="size-3" />{type}</span>
    }
  }

  function formatDate(dateStr: string | null) {
    if (!dateStr) return null
    return new Date(dateStr).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
  }

  function dateRange(b: Banner) {
    const s = formatDate(b.start_date)
    const e = formatDate(b.end_date)
    if (s && e) return `${s} – ${e}`
    if (s) return `${s} onward`
    if (e) return `Until ${e}`
    return "Always"
  }

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
        setValue("image_url", res.data.url, { shouldValidate: true })
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

        {(editing || showForm) && (
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
                <Label htmlFor="image_url">Image</Label>
                <div className="flex gap-2">
                  <Input id="image_url" {...register("image_url")} placeholder="Image URL" className="flex-1" />
                  <Button variant="outline" type="button" onClick={handleImageUpload}>Upload</Button>
                </div>
                {errors.image_url && <p className="text-xs text-destructive">{errors.image_url.message}</p>}
              </div>

              <div className="grid gap-2">
                <Label htmlFor="title">Title</Label>
                <Input id="title" {...register("title")} placeholder="e.g. Weekend Special!" />
                {errors.title && <p className="text-xs text-destructive">{errors.title.message}</p>}
              </div>

              {isAdmin && (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label htmlFor="link_type">Link Type</Label>
                      <Select
                        value={currentLinkType}
                        onValueChange={(v) => {
                          setValue("link_type", v as BannerForm["link_type"], { shouldValidate: true })
                          setValue("link_value", "")
                          setSelectedOffer("")
                        }}
                      >
                        <SelectTrigger id="link_type"><SelectValue /></SelectTrigger>
                        <SelectContent>
                          <SelectItem value="offer">Offer</SelectItem>
                          <SelectItem value="restaurant">Restaurant</SelectItem>
                          <SelectItem value="external">External URL</SelectItem>
                        </SelectContent>
                      </Select>
                      {errors.link_type && <p className="text-xs text-destructive">{errors.link_type.message}</p>}
                    </div>
                    <div className="grid gap-2">
                      <Label htmlFor="link_value">{currentLinkType === "offer" ? "Offer" : currentLinkType === "restaurant" ? "Restaurant" : "URL"}</Label>
                      {currentLinkType === "offer" ? (
                        <Select value={watch("link_value")} onValueChange={(v) => setValue("link_value", v, { shouldValidate: true })}>
                          <SelectTrigger id="link_value"><SelectValue placeholder="Select an offer..." /></SelectTrigger>
                          <SelectContent>
                            {adminOffers.map(o => (
                              <SelectItem key={o.id} value={o.id}>{o.title}{o.restaurant_name ? ` — ${o.restaurant_name}` : ""}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      ) : currentLinkType === "restaurant" ? (
                        <Select value={watch("link_value")} onValueChange={(v) => setValue("link_value", v, { shouldValidate: true })}>
                          <SelectTrigger id="link_value"><SelectValue placeholder="Select a restaurant..." /></SelectTrigger>
                          <SelectContent>
                            {adminRestaurants.map(r => (
                              <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      ) : (
                        <Input id="link_value" {...register("link_value")} placeholder="https://..." />
                      )}
                      {errors.link_value && <p className="text-xs text-destructive">{errors.link_value.message}</p>}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label htmlFor="cta_text">CTA Text / Sponsor Name</Label>
                      <Input id="cta_text" {...register("cta_text")} placeholder="Restaurant name" />
                      {errors.cta_text && <p className="text-xs text-destructive">{errors.cta_text.message}</p>}
                    </div>
                    <div className="grid gap-2">
                      <Label htmlFor="display_order">Display Order</Label>
                      <Input id="display_order" type="number" {...register("display_order", { valueAsNumber: true })} />
                      {errors.display_order && <p className="text-xs text-destructive">{errors.display_order.message}</p>}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="grid gap-2">
                      <Label htmlFor="start_date">Start Date</Label>
                      <Input id="start_date" type="date" {...register("start_date")} />
                      {errors.start_date && <p className="text-xs text-destructive">{errors.start_date.message}</p>}
                    </div>
                    <div className="grid gap-2">
                      <Label htmlFor="end_date">End Date</Label>
                      <Input id="end_date" type="date" {...register("end_date")} />
                      {errors.end_date && <p className="text-xs text-destructive">{errors.end_date.message}</p>}
                    </div>
                  </div>
                </>
              )}

              <div className="flex gap-2">
                <Button onClick={handleSubmit(onSave)} disabled={saving}>
                  {saving ? "Saving..." : editing ? "Update" : isAdmin ? "Create" : "Submit for Approval"}
                </Button>
                <Button variant="outline" type="button" onClick={() => { setEditing(null); setShowForm(false); resetForm() }}>Cancel</Button>
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
            <div className="overflow-x-auto">
              <Table className="min-w-[800px]">
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-40">Banner</TableHead>
                    <TableHead>Sponsor</TableHead>
                    {isAdmin && <TableHead>Link</TableHead>}
                    <TableHead>Schedule</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right w-20">Clicks</TableHead>
                    <TableHead className="text-right w-32">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? <TableSkeleton columns={isAdmin ? 7 : 6} /> :
                    filteredBanners.length === 0 ? (
                      <EmptyState
                        icon={<ImageIcon className="size-10 text-muted-foreground/50" />}
                        title="No banners"
                        description="Create your first banner to get started."
                      />
                    ) : filteredBanners.map(b => (
                      <TableRow key={b.id} className="group">
                        <TableCell>
                          <div className="relative h-16 w-32 rounded-md overflow-hidden bg-muted group">
                            {b.image ? (
                              <Image src={b.image} alt={b.title || ""} fill className="object-cover" sizes="128px" loading="eager" />
                            ) : (
                              <div className="size-full flex items-center justify-center text-muted-foreground/30">
                                <ImageIcon className="size-5" />
                              </div>
                            )}
                            {b.image && (
                              <div className="pointer-events-none absolute -top-2 left-full ml-2 z-50 hidden group-hover:block">
                                <div className="relative h-36 w-64 rounded-lg overflow-hidden shadow-xl border border-border">
                                  <Image src={b.image} alt={b.title || ""} fill className="object-cover" sizes="256px" loading="lazy" />
                                </div>
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div>
                            <div className="font-medium max-w-48 truncate">{b.title || "-"}</div>
                            <div className="text-sm text-muted-foreground">{b.sponsor_name || "-"}</div>
                          </div>
                        </TableCell>
                        {isAdmin && <TableCell>{linkTypeBadge(b.link_type)}</TableCell>}
                        <TableCell className="text-sm text-muted-foreground whitespace-nowrap">{dateRange(b)}</TableCell>
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
            </div>
          </CardContent>
        </Card>
      </div>
    </ErrorBoundary>
  )
}
