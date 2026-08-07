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
import { Plus, Pencil, Trash2, Tags } from "lucide-react"
import { useAuth } from "@/hooks/use-auth"

interface CuisineTag {
  id: string
  name: string
  created_at: string
}

export default function CuisineTagsPage() {
  const { isViewer, isReadOnly } = useAuth()
  const [tags, setTags] = useState<CuisineTag[]>([])
  const [loading, setLoading] = useState(true)
  const [newName, setNewName] = useState("")
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editName, setEditName] = useState("")
  const [saving, setSaving] = useState(false)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [showForm, setShowForm] = useState(false)

  const loadTags = useCallback(async () => {
    try {
      const data = await api.get<CuisineTag[]>("/admin/cuisine-tags")
      setTags(Array.isArray(data) ? data : (data as any)?.data || [])
    } catch {
      notify("Failed to load cuisine tags", "error")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadTags() }, [loadTags])

  const handleCreate = async () => {
    const name = newName.trim()
    if (!name) { notify("Name is required", "error"); return }
    setSaving(true)
    try {
      await api.post("/admin/cuisine-tags", { name })
      setNewName("")
      setShowForm(false)
      notify("Cuisine tag created", "success")
      loadTags()
    } catch {
      notify("Failed to create cuisine tag", "error")
    } finally {
      setSaving(false)
    }
  }

  const handleUpdate = async (id: string) => {
    const name = editName.trim()
    if (!name) { notify("Name is required", "error"); return }
    setSaving(true)
    try {
      await api.put(`/admin/cuisine-tags/${id}`, { name })
      setEditingId(null)
      notify("Cuisine tag updated", "success")
      loadTags()
    } catch {
      notify("Failed to update cuisine tag", "error")
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteId) return
    setDeleting(true)
    try {
      await api.delete(`/admin/cuisine-tags/${deleteId}`)
      setDeleteId(null)
      notify("Cuisine tag deleted", "success")
      loadTags()
    } catch {
      notify("Failed to delete cuisine tag", "error")
    } finally {
      setDeleting(false)
    }
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Cuisine Tags</h1>
            <p className="text-muted-foreground text-sm mt-1">
               {isViewer ? "Explore predefined restaurant filtering tags" : "Manage predefined cuisine tags for restaurant filtering"}
            </p>
          </div>
           {!isReadOnly && !showForm && (
            <Button onClick={() => setShowForm(true)} size="sm">
              <Plus className="mr-1 h-4 w-4" /> Add Tag
            </Button>
          )}
        </div>

        {!isReadOnly && showForm && (
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">New Cuisine Tag</CardTitle>
              <CardDescription>Add a new tag to the predefined list</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex items-end gap-3">
                <div className="flex-1">
                  <Label htmlFor="tag-name">Tag Name</Label>
                  <Input
                    id="tag-name"
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    placeholder="e.g. Indian"
                    onKeyDown={(e) => e.key === "Enter" && handleCreate()}
                  />
                </div>
                <Button onClick={handleCreate} disabled={saving || !newName.trim()}>
                  {saving ? "Saving..." : "Save"}
                </Button>
                <Button variant="ghost" onClick={() => { setShowForm(false); setNewName("") }}>
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">All Tags ({tags.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <TableSkeleton columns={isReadOnly ? 1 : 3} rows={8} />
            ) : tags.length === 0 ? (
              <EmptyState
                icon={<Tags className="h-8 w-8" />}
                title={isViewer ? "No cuisine tags available" : "No cuisine tags yet"}
                description={isViewer ? "Cuisine tags will appear here when available." : "Add tags to help users filter restaurants by cuisine type"}
              />
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    {!isViewer && <TableHead>Created</TableHead>}
                    {!isReadOnly && <TableHead className="w-24">Actions</TableHead>}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {tags.map((tag) => (
                    <TableRow key={tag.id}>
                      <TableCell>
                        {editingId === tag.id ? (
                          <Input
                            value={editName}
                            onChange={(e) => setEditName(e.target.value)}
                            onKeyDown={(e) => e.key === "Enter" && handleUpdate(tag.id)}
                            className="max-w-xs"
                          />
                        ) : (
                          <span className="font-medium">{tag.name}</span>
                        )}
                      </TableCell>
                      {!isViewer && <TableCell className="text-muted-foreground text-sm">
                        {new Date(tag.created_at).toLocaleDateString()}
                      </TableCell>}
                      {!isReadOnly && <TableCell>
                        <div className="flex gap-1">
                          {editingId === tag.id ? (
                            <>
                              <Button size="sm" variant="ghost" onClick={() => handleUpdate(tag.id)} disabled={saving}>
                                <Pencil className="h-4 w-4" />
                              </Button>
                              <Button size="sm" variant="ghost" onClick={() => setEditingId(null)}>
                                Cancel
                              </Button>
                            </>
                          ) : (
                            <>
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => { setEditingId(tag.id); setEditName(tag.name) }}
                              >
                                <Pencil className="h-4 w-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="ghost"
                                className="text-destructive"
                                onClick={() => setDeleteId(tag.id)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </TableCell>}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        {!isReadOnly && <AlertDialog open={!!deleteId} onOpenChange={(o) => !o && setDeleteId(null)}>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Delete Cuisine Tag</AlertDialogTitle>
              <AlertDialogDescription>
                This will remove this tag from the list. Restaurants that already use this tag will still show it.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction onClick={handleDelete} disabled={deleting} className="bg-destructive text-destructive-foreground">
                {deleting ? "Deleting..." : "Delete"}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>}
      </div>
    </ErrorBoundary>
  )
}
