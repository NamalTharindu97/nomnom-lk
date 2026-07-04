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
  const [code, setCode] = useState("")
  const [discountType, setDiscountType] = useState("percentage")
  const [discountValue, setDiscountValue] = useState("")
  const [minOrder, setMinOrder] = useState("")
  const [maxUses, setMaxUses] = useState("")
  const [startsAt, setStartsAt] = useState("")
  const [expiresAt, setExpiresAt] = useState("")
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Coupon | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<{ data: Coupon[] }>("/admin/coupons")
      setCoupons(res.data || [])
    } catch { setCoupons([]) }
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  function startCreate() { setEditing(null); setCode(""); setDiscountType("percentage"); setDiscountValue(""); setMinOrder(""); setMaxUses(""); setStartsAt(""); setExpiresAt("") }
  function startEdit(c: Coupon) { setEditing(c); setCode(c.code); setDiscountType(c.discount_type); setDiscountValue(String(c.discount_value)); setMinOrder(String(c.min_order_amount || "")); setMaxUses(String(c.max_uses || "")); setStartsAt(c.starts_at ? c.starts_at.slice(0, 16) : ""); setExpiresAt(c.expires_at ? c.expires_at.slice(0, 16) : "") }

  async function handleSave() {
    if (!code || !discountValue) { notify("Code and discount value are required", "error"); return }
    setSaving(true)
    try {
      const payload: any = {
        code, discount_type: discountType, discount_value: parseFloat(discountValue),
        min_order_amount: minOrder ? parseFloat(minOrder) : 0,
        max_uses: maxUses ? parseInt(maxUses) : 0,
        starts_at: startsAt ? new Date(startsAt).toISOString() : null,
        expires_at: expiresAt ? new Date(expiresAt).toISOString() : null,
      }
      if (editing) {
        await api.put(`/admin/coupons/${editing.id}`, payload)
        notify("Coupon updated", "success")
      } else {
        await api.post("/admin/coupons", payload)
        notify("Coupon created", "success")
      }
      startCreate(); load()
    } catch {}
    setSaving(false)
  }

  async function handleToggle(c: Coupon) {
    try {
      await api.post(`/admin/coupons/${c.id}/${c.is_active ? "deactivate" : "activate"}`)
      notify(`Coupon ${c.is_active ? "deactivated" : "activated"}`, "success")
      load()
    } catch {}
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try { await api.delete(`/admin/coupons/${deleteTarget.id}`); notify("Coupon deleted", "success"); setDeleteTarget(null); load() }
    catch {}
  }

  return (
    <ErrorBoundary><div className="space-y-6">
      <div><h1 className="text-2xl font-bold tracking-tight">Coupons</h1><p className="text-muted-foreground">Manage promo codes</p></div>
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader><CardTitle>{editing ? "Edit Coupon" : "New Coupon"}</CardTitle><CardDescription>Create percentage or fixed discount codes</CardDescription></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-2"><Label htmlFor="code">Code</Label><Input id="code" value={code} onChange={e => setCode(e.target.value.toUpperCase())} placeholder="SAVE20" /></div>
            <div className="grid grid-cols-2 gap-2">
              <div className="grid gap-2"><Label>Type</Label><Select value={discountType} onValueChange={setDiscountType}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="percentage">Percentage</SelectItem><SelectItem value="fixed">Fixed</SelectItem></SelectContent></Select></div>
              <div className="grid gap-2"><Label htmlFor="discount">Value</Label><Input id="discount" type="number" value={discountValue} onChange={e => setDiscountValue(e.target.value)} placeholder={discountType === "percentage" ? "20" : "500"} /></div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="grid gap-2"><Label htmlFor="minOrder">Min Order</Label><Input id="minOrder" type="number" value={minOrder} onChange={e => setMinOrder(e.target.value)} placeholder="0" /></div>
              <div className="grid gap-2"><Label htmlFor="maxUses">Max Uses</Label><Input id="maxUses" type="number" value={maxUses} onChange={e => setMaxUses(e.target.value)} placeholder="Unlimited" /></div>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className="grid gap-2"><Label htmlFor="starts">Starts At</Label><Input id="starts" type="datetime-local" value={startsAt} onChange={e => setStartsAt(e.target.value)} /></div>
              <div className="grid gap-2"><Label htmlFor="expires">Expires At</Label><Input id="expires" type="datetime-local" value={expiresAt} onChange={e => setExpiresAt(e.target.value)} /></div>
            </div>
            <div className="flex gap-2">
              <Button onClick={handleSave} disabled={saving}>{saving ? "Saving..." : editing ? "Update" : "Create"}</Button>
              {editing && <Button variant="outline" onClick={startCreate}>Cancel</Button>}
            </div>
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
                        <Button size="sm" variant="outline" onClick={() => handleToggle(c)}>{c.is_active ? "Deactivate" : "Activate"}</Button>
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
