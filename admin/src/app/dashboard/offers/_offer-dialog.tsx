"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2, Upload, X } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const offerSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().min(1, "Description is required"),
  original_price: z.number().positive("Must be positive"),
  offer_price: z.number().positive("Must be positive"),
  start_date: z.string().min(1, "Start date is required"),
  end_date: z.string().min(1, "End date is required"),
  restaurant_id: z.string().min(1, "Restaurant is required"),
  title_si: z.string().optional(),
  title_ta: z.string().optional(),
  description_si: z.string().optional(),
  description_ta: z.string().optional(),
})

type OfferForm = z.infer<typeof offerSchema>

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
  const [saving, setSaving] = useState(false)
  const [restaurants, setRestaurants] = useState<RestaurantOption[]>([])
  const [imageFiles, setImageFiles] = useState<File[]>([])
  const [uploadingImages, setUploadingImages] = useState(false)

  const isEdit = !!offer

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    formState: { errors },
  } = useForm<OfferForm>({
    resolver: zodResolver(offerSchema),
    defaultValues: {
      title: "",
      description: "",
      original_price: 0,
      offer_price: 0,
      start_date: "",
      end_date: "",
      restaurant_id: "",
      title_si: "",
      title_ta: "",
      description_si: "",
      description_ta: "",
    },
  })

  useEffect(() => {
    api.get<{ data: RestaurantOption[] }>("/restaurants").then((res) => {
      setRestaurants(res.data || [])
    }).catch(() => {})
  }, [])

  useEffect(() => {
    if (offer) {
      reset({
        title: offer.title || "",
        description: offer.description || "",
        original_price: offer.original_price || 0,
        offer_price: offer.offer_price || 0,
        start_date: offer.start_date ? offer.start_date.slice(0, 10) : "",
        end_date: offer.end_date ? offer.end_date.slice(0, 10) : "",
        restaurant_id: offer.restaurant_id || "",
        title_si: offer.title_si || "",
        title_ta: offer.title_ta || "",
        description_si: offer.description_si || "",
        description_ta: offer.description_ta || "",
      })
    } else {
      reset({
        title: "",
        description: "",
        original_price: 0,
        offer_price: 0,
        start_date: "",
        end_date: "",
        restaurant_id: "",
        title_si: "",
        title_ta: "",
        description_si: "",
        description_ta: "",
      })
      setImageFiles([])
    }
  }, [offer, reset])

  function onFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || [])
    setImageFiles((prev) => [...prev, ...files])
  }

  function removeFile(index: number) {
    setImageFiles((prev) => prev.filter((_, i) => i !== index))
  }

  async function uploadFiles(): Promise<string[]> {
    if (imageFiles.length === 0) return []
    setUploadingImages(true)
    try {
      const formData = new FormData()
      imageFiles.forEach((f) => formData.append("files", f))
      const res = await api.upload<{ data: { url: string }[] }>("/upload/multiple", formData)
      setUploadingImages(false)
      return (res.data || []).map((f) => f.url)
    } catch {
      setUploadingImages(false)
      return []
    }
  }

  async function onSave(data: OfferForm) {
    setSaving(true)
    try {
      const uploadedUrls = await uploadFiles()
      const existingUrls = offer?.image_urls || []
      const allUrls = [...existingUrls, ...uploadedUrls]

      const body = {
        ...data,
        image_urls: allUrls,
      }

      if (isEdit) {
        await api.put(`/offers/${offer.id}`, body)
        notify("Offer updated", "success")
      } else {
        await api.post("/offers", body)
        notify("Offer created", "success")
      }
      onSaved()
      onClose()
    } catch (err: any) {
      notify(err?.message || "Failed to save offer", "error")
    }
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

        <form onSubmit={handleSubmit(onSave)} className="grid gap-4 py-2">
          <div className="grid gap-2">
            <Label htmlFor="restaurant_id">Restaurant</Label>
            <Select
              defaultValue={offer?.restaurant_id || ""}
              onValueChange={(v) => setValue("restaurant_id", v, { shouldValidate: true })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select a restaurant" />
              </SelectTrigger>
              <SelectContent>
                {restaurants.map((r) => (
                  <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.restaurant_id && (
              <p className="text-xs text-destructive">{errors.restaurant_id.message}</p>
            )}
          </div>

          <div className="grid gap-2">
            <Label htmlFor="title">Title</Label>
            <Input id="title" {...register("title")} />
            {errors.title && <p className="text-xs text-destructive">{errors.title.message}</p>}
          </div>

          <div className="grid gap-2">
            <Label htmlFor="description">Description</Label>
            <textarea
              id="description"
              className="border-input flex min-h-[80px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
              {...register("description")}
            />
            {errors.description && <p className="text-xs text-destructive">{errors.description.message}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="grid gap-2">
              <Label htmlFor="original_price">Original Price (LKR)</Label>
              <Input id="original_price" type="number" {...register("original_price", { valueAsNumber: true })} />
              {errors.original_price && <p className="text-xs text-destructive">{errors.original_price.message}</p>}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="offer_price">Offer Price (LKR)</Label>
              <Input id="offer_price" type="number" {...register("offer_price", { valueAsNumber: true })} />
              {errors.offer_price && <p className="text-xs text-destructive">{errors.offer_price.message}</p>}
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

          <div className="grid gap-2">
            <Label>Images</Label>
            <div className="flex items-center gap-2">
              <Input type="file" multiple accept="image/*" onChange={onFileSelect} className="file:text-xs" />
            </div>
            {imageFiles.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-1">
                {imageFiles.map((f, i) => (
                  <span key={i} className="flex items-center gap-1 rounded-md bg-muted px-2 py-1 text-xs">
                    {f.name}
                    <button type="button" onClick={() => removeFile(i)} className="text-destructive hover:opacity-70">
                      <X className="size-3" />
                    </button>
                  </span>
                ))}
              </div>
            )}
            {offer?.image_urls?.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-1">
                {offer.image_urls.map((url: string, i: number) => (
                  <span key={i} className="rounded-md bg-muted px-2 py-1 text-xs truncate max-w-40">
                    {url.split("/").pop()}
                  </span>
                ))}
              </div>
            )}
          </div>

          <div className="border-t pt-4">
            <h4 className="text-sm font-semibold mb-3">Translations</h4>
            <div className="grid gap-4">
              <div>
                <h5 className="text-xs font-medium text-muted-foreground mb-2">Sinhala (සිංහල)</h5>
                <div className="grid gap-2">
                  <div className="grid gap-1">
                    <Label htmlFor="title_si">Title (SI)</Label>
                    <Input id="title_si" {...register("title_si")} />
                  </div>
                  <div className="grid gap-1">
                    <Label htmlFor="description_si">Description (SI)</Label>
                    <textarea
                      id="description_si"
                      className="border-input flex min-h-[60px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
                      {...register("description_si")}
                    />
                  </div>
                </div>
              </div>
              <div>
                <h5 className="text-xs font-medium text-muted-foreground mb-2">Tamil (தமிழ்)</h5>
                <div className="grid gap-2">
                  <div className="grid gap-1">
                    <Label htmlFor="title_ta">Title (TA)</Label>
                    <Input id="title_ta" {...register("title_ta")} />
                  </div>
                  <div className="grid gap-1">
                    <Label htmlFor="description_ta">Description (TA)</Label>
                    <textarea
                      id="description_ta"
                      className="border-input flex min-h-[60px] w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs"
                      {...register("description_ta")}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" type="button" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saving || uploadingImages}>
              {(saving || uploadingImages) && <Loader2 className="mr-2 size-4 animate-spin" />}
              {isEdit ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
