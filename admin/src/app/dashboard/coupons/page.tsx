"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { ErrorBoundary } from "@/components/error-boundary"
import { EmptyState } from "@/components/empty-state"
import { TableSkeleton } from "@/components/table-skeleton"
import { notify } from "@/components/ui/toast"
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent,
  AlertDialogDescription, AlertDialogFooter, AlertDialogHeader,
  AlertDialogTitle, AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Plus, Pencil, Trash2, Ticket } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const couponSchema = z.object({
  code: z.string().min(1, "Code is required").max(50),
  discount_type: z.enum(["percentage", "fixed"]),
  discount_value: z.number().positive("Must be positive"),
  min_order_amount: z.number().min(0).optional(),
  max_uses: z.number().int().min(0, "Must be 0 or positive").optional(),
  starts_at: z.string().optional(),
  expires_at: z.string().optional(),
}).refine(
  (data) => data.discount_type !== "percentage" || data.discount_value <= 100,
  { message: "Percentage must be ≤ 100", path: ["discount_value"] }
)

type FormData = z.infer<typeof couponSchema>

interface Coupon {
  id: string
  code: string
  discount_type: string
  discount_value: number
  min_order_amount: number
  max_uses: number
  current_uses: number
  is_active: boolean
  starts_at: string
  expires_at: string
  created_at: string
}

export default function CouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([])
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState<Coupon | null>(null)
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Coupon | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(couponSchema),
    defaultValues: { code: "", discount_type: "percentage", discount_value: 0, min_order_amount: 0, max_uses: 0, starts_at: "", expires_at: "" },
  })

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Coupon[] }>("/admin/coupons")
      setCoupons(res.data || [])
    } catch { setCoupons([]) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  function startCreate() {
    setEditing(null)
    reset({ code: "", discount_type: "percentage", discount_value: 0, min_order_amount: 0, max_uses: 0, starts_at: "", expires_at: "" })
  }

  function startEdit(c: Coupon) {
    setEditing(c)
    reset({
      code: c.code,
      discount_type: c.discount_type as "percentage" | "fixed",
      discount_value: c.discount_value,
      min_order_amount: c.min_order_amount || 0,
      max_uses: c.max_uses || 0,
      starts_at: c.starts_at ? c.starts_at.slice(0, 16) : "",
      expires_at: c.expires_at ? c.expires_at.slice(0, 16) : "",
    })
  }

  async function onSave(data: FormData) {
    setSaving(true)
    try {
      const payload: any = {
        code: data.code.toUpperCase(),
        discount_type: data.discount_type,
        discount_value: data.discount_value,
        min_order_amount: data.min_order_amount || 0,
        max_uses: data.max_uses || 0,
        starts_at: data.starts_at ? new Date(data.starts_at).toISOString() : null,
        expires_at: data.expires_at ? new Date(data.expires_at).toISOString() : null,
      }
      if (editing) {
        await api.put(`/admin/coupons/${editing.id}`, payload)
        notify("Coupon updated", "success")
      } else {
        await api.post("/admin/coupons", payload)
        notify("Coupon created", "success")
      }
      startCreate(); load()
    } catch { notify("Failed to save coupon") }
    setSaving(false)
  }

  async function handleToggle(c: Coupon) {
    try {
      await api.post(`/admin/coupons/${c.id}/${c.is_active ? "deactivate" : "activate"}`)
      notify(`Coupon ${c.is_active ? "deactivated" : "activated"}`, "success")
      load()
    } catch { notify("Failed to toggle coupon") }
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try { await api.delete(`/admin/coupons/${deleteTarget.id}`); notify("Coupon deleted", "success"); setDeleteTarget(null); load() }
    catch { notify("Failed to delete coupon") }
  }

  return (
    <ErrorBoundary><div className="space-y-6">
      <div><h1 className="text-2xl font-bold tracking-tight">Coupons</h1><p className="text-muted-foreground">Manage promo codes</p></div>
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle>{editing ? "Edit Coupon" : "New Coupon"}</CardTitle><CardDescription>Create percentage or fixed discount codes</CardDescription></CardHeader>
          <CardContent className="space-y-4">
            <form onSubmit={handleSubmit(onSave)}>
              <div className="grid gap-2">
                <Label htmlFor="code">Code</Label>
                <Input id="code" {...register("code")} onChange={(e) => setValue("code", e.target.value.toUpperCase(), { shouldDirty: true })} placeholder="SAVE20" />
                {errors.code && <p className="text-xs text-destructive">{errors.code.message}</p>}
              </div>
              <div className="grid grid-cols-2 gap-2 mt-4">
                <div className="grid gap-2">
                  <Label>Type</Label>
                  <Select value={watch("discount_type") || "percentage"} onValueChange={(v) => setValue("discount_type", v as "percentage" | "fixed")}>
                    <SelectTrigger><SelectValue /></SelectTrigger>
                    <SelectContent><SelectItem value="percentage">Percentage</SelectItem><SelectItem value="fixed">Fixed</SelectItem></SelectContent>
                  </Select>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="discount_value">Value</Label>
                  <Input id="discount_value" type="number" {...register("discount_value", { valueAsNumber: true })} placeholder={watch("discount_type") === "percentage" ? "20" : "500"} />
                  {errors.discount_value && <p className="text-xs text-destructive">{errors.discount_value.message}</p>}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 mt-4">
                <div className="grid gap-2">
                  <Label htmlFor="min_order_amount">Min Order</Label>
                  <Input id="min_order_amount" type="number" {...register("min_order_amount", { valueAsNumber: true })} placeholder="0" />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="max_uses">Max Uses</Label>
                  <Input id="max_uses" type="number" {...register("max_uses", { valueAsNumber: true })} placeholder="Unlimited" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 mt-4">
                <div className="grid gap-2">
                  <Label htmlFor="starts_at">Starts At</Label>
                  <Input id="starts_at" type="datetime-local" {...register("starts_at")} />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="expires_at">Expires At</Label>
                  <Input id="expires_at" type="datetime-local" {...register("expires_at")} />
                </div>
              </div>
              <div className="flex gap-2 mt-4">
                <Button type="submit" disabled={saving}>{saving ? "Saving..." : editing ? "Update" : "Create"}</Button>
                {editing && <Button variant="outline" type="button" onClick={startCreate}>Cancel</Button>}
              </div>
            </form>
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>All Coupons</CardTitle></CardHeader>
          <CardContent>
            <Table>
              <TableHeader><TableRow><TableHead>Code</TableHead><TableHead>Discount</TableHead><TableHead>Uses</TableHead><TableHead>Status</TableHead><TableHead className="text-right">Actions</TableHead></TableRow></TableHeader>
              <TableBody>
                {loading ? <TableSkeleton columns={5} /> : coupons.length === 0 ? <EmptyState icon={<Ticket className="size-10 text-muted-foreground/50" />} title="No coupons" description="Create your first coupon code." /> : coupons.map(c => (
                  <TableRow key={c.id}>
                    <TableCell className="font-medium">{c.code}</TableCell>
                    <TableCell>{c.discount_type === "percentage" ? `${c.discount_value}%` : `LKR ${c.discount_value}`}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">{c.current_uses}{c.max_uses > 0 ? ` / ${c.max_uses}` : ""}</TableCell>
                    <TableCell><Badge variant={c.is_active ? "default" : "destructive"}>{c.is_active ? "Active" : "Inactive"}</Badge></TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button size="icon" variant="ghost" onClick={() => startEdit(c)}><Pencil className="size-4" /></Button>
                        <AlertDialog>
                          <AlertDialogTrigger asChild>
                            <Button size="sm" variant="outline">{c.is_active ? "Deactivate" : "Activate"}</Button>
                          </AlertDialogTrigger>
                          <AlertDialogContent>
                            <AlertDialogHeader>
                              <AlertDialogTitle>{c.is_active ? "Deactivate" : "Activate"} {c.code}</AlertDialogTitle>
                              <AlertDialogDescription>
                                {c.is_active
                                  ? `Deactivate ${c.code}? Users will not be able to use this coupon.`
                                  : `Activate ${c.code}? Users will be able to use this coupon.`}
                              </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                              <AlertDialogCancel>Cancel</AlertDialogCancel>
                              <AlertDialogAction onClick={() => handleToggle(c)}>
                                {c.is_active ? "Deactivate" : "Activate"}
                              </AlertDialogAction>
                            </AlertDialogFooter>
                          </AlertDialogContent>
                        </AlertDialog>
                        <AlertDialog>
                          <AlertDialogTrigger asChild><Button size="icon" variant="ghost" onClick={() => setDeleteTarget(c)}><Trash2 className="size-4 text-destructive" /></Button></AlertDialogTrigger>
                          <AlertDialogContent><AlertDialogHeader><AlertDialogTitle>Delete Coupon</AlertDialogTitle><AlertDialogDescription>Delete <strong>{c.code}</strong>? This cannot be undone.</AlertDialogDescription></AlertDialogHeader><AlertDialogFooter><AlertDialogCancel onClick={() => setDeleteTarget(null)}>Cancel</AlertDialogCancel><AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">Delete</AlertDialogAction></AlertDialogFooter></AlertDialogContent>
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
