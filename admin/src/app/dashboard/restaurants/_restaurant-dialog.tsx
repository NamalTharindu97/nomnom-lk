"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2, X } from "lucide-react"

interface RestaurantForm {
  name: string
  slug: string
  address: string
  cuisine_tags: string
  description: string
  phone: string
  owner_id: string
  name_si: string
  name_ta: string
  description_si: string
  description_ta: string
}

const emptyForm: RestaurantForm = {
  name: "",
  slug: "",
  address: "",
  cuisine_tags: "",
  description: "",
  phone: "",
  owner_id: "",
  name_si: "",
  name_ta: "",
  description_si: "",
  description_ta: "",
}

interface OwnerOption {
  id: string
  name: string
  email: string
}

interface RestaurantDialogProps {
  open: boolean
  onClose: () => void
  onSaved: () => void
  restaurant?: any | null
}

export default function RestaurantDialog({ open, onClose, onSaved, restaurant }: RestaurantDialogProps) {
  const [form, setForm] = useState<RestaurantForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [coverFile, setCoverFile] = useState<File | null>(null)
  const [coverPreview, setCoverPreview] = useState<string | null>(null)
  const [uploadingImage, setUploadingImage] = useState(false)
  const [owners, setOwners] = useState<OwnerOption[]>([])

  const isEdit = !!restaurant

  useEffect(() => {
    if (open) {
      api.get<{ data: OwnerOption[] }>("/users?role=restaurant_owner&per_page=100")
        .then((res) => setOwners(res.data || []))
        .catch(() => {})
    }
  }, [open])

  useEffect(() => {
    if (restaurant) {
      setForm({
        name: restaurant.name || "",
        slug: restaurant.slug || "",
        address: restaurant.address || "",
        cuisine_tags: (restaurant.cuisine_tags || []).join(", "),
        description: restaurant.description || "",
        phone: restaurant.contact_phone || "",
        owner_id: restaurant.owner_id || "",
        name_si: restaurant.name_si || "",
        name_ta: restaurant.name_ta || "",
        description_si: restaurant.description_si || "",
        description_ta: restaurant.description_ta || "",
      })
      setCoverPreview(restaurant.cover_image || null)
    } else {
      setForm(emptyForm)
      setCoverFile(null)
      setCoverPreview(null)
    }
  }, [restaurant])

  function set<K extends keyof RestaurantForm>(key: K, value: RestaurantForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  function onFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] || null
    setCoverFile(file)
    if (file) {
      const reader = new FileReader()
      reader.onload = () => setCoverPreview(reader.result as string)
      reader.readAsDataURL(file)
    } else {
      setCoverPreview(restaurant?.cover_image || null)
    }
  }

  function removeFile() {
    setCoverFile(null)
    setCoverPreview(null)
  }

  async function uploadFile(): Promise<string | null> {
    if (!coverFile) return restaurant?.cover_image || null
    setUploadingImage(true)
    try {
      const formData = new FormData()
      formData.append("files", coverFile)
      const res = await api.upload<{ data: { url: string }[] }>("/upload/multiple", formData)
      setUploadingImage(false)
      return (res.data?.[0]?.url) || null
    } catch {
      setUploadingImage(false)
      return null
    }
  }

  async function handleSave() {
    if (!form.name.trim() || !form.slug.trim()) {
      notify("Name and slug are required", "error")
      return
    }
    setSaving(true)
    try {
      const coverImage = await uploadFile()

      const { phone, owner_id, ...restForm } = form
      const body: Record<string, any> = {
        ...restForm,
        contact_phone: phone || null,
        cuisine_tags: form.cuisine_tags.split(",").map((s) => s.trim()).filter(Boolean),
      }
      if (owner_id && owner_id !== "__none") body.owner_id = owner_id

      if (coverImage) {
        body.cover_image = coverImage
      }

      if (isEdit) {
        await api.put(`/restaurants/${restaurant.id}`, body)
        notify("Restaurant updated", "success")
      } else {
        await api.post("/restaurants", body)
        notify("Restaurant created", "success")
      }
      onSaved()
      onClose()
    } catch (err: any) {
      notify(err?.message || "Failed to save restaurant", "error")
    }
    setSaving(false)
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose() }}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Restaurant" : "New Restaurant"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update the restaurant details below." : "Fill in the details to create a new restaurant."}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-2">
          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="name">Name</Label>
              <Input id="name" value={form.name} onChange={(e) => set("name", e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="slug">Slug</Label>
              <Input id="slug" value={form.slug} onChange={(e) => set("slug", e.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="address">Address</Label>
              <Input id="address" value={form.address} onChange={(e) => set("address", e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="phone">Phone</Label>
              <Input id="phone" value={form.phone} onChange={(e) => set("phone", e.target.value)} />
            </div>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="cuisine_tags">Cuisine Tags (comma-separated)</Label>
            <Input id="cuisine_tags" value={form.cuisine_tags} onChange={(e) => set("cuisine_tags", e.target.value)} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="description">Description</Label>
            <textarea
              id="description"
              className="border-input flex min-h-[80px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
              value={form.description}
              onChange={(e) => set("description", e.target.value)}
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="owner">Owner</Label>
            <Select value={form.owner_id} onValueChange={(v) => set("owner_id", v)}>
              <SelectTrigger id="owner">
                <SelectValue placeholder="No owner (admin-managed)" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__none">No owner</SelectItem>
                {owners.map((o) => (
                  <SelectItem key={o.id} value={o.id}>
                    {o.name} ({o.email})
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid gap-2">
            <Label>Cover Image</Label>
            <div className="flex items-center gap-2">
              <Input type="file" accept="image/*" onChange={onFileSelect} className="file:text-xs" />
              {(coverPreview || restaurant?.cover_image) && (
                <Button type="button" variant="ghost" size="icon" onClick={removeFile} className="shrink-0">
                  <X className="size-4 text-destructive" />
                </Button>
              )}
            </div>
            {coverPreview && (
              <div className="relative mt-1 overflow-hidden rounded-md border">
                <img src={coverPreview} alt="Cover preview" className="h-32 w-full object-cover" />
              </div>
            )}
          </div>

          <div className="border-t pt-4">
            <h4 className="text-sm font-semibold mb-3">Translations</h4>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <h5 className="text-xs font-medium text-muted-foreground mb-2">Sinhala (සිංහල)</h5>
                <div className="grid gap-2">
                  <div className="grid gap-1">
                    <Label htmlFor="name_si">Name</Label>
                    <Input id="name_si" value={form.name_si} onChange={(e) => set("name_si", e.target.value)} />
                  </div>
                  <div className="grid gap-1">
                    <Label htmlFor="description_si">Description</Label>
                    <textarea
                      id="description_si"
                      className="border-input flex min-h-[60px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
                      value={form.description_si}
                      onChange={(e) => set("description_si", e.target.value)}
                    />
                  </div>
                </div>
              </div>
              <div>
                <h5 className="text-xs font-medium text-muted-foreground mb-2">Tamil (தமிழ்)</h5>
                <div className="grid gap-2">
                  <div className="grid gap-1">
                    <Label htmlFor="name_ta">Name</Label>
                    <Input id="name_ta" value={form.name_ta} onChange={(e) => set("name_ta", e.target.value)} />
                  </div>
                  <div className="grid gap-1">
                    <Label htmlFor="description_ta">Description</Label>
                    <textarea
                      id="description_ta"
                      className="border-input flex min-h-[60px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
                      value={form.description_ta}
                      onChange={(e) => set("description_ta", e.target.value)}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave} disabled={saving || uploadingImage}>
            {(saving || uploadingImage) && <Loader2 className="mr-2 size-4 animate-spin" />}
            {isEdit ? "Update" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
