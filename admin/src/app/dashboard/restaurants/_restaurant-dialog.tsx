"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2, X } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Checkbox } from "@/components/ui/checkbox"
import { useAuth } from "@/hooks/use-auth"

const restaurantSchema = z.object({
  name: z.string().min(1, "Name is required"),
  slug: z.string().min(1, "Slug is required").regex(/^[a-z0-9-]+$/, "Slug must be lowercase, alphanumeric, with dashes"),
  cuisine_tags: z.array(z.string()).optional(),
  description: z.string().optional(),
  contact_phone: z.string().optional(),
  owner_id: z.string().optional(),
  name_si: z.string().optional(),
  name_ta: z.string().optional(),
  description_si: z.string().optional(),
  description_ta: z.string().optional(),
  social_links: z.array(z.object({ platform: z.string(), url: z.string() })).optional(),
  order_platforms: z.array(z.string()).optional(),
})

type FormData = z.infer<typeof restaurantSchema>

interface OwnerOption {
  id: string
  name: string
  email: string
}

interface CuisineTag {
  id: string
  name: string
}

interface SocialPlatformItem {
  id: string
  name: string
  slug: string
  display_name: string
  primary_color: string
}

interface OrderPlatformItem {
  id: string
  name: string
  slug: string
  display_name: string
  primary_color: string
  deep_link_scheme: string
}

interface RestaurantDialogProps {
  open: boolean
  onClose: () => void
  onSaved: () => void
  restaurant?: any | null
}

export default function RestaurantDialog({ open, onClose, onSaved, restaurant }: RestaurantDialogProps) {
  const { isAdmin } = useAuth()
  const [saving, setSaving] = useState(false)
  const [coverFile, setCoverFile] = useState<File | null>(null)
  const [coverPreview, setCoverPreview] = useState<string | null>(null)
  const [uploadingImage, setUploadingImage] = useState(false)
  const [owners, setOwners] = useState<OwnerOption[]>([])
  const [allTags, setAllTags] = useState<{ id: string; name: string }[]>([])
  const [selectedTags, setSelectedTags] = useState<string[]>([])
  const [orderPlatforms, setOrderPlatforms] = useState<OrderPlatformItem[]>([])
  const [socialPlatforms, setSocialPlatforms] = useState<SocialPlatformItem[]>([])
  const [socialLinks, setSocialLinks] = useState<{ platform: string; url: string }[]>([])

  const isEdit = !!restaurant

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(restaurantSchema),
    defaultValues: {
      name: "", slug: "", cuisine_tags: [], description: "",
      contact_phone: "", owner_id: "", name_si: "", name_ta: "",
      description_si: "", description_ta: "",
      social_links: [], order_platforms: [],
    },
  })

  useEffect(() => {
    if (open && isAdmin) {
      api.get<{ data: OwnerOption[] }>("/users?role=restaurant_owner&per_page=100")
        .then((res) => setOwners(res.data || []))
        .catch(() => {})
    }
    if (open) {
      api.get<CuisineTag[]>("/admin/cuisine-tags")
        .then((data) => setAllTags(Array.isArray(data) ? data : (data as any)?.data || []))
        .catch(() => {})
      api.get<OrderPlatformItem[]>("/admin/order-platforms")
        .then((data) => setOrderPlatforms(Array.isArray(data) ? data : (data as any)?.data || []))
        .catch(() => {})
      api.get<SocialPlatformItem[]>("/admin/social-platforms")
        .then((data) => setSocialPlatforms(Array.isArray(data) ? data : (data as any)?.data || []))
        .catch(() => {})
    }
  }, [open, isAdmin])

  useEffect(() => {
    if (restaurant) {
      const tags = restaurant.cuisine_tags || []
      reset({
        name: restaurant.name || "",
        slug: restaurant.slug || "",
        cuisine_tags: tags,
        description: restaurant.description || "",
        contact_phone: restaurant.contact_phone || "",
        owner_id: restaurant.owner_id || "",
        name_si: restaurant.name_si || "",
        name_ta: restaurant.name_ta || "",
        description_si: restaurant.description_si || "",
        description_ta: restaurant.description_ta || "",
        social_links: restaurant.social_links || [],
        order_platforms: restaurant.order_platforms || [],
      })
      setSelectedTags(tags)
      setSocialLinks(restaurant.social_links || [])
      setCoverPreview(restaurant.cover_image || null)
    } else {
      reset()
      setSelectedTags([])
      setSocialLinks([])
      setCoverFile(null)
      setCoverPreview(null)
    }
  }, [restaurant, reset])

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

  async function onSave(data: FormData) {
    setSaving(true)
    try {
      const coverImage = await uploadFile()

      const body: Record<string, any> = {
        ...data,
        cuisine_tags: selectedTags,
        social_links: socialLinks.filter(l => l.url.trim()),
      }
      if (isAdmin && data.owner_id && data.owner_id !== "__none") body.owner_id = data.owner_id
      else delete body.owner_id

      if (coverImage) {
        body.cover_image = coverImage
      }

      if (isEdit) {
        await api.put(`/dashboard/restaurants/${restaurant.id}`, body)
        notify("Restaurant updated", "success")
      } else {
        await api.post("/dashboard/restaurants", body)
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

        <form onSubmit={handleSubmit(onSave)}>
          <div className="overflow-y-auto max-h-[55vh] space-y-4 px-1 scrollbar-thin">
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="name">Name</Label>
                <Input id="name" {...register("name")} />
                {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
              </div>
              <div className="grid gap-2">
                <Label htmlFor="slug">Slug</Label>
                <Input id="slug" {...register("slug")} />
                {errors.slug && <p className="text-xs text-destructive">{errors.slug.message}</p>}
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="grid gap-2">
                <Label htmlFor="contact_phone">Phone</Label>
                <Input id="contact_phone" {...register("contact_phone")} />
              </div>
            </div>
            <div className="grid gap-2">
              <Label>Cuisine Tags</Label>
              <div className="max-h-[160px] overflow-y-auto border rounded-md p-3 space-y-2">
                {allTags.length === 0 && <p className="text-sm text-muted-foreground">No cuisine tags defined yet. Go to Cuisine Tags page to add some.</p>}
                {allTags.map((tag) => (
                  <div key={tag.id} className="flex items-center gap-2">
                    <Checkbox
                      id={`tag-${tag.id}`}
                      checked={selectedTags.includes(tag.name)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setSelectedTags([...selectedTags, tag.name])
                          setValue("cuisine_tags", [...selectedTags, tag.name])
                        } else {
                          const next = selectedTags.filter((t) => t !== tag.name)
                          setSelectedTags(next)
                          setValue("cuisine_tags", next)
                        }
                      }}
                    />
                    <Label htmlFor={`tag-${tag.id}`} className="font-normal cursor-pointer">{tag.name}</Label>
                  </div>
                ))}
              </div>
            </div>
            <div className="grid gap-2">
              <Label htmlFor="description">Description</Label>
              <Textarea id="description" className="min-h-[80px]" {...register("description")} />
            </div>

            {isAdmin && (
              <div className="grid gap-2">
                <Label htmlFor="owner">Owner</Label>
                <Select
                  defaultValue=""
                  onValueChange={(v) => setValue("owner_id", v)}
                >
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
            )}

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
              <h4 className="text-sm font-semibold mb-3">Social & Order Links</h4>
              <div className="space-y-3">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <Label>Social Links</Label>
                    {socialPlatforms.length > 0 && (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => setSocialLinks([...socialLinks, { platform: socialPlatforms[0].slug, url: "" }])}
                        disabled={socialLinks.some(l => !l.platform || !l.url.trim())}
                      >
                        + Add
                      </Button>
                    )}
                  </div>
                  {socialLinks.length === 0 && (
                    <p className="text-sm text-muted-foreground">No social links added.</p>
                  )}
                  {socialLinks.map((link, i) => (
                    <div key={i} className="flex items-center gap-2 mb-2">
                      <Select
                        value={link.platform}
                        onValueChange={(v) => {
                          const next = [...socialLinks]
                          next[i] = { ...next[i], platform: v }
                          setSocialLinks(next)
                        }}
                      >
                        <SelectTrigger className="w-[140px]">
                          <SelectValue placeholder="Platform" />
                        </SelectTrigger>
                        <SelectContent>
                          {socialPlatforms.map((p) => (
                            <SelectItem key={p.id} value={p.slug}>{p.display_name}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <Input
                        placeholder="https://..."
                        value={link.url}
                        onChange={(e) => {
                          const next = [...socialLinks]
                          next[i] = { ...next[i], url: e.target.value }
                          setSocialLinks(next)
                        }}
                        className="flex-1"
                      />
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        onClick={() => setSocialLinks(socialLinks.filter((_, j) => j !== i))}
                        className="shrink-0"
                      >
                        <X className="size-4 text-destructive" />
                      </Button>
                    </div>
                  ))}
                </div>
                <div className="grid gap-2">
                  <Label>Ordering Platforms</Label>
                  <div className="flex items-center gap-6 pt-1">
                    {orderPlatforms.map((platform) => (
                      <label key={platform.id} className="flex items-center gap-2 text-sm cursor-pointer">
                        <Checkbox
                          checked={(watch("order_platforms") || []).includes(platform.slug)}
                          onCheckedChange={(checked) => {
                            const current = watch("order_platforms") || []
                            if (checked) {
                              setValue("order_platforms", [...current, platform.slug], { shouldDirty: true })
                            } else {
                              setValue("order_platforms", current.filter((p) => p !== platform.slug), { shouldDirty: true })
                            }
                          }}
                        />
                        {platform.display_name}
                      </label>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            <div className="border-t pt-4">
              <h4 className="text-sm font-semibold mb-3">Translations</h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h5 className="text-xs font-medium text-muted-foreground mb-2">Sinhala (සිංහල)</h5>
                  <div className="grid gap-2">
                    <div className="grid gap-1">
                      <Label htmlFor="name_si">Name</Label>
                      <Input id="name_si" {...register("name_si")} />
                    </div>
                    <div className="grid gap-1">
                      <Label htmlFor="description_si">Description</Label>
                      <Textarea id="description_si" className="min-h-[60px]" {...register("description_si")} />
                    </div>
                  </div>
                </div>
                <div>
                  <h5 className="text-xs font-medium text-muted-foreground mb-2">Tamil (தமிழ்)</h5>
                  <div className="grid gap-2">
                    <div className="grid gap-1">
                      <Label htmlFor="name_ta">Name</Label>
                      <Input id="name_ta" {...register("name_ta")} />
                    </div>
                    <div className="grid gap-1">
                      <Label htmlFor="description_ta">Description</Label>
                      <Textarea id="description_ta" className="min-h-[60px]" {...register("description_ta")} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <DialogFooter className="mt-4">
            <Button variant="outline" type="button" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saving || uploadingImage}>
              {(saving || uploadingImage) && <Loader2 className="mr-2 size-4 animate-spin" />}
              {isEdit ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
