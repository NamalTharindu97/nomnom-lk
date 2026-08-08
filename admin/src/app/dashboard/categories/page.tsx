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
import { Plus, Pencil, Trash2, Folder } from "lucide-react"

interface Category {
  id: string
  name: string
  slug: string
  created_at: string
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Category | null>(null)
  const [name, setName] = useState("")
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Category | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Category[] }>("/admin/categories")
      setCategories(res.data || [])
    } catch { setCategories([]) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  function startCreate() { setEditing(null); setName("") }
  function startEdit(c: Category) { setEditing(c); setName(c.name) }

  async function handleSave() {
    if (!name.trim()) { notify("Name is required", "error"); return }
    setSaving(true)
    try {
      if (editing) {
        await api.put(`/admin/categories/${editing.id}`, { name: name.trim() })
        notify("Category updated", "success")
      } else {
        await api.post("/admin/categories", { name: name.trim() })
        notify("Category created", "success")
      }
      startCreate(); load()
    } catch { notify("Failed to save category") }
    setSaving(false)
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try { await api.delete(`/admin/categories/${deleteTarget.id}`); notify("Category deleted", "success"); setDeleteTarget(null); load() }
    catch { notify("Failed to delete category") }
  }

  return (
    <ErrorBoundary><div className="space-y-6">
      <div><h1 className="text-2xl font-bold tracking-tight">Categories</h1><p className="text-muted-foreground">Organize offers by category</p></div>
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle>{editing ? "Edit Category" : "New Category"}</CardTitle><CardDescription>Create categories to organize your offers</CardDescription></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-2"><Label htmlFor="cat-name">Name</Label><Input id="cat-name" value={name} onChange={e => setName(e.target.value)} placeholder="Pizza & Pasta" /></div>
            <div className="flex gap-2">
              <Button onClick={handleSave} disabled={saving}>{saving ? "Saving..." : editing ? "Update" : "Create"}</Button>
              {editing && <Button variant="outline" onClick={startCreate}>Cancel</Button>}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>All Categories</CardTitle></CardHeader>
          <CardContent>
            <Table>
              <TableHeader><TableRow><TableHead>Name</TableHead><TableHead>Slug</TableHead><TableHead className="text-right">Actions</TableHead></TableRow></TableHeader>
              <TableBody>
                {loading ? <TableSkeleton columns={3} /> : categories.length === 0 ? <EmptyState icon={<Folder className="size-10 text-muted-foreground/50" />} title="No categories" description="Create your first category." /> : categories.map(c => (
                  <TableRow key={c.id}>
                    <TableCell className="font-medium">{c.name}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">{c.slug}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button size="icon" variant="ghost" onClick={() => startEdit(c)}><Pencil className="size-4" /></Button>
                        <AlertDialog>
                          <AlertDialogTrigger asChild><Button size="icon" variant="ghost" onClick={() => setDeleteTarget(c)}><Trash2 className="size-4 text-destructive" /></Button></AlertDialogTrigger>
                          <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Delete Category</AlertDialogTitle><AlertDialogDescription>Delete <strong>{c.name}</strong>? This cannot be undone.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter><AlertDialogCancel onClick={() => setDeleteTarget(null)}>Cancel</AlertDialogCancel><AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">Delete</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
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
    </div></ErrorBoundary>
  )
}
