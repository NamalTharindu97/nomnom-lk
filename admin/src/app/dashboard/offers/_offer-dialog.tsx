"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { api } from "@/lib/api"
import { Loader2 } from "lucide-react"

interface OfferData {
  title: string
  description: string
  original_price: number
  offer_price: number
  start_date: string
  end_date: string
  image_urls: string
  restaurant_id: string
}

const emptyForm: OfferData = {
  title: "",
  description: "",
  original_price: 0,
  offer_price: 0,
  start_date: "",
  end_date: "",
  image_urls: "",
  restaurant_id: "",
}

interface RestaurantOption {
  id: string
  name: string
}

interface OfferDialogProps {
  open: boolean
  onClose: () => void
  onSaved: () => void
  offer?: any | null
}

export default function OfferDialog({ open, onClose, onSaved, offer }: OfferDialogProps) {
  const [form, setForm] = useState<OfferData>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [restaurants, setRestaurants] = useState<RestaurantOption[]>([])

  const isEdit = !!offer

  useEffect(() => {
    api.get<{ data: RestaurantOption[] }>("/restaurants").then((res) => {
      setRestaurants(res.data || [])
    }).catch(() => {})
  }, [])

  useEffect(() => {
    if (offer) {
      setForm({
        title: offer.title || "",
        description: offer.description || "",
        original_price: offer.original_price || 0,
        offer_price: offer.offer_price || 0,
        start_date: offer.start_date ? offer.start_date.slice(0, 10) : "",
        end_date: offer.end_date ? offer.end_date.slice(0, 10) : "",
        image_urls: (offer.image_urls || []).join(", "),
        restaurant_id: offer.restaurant_id || "",
      })
    } else {
      setForm(emptyForm)
    }
  }, [offer])

  function set<K extends keyof OfferData>(key: K, value: OfferData[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSave() {
    setSaving(true)
    try {
      const body = {
        ...form,
        original_price: Number(form.original_price),
        offer_price: Number(form.offer_price),
        image_urls: form.image_urls
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
      }

      if (isEdit) {
        await api.put(`/offers/${offer.id}`, body)
      } else {
        await api.post("/offers", body)
      }
      onSaved()
      onClose()
    } catch {}
    setSaving(false)
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose() }}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Offer" : "New Offer"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update the offer details below." : "Fill in the details to create a new offer."}
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-2">
          <div className="grid gap-2">
            <Label htmlFor="restaurant">Restaurant</Label>
            <Select value={form.restaurant_id} onValueChange={(v) => set("restaurant_id", v)}>
              <SelectTrigger>
                <SelectValue placeholder="Select a restaurant" />
              </SelectTrigger>
              <SelectContent>
                {restaurants.map((r) => (
                  <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="title">Title</Label>
            <Input id="title" value={form.title} onChange={(e) => set("title", e.target.value)} />
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

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="original_price">Original Price (LKR)</Label>
              <Input id="original_price" type="number" value={form.original_price} onChange={(e) => set("original_price", Number(e.target.value))} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="offer_price">Offer Price (LKR)</Label>
              <Input id="offer_price" type="number" value={form.offer_price} onChange={(e) => set("offer_price", Number(e.target.value))} />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="start_date">Start Date</Label>
              <Input id="start_date" type="date" value={form.start_date} onChange={(e) => set("start_date", e.target.value)} />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="end_date">End Date</Label>
              <Input id="end_date" type="date" value={form.end_date} onChange={(e) => set("end_date", e.target.value)} />
            </div>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="image_urls">Image URLs (comma-separated)</Label>
            <Input id="image_urls" value={form.image_urls} onChange={(e) => set("image_urls", e.target.value)} />
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
