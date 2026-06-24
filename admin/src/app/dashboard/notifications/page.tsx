"use client"

import { useState } from "react"
import { api, ApiError } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectTrigger,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select"

export default function NotificationsPage() {
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [target, setTarget] = useState("all")
  const [userId, setUserId] = useState("")
  const [sending, setSending] = useState(false)
  const [result, setResult] = useState<{ ok: boolean; message: string } | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSending(true)
    setResult(null)

    try {
      await api.post("/admin/notifications/push", {
        title,
        body,
        target,
        user_id: target === "user" ? userId : "",
      })
      setResult({ ok: true, message: "Push notification sent successfully!" })
      setTitle("")
      setBody("")
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : "Failed to send notification"
      setResult({ ok: false, message: msg })
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Push Notifications</h1>
        <p className="text-muted-foreground">Send push notifications to users</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Send Notification</CardTitle>
          <CardDescription>
            Send a push notification to all users or a specific user
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid gap-2">
              <Label htmlFor="title">Title</Label>
              <Input
                id="title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="New offer available!"
                required
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="body">Body</Label>
              <Textarea
                id="body"
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Check out our latest deals..."
                required
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="target">Target</Label>
              <Select value={target} onValueChange={setTarget}>
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Users</SelectItem>
                  <SelectItem value="user">Specific User</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {target === "user" && (
              <div className="grid gap-2">
                <Label htmlFor="userId">User ID</Label>
                <Input
                  id="userId"
                  value={userId}
                  onChange={(e) => setUserId(e.target.value)}
                  placeholder="UUID of the user"
                  required
                />
              </div>
            )}
            {result && (
              <p className={`text-sm ${result.ok ? "text-green-600" : "text-destructive"}`}>
                {result.message}
              </p>
            )}
            <Button type="submit" disabled={sending}>
              {sending ? "Sending..." : "Send Push Notification"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
