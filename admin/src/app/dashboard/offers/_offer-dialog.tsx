"use client"

import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { api, API_BASE } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2, Upload, X, GripVertical } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import ImageCropDialog from "@/components/image-crop-dialog"

function formatDateTimeLocal(date: Date): string {
  const pad = (n: number) => n.toString().padStart(2, "0")
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

const offerSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().min(1, "Description is required"),
  original_price: z.number().positive("Must be positive"),
  offer_price: z.number().positive("Must be positive"),
  start_date: z.string().min(1, "Start date is required"),
  end_date: z.string().min(1, "End date is required"),
  restaurant_id: z.string().min(1, "Restaurant is required"),
  publish_at: z.string().optional(),
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
  const [uploadingImages, setUploadingImages] = useState(false)

  const [croppedResults, setCroppedResults] = useState<Array<{ blob: Blob; previewUrl: string }>>([])
  const [pendingCropFiles, setPendingCropFiles] = useState<Array<{ dataUrl: string; file: File }>>([])
  const [currentCropIndex, setCurrentCropIndex] = useState(-1)
  const [removedUrls, setRemovedUrls] = useState<string[]>([])
  const [reorderedUrls, setReorderedUrls] = useState<string[]>([])
  const [dragIndex, setDragIndex] = useState<number | null>(null)

  const fileInputRef = useRef<HTMLInputElement>(null)

  const isEdit = !!offer
  const today = useMemo(() => new Date().toISOString().slice(0, 10), [])
  const imageOrigin = useMemo(() => API_BASE.replace('/api/v1', ''), [])

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<OfferForm>({
    resolver: zodResolver(offerSchema),
    defaultValues: {
      title: "",
      description: "",
      original_price: 0,
      offer_price: 0,
      start_date: today,
      end_date: today,
      restaurant_id: "",
      title_si: "",
      title_ta: "",
      description_si: "",
      description_ta: "",
    },
  })

  useEffect(() => {
    api.get<{ data: RestaurantOption[] }>("/dashboard/restaurants").then((res) => {
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
        publish_at: offer.publish_at ? offer.publish_at.slice(0, 16) : "",
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
        start_date: today,
        end_date: today,
        restaurant_id: "",
        title_si: "",
        title_ta: "",
        description_si: "",
        description_ta: "",
      })
    }
    resetCropState()
  }, [offer, reset])

  useEffect(() => {
    if (!open) {
      resetCropState()
    }
  }, [open])

  useEffect(() => {
    return () => {
      croppedResults.forEach(r => URL.revokeObjectURL(r.previewUrl))
      pendingCropFiles.forEach(f => URL.revokeObjectURL(f.dataUrl))
    }
  }, [])

  function resetCropState() {
    croppedResults.forEach(r => URL.revokeObjectURL(r.previewUrl))
    pendingCropFiles.forEach(f => URL.revokeObjectURL(f.dataUrl))
    setCroppedResults([])
    setPendingCropFiles([])
    setCurrentCropIndex(-1)
    setRemovedUrls([])
    setReorderedUrls([])
    setDragIndex(null)
    setUploadingImages(false)
    setSaving(false)
  }

  function onFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || [])
    const maxSize = 5 * 1024 * 1024
    const allowed = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg"]
    const valid = files.filter((f) => {
      const ext = "." + f.name.split(".").pop()?.toLowerCase()
      if (!allowed.includes(ext)) { notify(`Unsupported type: ${f.name}`, "error"); return false }
      if (f.size > maxSize) { notify(`File too large (>5MB): ${f.name}`, "error"); return false }
      return true
    })
    if (valid.length === 0) return
    if (fileInputRef.current) fileInputRef.current.value = ""

    const pending = valid.map(f => ({ dataUrl: URL.createObjectURL(f), file: f }))
    setPendingCropFiles(pending)
    setCurrentCropIndex(0)
  }

  const handleCropComplete = useCallback((blob: Blob) => {
    const previewUrl = URL.createObjectURL(blob)
    setCroppedResults(prev => [...prev, { blob, previewUrl }])

    const nextIndex = currentCropIndex + 1
    if (nextIndex < pendingCropFiles.length) {
      setCurrentCropIndex(nextIndex)
    } else {
      setCurrentCropIndex(-1)
      pendingCropFiles.forEach(f => URL.revokeObjectURL(f.dataUrl))
      setPendingCropFiles([])
    }
  }, [currentCropIndex, pendingCropFiles])

  const handleCropCancel = useCallback(() => {
    pendingCropFiles.forEach(f => URL.revokeObjectURL(f.dataUrl))
    setPendingCropFiles([])
    setCurrentCropIndex(-1)
  }, [pendingCropFiles])

  function removeCropped(index: number) {
    setCroppedResults(prev => {
      const item = prev[index]
      if (item) URL.revokeObjectURL(item.previewUrl)
      return prev.filter((_, i) => i !== index)
    })
  }

  function removeExistingUrl(url: string) {
    setRemovedUrls(prev => [...prev, url])
  }

  function restoreExistingUrl(url: string) {
    setRemovedUrls(prev => prev.filter(u => u !== url))
  }

  async function uploadCroppedBlobs(): Promise<string[]> {
    if (croppedResults.length === 0) return []
    setUploadingImages(true)
    try {
      const formData = new FormData()
      croppedResults.forEach(({ blob }) => {
        formData.append("files", blob, "cropped.jpg")
      })
      const res = await api.upload<{ data: { urls: string[] } }>("/upload/multiple", formData)
      return res.data?.urls || []
    } catch {
      notify("Image upload failed. Please try again.", "error")
      return []
    } finally {
      setUploadingImages(false)
    }
  }

  async function onSave(data: OfferForm) {
    setSaving(true)
    try {
      const croppedUrls = await uploadCroppedBlobs()
      const baseExisting = (offer?.image_urls || []).filter((u: string) => !removedUrls.includes(u))
      const existingUrls = reorderedUrls.length > 0 ? reorderedUrls : baseExisting
      const allUrls = croppedUrls.length > 0 ? croppedUrls : existingUrls

      const body: Record<string, any> = {
        ...data,
        image_urls: allUrls,
      }

      if (body.start_date) body.start_date = `${body.start_date}T00:00:00Z`
      if (body.end_date) body.end_date = `${body.end_date}T00:00:00Z`
      if (body.publish_at) {
        body.publish_at = new Date(body.publish_at).toISOString()
      } else {
        delete body.publish_at
      }

      if (isEdit) {
        await api.put(`/dashboard/offers/${offer.id}`, body)
        notify("Offer updated", "success")
      } else {
        await api.post("/dashboard/offers", body)
        notify("Offer created", "success")
      }
      onSaved()
      onClose()
    } catch (err: any) {
      notify(err?.message || "Failed to save offer", "error")
    }
    setSaving(false)
  }

  const currentCropFile = currentCropIndex >= 0 && currentCropIndex < pendingCropFiles.length
    ? pendingCropFiles[currentCropIndex]
    : null

  const existingVisibleUrls = (offer?.image_urls || []).filter((u: string) => !removedUrls.includes(u))
  const displayUrls = isEdit && reorderedUrls.length > 0 ? reorderedUrls : existingVisibleUrls

  function handleDragStart(index: number) {
    setDragIndex(index)
  }

  function handleDragOver(e: React.DragEvent, index: number) {
    e.preventDefault()
    if (dragIndex === null || dragIndex === index) return
    const newUrls = [...displayUrls]
    const [moved] = newUrls.splice(dragIndex, 1)
    newUrls.splice(index, 0, moved)
    setReorderedUrls(newUrls)
    setDragIndex(index)
  }

  function handleDragEnd() {
    setDragIndex(null)
  }

  const hasChanges = croppedResults.length > 0 || removedUrls.length > 0 || reorderedUrls.length > 0
  const isSaving = saving || uploadingImages

  return (
    <>
      <ImageCropDialog
        open={currentCropIndex >= 0 && !!currentCropFile}
        imageUrl={currentCropFile?.dataUrl || ""}
        fileName={currentCropFile?.file.name || ""}
        index={currentCropIndex}
        total={pendingCropFiles.length}
        onCropComplete={handleCropComplete}
        onCancel={handleCropCancel}
      />

      <Dialog open={open} onOpenChange={(v) => { if (!v && currentCropIndex < 0) onClose() }}>
        <DialogContent className="sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{isEdit ? "Edit Offer" : "New Offer"}</DialogTitle>
            <DialogDescription>
              {isEdit ? "Update the offer details below." : "Fill in the details to create a new offer."}
            </DialogDescription>
          </DialogHeader>

          <form key={offer?.id || 'new'} onSubmit={handleSubmit(onSave)}>
            <div className="overflow-y-auto max-h-[55vh] space-y-4 px-1 scrollbar-thin">
              <div className="grid gap-2">
                <Label htmlFor="restaurant_id">Restaurant</Label>
                <Select
                  value={watch('restaurant_id') || ""}
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
                <Textarea
                  id="description"
                  className="min-h-[80px]"
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
                <Label htmlFor="publish_at">Schedule Publish</Label>
                <Input
                  id="publish_at"
                  type="datetime-local"
                  {...register("publish_at")}
                />
                <p className="text-xs text-muted-foreground">
                  Leave empty to publish immediately upon approval
                </p>
              </div>

              <div className="grid gap-2">
                <Label>Images</Label>
                <p className="text-xs text-muted-foreground">
                  Images are cropped to 1024×1024 (square). Adjust the crop window to frame your image.
                  {isEdit && <span> New images replace existing ones.</span>}
                </p>
                <div className="flex items-center gap-2">
                  <Input ref={fileInputRef} type="file" multiple accept="image/*" onChange={onFileSelect} className="file:text-xs" />
                </div>

                {croppedResults.length > 0 && (
                  <div className="flex flex-wrap gap-2 mt-1">
                    {croppedResults.map((r, i) => (
                      <div key={i} className="relative size-16 group">
                        <img
                          src={r.previewUrl}
                          alt={`Cropped ${i + 1}`}
                          className="size-full rounded-md object-cover"
                        />
                        <button
                          type="button"
                          onClick={() => removeCropped(i)}
                          className="absolute -top-1 -right-1 rounded-full bg-destructive p-0.5 text-destructive-foreground opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <X className="size-3" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}

                {existingVisibleUrls.length > 0 && !isEdit && croppedResults.length === 0 && (
                  <div className="flex flex-wrap gap-2 mt-1">
                    {existingVisibleUrls.map((url: string, i: number) => (
                      <div key={i} className="relative size-16 group">
                        <img
                          src={`${imageOrigin}${url}`}
                          alt={`Image ${i + 1}`}
                          className="size-full rounded-md object-cover"
                        />
                      </div>
                    ))}
                  </div>
                )}

                {displayUrls.length > 0 && isEdit && croppedResults.length === 0 && (
                  <div className="flex flex-wrap gap-2 mt-1">
                    {displayUrls.map((url: string, i: number) => (
                      <div
                        key={url}
                        draggable
                        onDragStart={() => handleDragStart(i)}
                        onDragOver={(e) => handleDragOver(e, i)}
                        onDragEnd={handleDragEnd}
                        className={`relative size-20 group cursor-grab active:cursor-grabbing ${
                          dragIndex === i ? 'opacity-50 ring-2 ring-primary' : ''
                        }`}
                      >
                        <img
                          src={`${imageOrigin}${url}`}
                          alt={`Image ${i + 1}`}
                          className="size-full rounded-md object-cover"
                        />
                        <div className="absolute top-0 left-0 rounded-tl-md rounded-br-md bg-background/80 p-0.5">
                          <GripVertical className="size-3 text-muted-foreground" />
                        </div>
                        <button
                          type="button"
                          onClick={() => removeExistingUrl(url)}
                          className="absolute -top-1.5 -right-1.5 rounded-full bg-destructive p-0.5 text-destructive-foreground opacity-0 group-hover:opacity-100 transition-opacity"
                          title="Remove this image"
                        >
                          <X className="size-3" />
                        </button>
                        <span className="absolute bottom-0 left-0 right-0 rounded-b-md bg-background/60 text-[10px] text-center text-muted-foreground">
                          {i + 1}
                        </span>
                      </div>
                    ))}
                  </div>
                )}

                {removedUrls.length > 0 && (
                  <div className="flex flex-wrap gap-2">
                    {removedUrls.map((url, i) => (
                      <div key={i} className="relative size-16">
                        <img
                          src={`${imageOrigin}${url}`}
                          alt={`Removed ${i + 1}`}
                          className="size-full rounded-md object-cover opacity-40"
                        />
                        <div className="absolute inset-0 flex items-center justify-center">
                          <button
                            type="button"
                            onClick={() => restoreExistingUrl(url)}
                            className="rounded-full bg-background/80 p-1 text-xs hover:bg-background"
                            title="Restore this image"
                          >
                            <Upload className="size-3" />
                          </button>
                        </div>
                      </div>
                    ))}
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
                        <Label htmlFor="title_si">Title</Label>
                        <Input id="title_si" {...register("title_si")} />
                      </div>
                      <div className="grid gap-1">
                        <Label htmlFor="description_si">Description</Label>
                        <Textarea
                          id="description_si"
                          className="min-h-[60px]"
                          {...register("description_si")}
                        />
                      </div>
                    </div>
                  </div>
                  <div>
                    <h5 className="text-xs font-medium text-muted-foreground mb-2">Tamil (தமிழ்)</h5>
                    <div className="grid gap-2">
                      <div className="grid gap-1">
                        <Label htmlFor="title_ta">Title</Label>
                        <Input id="title_ta" {...register("title_ta")} />
                      </div>
                      <div className="grid gap-1">
                        <Label htmlFor="description_ta">Description</Label>
                        <Textarea
                          id="description_ta"
                          className="min-h-[60px]"
                          {...register("description_ta")}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <DialogFooter className="mt-4">
              <Button variant="outline" type="button" onClick={onClose}>Cancel</Button>
              <Button type="submit" disabled={isSaving}>
                {isSaving && <Loader2 className="mr-2 size-4 animate-spin" />}
                {isEdit ? "Update" : "Create"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </>
  )
}
