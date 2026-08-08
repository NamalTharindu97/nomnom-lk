"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Plus, Pencil, Trash2, ShoppingCart } from "lucide-react"

interface OrderPlatform {
  id: string
  name: string
  slug: string
  display_name: string
  primary_color: string
  deep_link_scheme: string
  logo_url: string | null
  created_at: string
}

export default function OrderPlatformsPage() {
  const [platforms, setPlatforms] = useState<OrderPlatform[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [saving, setSaving] = useState(false)
  const [editId, setEditId] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  const [name, setName] = useState("")
  const [displayName, setDisplayName] = useState("")
  const [primaryColor, setPrimaryColor] = useState("#06C167")
  const [deepLinkScheme, setDeepLinkScheme] = useState("")
  const [logoUrl, setLogoUrl] = useState("")

  const loadPlatforms = useCallback(async () => {
    try {
      const data = await api.get<OrderPlatform[]>("/admin/order-platforms")
      setPlatforms(Array.isArray(data) ? data : (data as any)?.data || [])
    } catch {
      notify("Failed to load order platforms", "error")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadPlatforms() }, [loadPlatforms])

  const resetForm = () => {
    setName("")
    setDisplayName("")
    setPrimaryColor("#06C167")
    setDeepLinkScheme("")
    setLogoUrl("")
    setEditId(null)
    setShowForm(false)
  }

  const handleSave = async () => {
    const trimmed = name.trim()
    if (!trimmed || !displayName.trim() || !deepLinkScheme.trim()) {
      notify("All fields are required", "error")
      return
    }
    setSaving(true)
    try {
      if (editId) {
        await api.put(`/admin/order-platforms/${editId}`, {
          name: trimmed, display_name: displayName.trim(),
          primary_color: primaryColor, deep_link_scheme: deepLinkScheme.trim(),
          logo_url: logoUrl.trim() || null,
        })
        notify("Platform updated", "success")
      } else {
        await api.post("/admin/order-platforms", {
          name: trimmed, display_name: displayName.trim(),
          primary_color: primaryColor, deep_link_scheme: deepLinkScheme.trim(),
          logo_url: logoUrl.trim() || null,
        })
        notify("Platform created", "success")
      }
      resetForm()
      loadPlatforms()
    } catch {
      notify("Failed to save", "error")
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    setDeleting(true)
    try {
      await api.delete(`/admin/order-platforms/${deleteId}`)
      setDeleteId(null)
      notify("Platform deleted", "success")
      loadPlatforms()
    } catch {
      notify("Failed to delete", "error")
    } finally {
      setDeleting(false)
    }
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Ordering Platforms</h1>
            <p className="text-muted-foreground text-sm mt-1">
              Manage delivery platforms for restaurant ordering
            </p>
          </div>
          {!showForm && (
            <Button onClick={() => setShowForm(true)} size="sm">
              <Plus className="mr-1 h-4 w-4" /> Add Platform
            </Button>
          )}
        </div>

        {showForm && (
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">{editId ? "Edit" : "New"} Ordering Platform</CardTitle>
              <CardDescription>Add a delivery service like Uber Eats, PickMe, etc.</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label>Name</Label>
                  <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Uber Eats" />
                </div>
                <div className="grid gap-2">
                  <Label>Display Name</Label>
                  <Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder="e.g. Uber Eats" />
                </div>
                <div className="grid gap-2">
                  <Label>Primary Color</Label>
                  <div className="flex gap-2 items-center">
                    <Input value={primaryColor} onChange={(e) => setPrimaryColor(e.target.value)} placeholder="#06C167" className="w-28" />
                    <div className="w-8 h-8 rounded border" style={{ backgroundColor: primaryColor }} />
                  </div>
                </div>
                <div className="grid gap-2">
                  <Label>Deep Link Scheme</Label>
                  <Input value={deepLinkScheme} onChange={(e) => setDeepLinkScheme(e.target.value)} placeholder="e.g. ubereats://" />
                </div>
              </div>
              <div className="grid gap-2">
                <Label>Logo Image URL</Label>
                <div className="flex gap-2">
                  <Input value={logoUrl} onChange={(e) => setLogoUrl(e.target.value)} placeholder="https://... or upload" className="flex-1" />
                  <Button variant="outline" size="sm" type="button" onClick={() => {
                    const input = document.createElement("input")
                    input.type = "file"
                    input.accept = "image/*"
                    input.onchange = async () => {
                      const file = input.files?.[0]
                      if (!file) return
                      const formData = new FormData()
                      formData.append("file", file)
                      try {
                        const res = await api.upload<{ data: { url: string } }>("/upload?folder=platforms", formData)
                        setLogoUrl(res.data.url)
                        notify("Logo uploaded", "success")
                      } catch { notify("Upload failed", "error") }
                    }
                    input.click()
                  }}>Upload</Button>
                </div>
                {logoUrl && (
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded border overflow-hidden bg-muted">
                      <img src={logoUrl} alt="logo" className="w-full h-full object-cover" />
                    </div>
                    <span className="text-xs text-muted-foreground truncate flex-1">{logoUrl}</span>
                  </div>
                )}
              </div>
              <div className="flex gap-2 mt-4">
                <Button onClick={handleSave} disabled={saving}>{saving ? "Saving..." : "Save"}</Button>
                <Button variant="ghost" onClick={resetForm}>Cancel</Button>
              </div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">All Platforms ({platforms.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <TableSkeleton columns={4} rows={3} />
            ) : platforms.length === 0 ? (
              <EmptyState
                icon={<ShoppingCart className="h-8 w-8" />}
                title="No ordering platforms yet"
                description="Add delivery platforms so restaurants can link to them"
              />
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Slug</TableHead>
                    <TableHead>Scheme</TableHead>
                    <TableHead>Color</TableHead>
                    <TableHead className="w-24">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {platforms.map((p) => (
                    <TableRow key={p.id}>
                      <TableCell className="font-medium">{p.display_name}</TableCell>
                      <TableCell className="text-muted-foreground text-sm">{p.slug}</TableCell>
                      <TableCell className="text-muted-foreground text-sm font-mono">{p.deep_link_scheme}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <div className="w-4 h-4 rounded" style={{ backgroundColor: p.primary_color }} />
                          <span className="text-xs font-mono">{p.primary_color}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-1">
                          <Button size="sm" variant="ghost" onClick={() => {
                            setEditId(p.id); setName(p.name); setDisplayName(p.display_name)
                            setPrimaryColor(p.primary_color); setDeepLinkScheme(p.deep_link_scheme)
                            setLogoUrl(p.logo_url || "")
                            setShowForm(true)
                          }}>
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeleteId(p.id)}>
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <AlertDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Delete Ordering Platform</AlertDialogTitle>
              <AlertDialogDescription>
                This removes the platform from the list. Restaurants that already use it will still show it.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction onClick={handleDelete} disabled={deleting} className="bg-destructive text-destructive-foreground">
                {deleting ? "Deleting..." : "Delete"}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </ErrorBoundary>
  )
}
