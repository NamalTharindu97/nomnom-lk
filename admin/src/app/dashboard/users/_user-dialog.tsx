"use client"

import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2 } from "lucide-react"

interface UserForm {
  email: string
  name: string
  password: string
  role: string
}

const emptyForm: UserForm = {
  email: "",
  name: "",
  password: "",
  role: "user",
}

interface UserDialogProps {
  open: boolean
  onClose: () => void
  onSaved: () => void
}

export default function UserDialog({ open, onClose, onSaved }: UserDialogProps) {
  const [form, setForm] = useState<UserForm>(emptyForm)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (open) setForm(emptyForm)
  }, [open])

  function set<K extends keyof UserForm>(key: K, value: UserForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSave() {
    if (!form.email.trim() || !form.name.trim() || !form.password.trim()) {
      notify("Email, name, and password are required", "error")
      return
    }
    setSaving(true)
    try {
      await api.post("/users", form)
      notify("User created", "success")
      onSaved()
      onClose()
    } catch (err: any) {
      notify(err?.message || "Failed to create user", "error")
    }
    setSaving(false)
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose() }}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>New User</DialogTitle>
          <DialogDescription>
            Create a new platform user.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-4 py-2">
          <div className="grid gap-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" value={form.email} onChange={(e) => set("email", e.target.value)} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="name">Name</Label>
            <Input id="name" value={form.name} onChange={(e) => set("name", e.target.value)} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="password">Password</Label>
            <Input id="password" type="password" value={form.password} onChange={(e) => set("password", e.target.value)} />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="role">Role</Label>
            <Select value={form.role} onValueChange={(v) => set("role", v)}>
              <SelectTrigger id="role">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="user">User</SelectItem>
                <SelectItem value="restaurant_owner">Restaurant Owner</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSave} disabled={saving}>
            {saving && <Loader2 className="mr-2 size-4 animate-spin" />}
            Create User
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
