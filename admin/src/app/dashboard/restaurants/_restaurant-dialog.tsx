"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2 } from "lucide-react"

interface RestaurantForm {
  name: string
  slug: string
  address: string
  cuisine_tags: string
  description: string
  phone: string
}

const emptyForm: RestaurantForm = {
  name: "",
  slug: "",
  address: "",
  cuisine_tags: "",
  description: "",
  phone: "",
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

  const isEdit = !!restaurant

  useEffect(() => {
    if (restaurant) {
      setForm({
        name: restaurant.name || "",
        slug: restaurant.slug || "",
        address: restaurant.address || "",
        cuisine_tags: (restaurant.cuisine_tags || []).join(", "),
        description: restaurant.description || "",
        phone: restaurant.phone || "",
      })
    } else {
      setForm(emptyForm)
    }
  }, [restaurant])

  function set<K extends keyof RestaurantForm>(key: K, value: RestaurantForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSave() {
    if (!form.name.trim() || !form.slug.trim()) {
      notify("Name and slug are required", "error")
      return
    }
    setSaving(true)
    try {
      const body = {
        ...form,
        cuisine_tags: form.cuisine_tags.split(",").map((s) => s.trim()).filter(Boolean),
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
      <DialogContent className="sm:max-w-lg">
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
          <div className="grid gap-2">
            <Label htmlFor="address">Address</Label>
            <Input id="address" value={form.address} onChange={(e) => set("address", e.target.value)} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="phone">Phone</Label>
            <Input id="phone" value={form.phone} onChange={(e) => set("phone", e.target.value)} />
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
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave} disabled={saving}>
            {saving && <Loader2 className="mr-2 size-4 animate-spin" />}
            {isEdit ? "Update" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
