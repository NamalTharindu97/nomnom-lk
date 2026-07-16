"use client"

import { useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { api } from "@/lib/api"
import { notify } from "@/components/ui/toast"
import { Loader2 } from "lucide-react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const userSchema = z.object({
  email: z.string().email("Invalid email address"),
  name: z.string().min(1, "Name is required").max(100),
  role: z.enum(["user", "restaurant_owner", "admin"]),
  password: z.string().min(6, "Password must be at least 6 characters").optional().or(z.literal("")),
})

type FormData = z.infer<typeof userSchema>

interface User {
  id: string
  email: string
  name: string
  role: string
}

interface UserDialogProps {
  open: boolean
  onClose: () => void
  onSaved: () => void
  user?: User | null
}

export default function UserDialog({ open, onClose, onSaved, user }: UserDialogProps) {
  const isEdit = !!user

  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(userSchema),
    defaultValues: { email: "", name: "", role: "user", password: "" },
  })

  useEffect(() => {
    if (user) {
      reset({ email: user.email, name: user.name, role: user.role as "user" | "restaurant_owner" | "admin", password: "" })
    } else {
      reset({ email: "", name: "", role: "user", password: "" })
    }
  }, [user, reset])

  async function onSave(data: FormData) {
    try {
      const body: Record<string, any> = { name: data.name, email: data.email, role: data.role }
      if (data.password) body.password = data.password

      if (isEdit) {
        await api.put(`/users/${user!.id}`, body)
        notify("User updated", "success")
      } else {
        await api.post("/users", body)
        notify("User created", "success")
      }
      onSaved()
      onClose()
    } catch (err: any) {
      notify(err?.message || `Failed to ${isEdit ? "update" : "create"} user`, "error")
    }
  }

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onClose() }}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit User" : "New User"}</DialogTitle>
          <DialogDescription>
            {isEdit ? "Update the user details below." : "Create a new platform user."}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSave)}>
          <div className="grid gap-4 py-2">
            <div className="grid gap-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" {...register("email")} />
              {errors.email && <p className="text-xs text-destructive">{errors.email.message}</p>}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="name">Name</Label>
              <Input id="name" {...register("name")} />
              {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">
                Password {isEdit && <span className="text-muted-foreground">(leave blank to keep current)</span>}
              </Label>
              <Input id="password" type="password" {...register("password")} />
              {errors.password && <p className="text-xs text-destructive">{errors.password.message}</p>}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="role">Role</Label>
              <Select
                value={watch ? watch("role") : "user"}
                onValueChange={(v) => reset((prev) => ({ ...prev, role: v as "user" | "restaurant_owner" | "admin" }))}
              >
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
            <Button variant="outline" type="button" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting && <Loader2 className="mr-2 size-4 animate-spin" />}
              {isEdit ? "Update User" : "Create User"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
