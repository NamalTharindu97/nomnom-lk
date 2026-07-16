"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
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
import { Plus, Pencil, Trash2, Mail } from "lucide-react"

interface Template {
  id: string
  name: string
  title: string
  body: string
  created_at: string
}

export default function NotificationTemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Template | null>(null)
  const [name, setName] = useState("")
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Template | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Template[] }>("/admin/notification-templates")
      setTemplates(res.data || [])
    } catch {
      setTemplates([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  function startCreate() {
    setEditing(null)
    setName("")
    setTitle("")
    setBody("")
  }

  function startEdit(t: Template) {
    setEditing(t)
    setName(t.name)
    setTitle(t.title)
    setBody(t.body)
  }

  async function handleSave() {
    if (!name || !title || !body) {
      notify("All fields are required", "error")
      return
    }
    setSaving(true)
    try {
      if (editing) {
        await api.put(`/admin/notification-templates/${editing.id}`, { name, title, body })
        notify("Template updated", "success")
      } else {
        await api.post("/admin/notification-templates", { name, title, body })
        notify("Template created", "success")
      }
      startCreate()
      load()
    } catch { notify("Failed to save template") }
    setSaving(false)
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await api.delete(`/admin/notification-templates/${deleteTarget.id}`)
      notify("Template deleted", "success")
      setDeleteTarget(null)
      load()
    } catch { notify("Failed to delete template") }
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notification Templates</h1>
          <p className="text-muted-foreground">Create reusable push notification templates</p>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>{editing ? "Edit Template" : "New Template"}</CardTitle>
              <CardDescription>Use {"{{variable}}"} placeholders for dynamic content</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-2">
                <Label htmlFor="tname">Template Name</Label>
                <Input
                  id="tname"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Welcome Message"
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="ttitle">Title</Label>
                <Input
                  id="ttitle"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Hello {{name}}!"
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="tbody">Body</Label>
                <Textarea
                  id="tbody"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Check out our new offer at {{restaurant}}..."
                  rows={4}
                />
              </div>
              <div className="flex gap-2">
                <Button onClick={handleSave} disabled={saving}>
                  {saving ? "Saving..." : editing ? "Update" : "Create"}
                </Button>
                {editing && (
                  <Button variant="outline" onClick={startCreate}>Cancel</Button>
                )}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>All Templates</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Title</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableSkeleton columns={3} />
                  ) : templates.length === 0 ? (
                    <EmptyState
                      icon={<Mail className="size-10 text-muted-foreground/50" />}
                      title="No templates"
                      description="Create your first notification template."
                    />
                  ) : (
                    templates.map((t) => (
                      <TableRow key={t.id}>
                        <TableCell className="font-medium">{t.name}</TableCell>
                        <TableCell className="text-sm text-muted-foreground truncate max-w-xs">{t.title}</TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-1">
                            <Button size="icon" variant="ghost" onClick={() => startEdit(t)}>
                              <Pencil className="size-4" />
                            </Button>
                            <AlertDialog>
                              <AlertDialogTrigger asChild>
                                <Button size="icon" variant="ghost" onClick={() => setDeleteTarget(t)}>
                                  <Trash2 className="size-4 text-destructive" />
                                </Button>
                              </AlertDialogTrigger>
                              <AlertDialogContent>
                                <AlertDialogHeader>
                                  <AlertDialogTitle>Delete Template</AlertDialogTitle>
                                  <AlertDialogDescription>
                                    Delete <strong>{t.name}</strong>? This cannot be undone.
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
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      </div>
    </ErrorBoundary>
  )
}
