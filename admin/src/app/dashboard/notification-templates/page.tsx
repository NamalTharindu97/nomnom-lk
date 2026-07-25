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
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
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

const templateSchema = z.object({
  name: z.string().min(1, "Name is required"),
  title: z.string().min(1, "Title is required"),
  body: z.string().min(1, "Body is required"),
})

type TemplateForm = z.infer<typeof templateSchema>

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
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Template | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<TemplateForm>({
    resolver: zodResolver(templateSchema),
    defaultValues: {
      name: "",
      title: "",
      body: "",
    },
  })

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
    reset({ name: "", title: "", body: "" })
  }

  function startEdit(t: Template) {
    setEditing(t)
    reset({ name: t.name, title: t.title, body: t.body })
  }

  async function onSave(data: TemplateForm) {
    setSaving(true)
    try {
      if (editing) {
        await api.put(`/admin/notification-templates/${editing.id}`, data)
        notify("Template updated", "success")
      } else {
        await api.post("/admin/notification-templates", data)
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
                  {...register("name")}
                  placeholder="e.g., Welcome Message"
                />
                {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
              </div>
              <div className="grid gap-2">
                <Label htmlFor="ttitle">Title</Label>
                <Input
                  id="ttitle"
                  {...register("title")}
                  placeholder="Hello {{name}}!"
                />
                {errors.title && <p className="text-xs text-destructive">{errors.title.message}</p>}
              </div>
              <div className="grid gap-2">
                <Label htmlFor="tbody">Body</Label>
                <Textarea
                  id="tbody"
                  {...register("body")}
                  placeholder="Check out our new offer at {{restaurant}}..."
                  rows={4}
                />
                {errors.body && <p className="text-xs text-destructive">{errors.body.message}</p>}
              </div>
              <div className="flex gap-2">
                <Button onClick={handleSubmit(onSave)} disabled={saving}>
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
