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
import { Plus, Pencil, Trash2, Share2 } from "lucide-react"

interface SocialPlatform {
  id: string
  name: string
  slug: string
  display_name: string
  primary_color: string
  logo_url: string | null
  sort_order: number
  created_at: string
}

export default function SocialPlatformsPage() {
  const [platforms, setPlatforms] = useState<SocialPlatform[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [saving, setSaving] = useState(false)
  const [editId, setEditId] = useState<string | null>(null)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [name, setName] = useState("")
  const [displayName, setDisplayName] = useState("")
  const [primaryColor, setPrimaryColor] = useState("#E4405F")
  const [logoUrl, setLogoUrl] = useState("")
  const [sortOrder, setSortOrder] = useState(0)

  const load = useCallback(async () => {
    try {
      const data = await api.get<SocialPlatform[]>("/admin/social-platforms")
      setPlatforms(Array.isArray(data) ? data : (data as any)?.data || [])
    } catch { notify("Failed to load", "error") }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  const reset = () => {
    setName(""); setDisplayName(""); setPrimaryColor("#E4405F"); setLogoUrl("")
    setSortOrder(0); setEditId(null); setShowForm(false)
  }

  const handleSave = async () => {
    if (!name.trim() || !displayName.trim()) { notify("Name and display name are required", "error"); return }
    setSaving(true)
    try {
      const body = { name: name.trim(), display_name: displayName.trim(), primary_color: primaryColor, logo_url: logoUrl.trim() || null, sort_order: sortOrder }
      if (editId) { await api.put(`/admin/social-platforms/${editId}`, body); notify("Updated", "success") }
      else { await api.post("/admin/social-platforms", body); notify("Created", "success") }
      reset(); load()
    } catch { notify("Failed to save", "error") }
    finally { setSaving(false) }
  }

  const handleDelete = async () => {
    if (!deleteId) return; setDeleting(true)
    try { await api.delete(`/admin/social-platforms/${deleteId}`); setDeleteId(null); notify("Deleted", "success"); load() }
    catch { notify("Failed to delete", "error") }
    finally { setDeleting(false) }
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div><h1 className="text-2xl font-bold">Social Platforms</h1><p className="text-muted-foreground text-sm mt-1">Manage social and website link platforms</p></div>
          {!showForm && <Button onClick={() => setShowForm(true)} size="sm"><Plus className="mr-1 h-4 w-4" />Add Platform</Button>}
        </div>

        {showForm && (
          <Card>
            <CardHeader><CardTitle className="text-lg">{editId ? "Edit" : "New"} Social Platform</CardTitle><CardDescription>Instagram, Facebook, Website, etc.</CardDescription></CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4">
                <div className="grid gap-2"><Label>Name</Label><Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Instagram" /></div>
                <div className="grid gap-2"><Label>Display Name</Label><Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder="e.g. Visit Instagram" /></div>
                <div className="grid gap-2"><Label>Primary Color</Label><div className="flex gap-2 items-center"><Input value={primaryColor} onChange={(e) => setPrimaryColor(e.target.value)} className="w-28" /><div className="w-8 h-8 rounded border" style={{ backgroundColor: primaryColor }} /></div></div>
                <div className="grid gap-2"><Label>Sort Order</Label><Input type="number" value={sortOrder} onChange={(e) => setSortOrder(Number(e.target.value))} /></div>
                <div className="grid gap-2"><Label>Logo URL</Label>
                  <div className="flex gap-2"><Input value={logoUrl} onChange={(e) => setLogoUrl(e.target.value)} placeholder="https://... or upload" className="flex-1" />
                  <Button variant="outline" size="sm" type="button" onClick={() => {
                    const input = document.createElement("input")
                    input.type = "file"; input.accept = "image/*"
                    input.onchange = async () => {
                      const file = input.files?.[0]; if (!file) return
                      const formData = new FormData(); formData.append("file", file)
                      try { const res = await api.upload<{ data: { url: string } }>("/upload?folder=platforms", formData); setLogoUrl(res.data.url); notify("Logo uploaded", "success") }
                      catch { notify("Upload failed", "error") }
                    }
                    input.click()
                  }}>Upload</Button></div>
                  {logoUrl && <div className="flex items-center gap-2 mt-1"><div className="w-8 h-8 rounded border overflow-hidden bg-muted"><img src={logoUrl} alt="logo" className="w-full h-full object-cover" /></div><span className="text-xs text-muted-foreground truncate">Preview</span></div>}
                </div>
              </div>
              <div className="flex gap-2 mt-4"><Button onClick={handleSave} disabled={saving}>{saving ? "Saving..." : "Save"}</Button><Button variant="ghost" onClick={reset}>Cancel</Button></div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader><CardTitle className="text-lg">All Platforms ({platforms.length})</CardTitle></CardHeader>
          <CardContent>
            {loading ? <TableSkeleton columns={4} rows={3} /> : platforms.length === 0 ? <EmptyState icon={<Share2 className="h-8 w-8" />} title="No platforms yet" description="Add social platforms to configure restaurant links" /> : (
              <Table>
                <TableHeader><TableRow><TableHead className="w-10">#</TableHead><TableHead>Name</TableHead><TableHead>Slug</TableHead><TableHead>Color</TableHead><TableHead className="w-24">Actions</TableHead></TableRow></TableHeader>
                <TableBody>
                  {platforms.map((p) => (
                    <TableRow key={p.id}>
                      <TableCell className="text-muted-foreground text-sm">{p.sort_order}</TableCell>
                      <TableCell className="font-medium">{p.display_name}</TableCell>
                      <TableCell className="text-muted-foreground text-sm">{p.slug}</TableCell>
                      <TableCell><div className="flex items-center gap-2"><div className="w-4 h-4 rounded" style={{ backgroundColor: p.primary_color }} /><span className="text-xs font-mono">{p.primary_color}</span></div></TableCell>
                      <TableCell>
                        <div className="flex gap-1">
                          <Button size="sm" variant="ghost" onClick={() => { setEditId(p.id); setName(p.name); setDisplayName(p.display_name); setPrimaryColor(p.primary_color); setLogoUrl(p.logo_url || ""); setSortOrder(p.sort_order); setShowForm(true) }}><Pencil className="h-4 w-4" /></Button>
                          <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeleteId(p.id)}><Trash2 className="h-4 w-4" /></Button>
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
          <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Delete Platform</AlertDialogTitle><AlertDialogDescription>This removes the platform from the list.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter><AlertDialogCancel>Cancel</AlertDialogCancel><AlertDialogAction onClick={handleDelete} disabled={deleting} className="bg-destructive text-destructive-foreground">{deleting ? "Deleting..." : "Delete"}</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
        </AlertDialog>
      </div>
    </ErrorBoundary>
  )
}
