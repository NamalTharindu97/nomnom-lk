"use client"

import { useState, useEffect, useCallback, useMemo } from "react"
import { api, ApiError } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Label } from "@/components/ui/label"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { PaginationBar } from "@/components/ui/pagination-bar"
import { ErrorBoundary } from "@/components/error-boundary"
import { CheckIcon, ChevronsUpDownIcon } from "lucide-react"
import { cn } from "@/lib/utils"
import {
  Select,
  SelectTrigger,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select"
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@/components/ui/popover"
import {
  Command,
  CommandInput,
  CommandList,
  CommandEmpty,
  CommandGroup,
  CommandItem,
} from "@/components/ui/command"

const PER_PAGE = 10

interface OfferOption {
  id: string
  title: string
  restaurant_name: string
}

interface UserOption {
  id: string
  name: string
  email: string
  role: string
}

export default function NotificationsPage() {
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [target, setTarget] = useState("all")
  const [userId, setUserId] = useState("")
  const [offerId, setOfferId] = useState("")
  const [open, setOpen] = useState(false)
  const [sending, setSending] = useState(false)
  const [result, setResult] = useState<{ ok: boolean; message: string } | null>(null)

  const [users, setUsers] = useState<UserOption[]>([])
  const [loadingUsers, setLoadingUsers] = useState(true)

  const [offers, setOffers] = useState<OfferOption[]>([])
  const [loadingOffers, setLoadingOffers] = useState(true)

  useEffect(() => {
    if (!result) return
    const timer = setTimeout(() => setResult(null), 5000)
    return () => clearTimeout(timer)
  }, [result])

  const selectedUser = useMemo(() => users.find((u) => u.id === userId), [users, userId])

  const [history, setHistory] = useState<any[]>([])
  const [loadingHistory, setLoadingHistory] = useState(true)
  const [page, setPage] = useState(1)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    api.get<{ data: UserOption[] }>("/users?per_page=500")
      .then((res) => setUsers(res.data || []))
      .catch(() => setUsers([]))
      .finally(() => setLoadingUsers(false))
  }, [])

  useEffect(() => {
    api.get<{ data: OfferOption[] }>("/offers?per_page=200&status=approved")
      .then((res) => setOffers(res.data || []))
      .catch(() => setOffers([]))
      .finally(() => setLoadingOffers(false))
  }, [])

  const loadHistory = useCallback(async () => {
    setLoadingHistory(true)
    try {
      const res = await api.get<{ data: any[]; pagination: { total: number } }>(
        `/admin/notifications?page=${page}&per_page=${PER_PAGE}`
      )
      setHistory(res.data || [])
      setTotal(res.pagination?.total || 0)
    } catch {
      setHistory([])
    } finally {
      setLoadingHistory(false)
    }
  }, [page])

  useEffect(() => { loadHistory() }, [loadHistory])

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
        offer_id: offerId && offerId !== "none" ? offerId : undefined,
      })
      setResult({ ok: true, message: "Push notification sent successfully!" })
      setTitle("")
      setBody("")
      setOfferId("")
      loadHistory()
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : "Failed to send notification"
      setResult({ ok: false, message: msg })
    } finally {
      setSending(false)
    }
  }

  return (
    <ErrorBoundary>
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Push Notifications</h1>
        <p className="text-muted-foreground">Send and manage push notifications</p>
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
                <Label>User</Label>
                <Popover open={open} onOpenChange={setOpen}>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      role="combobox"
                      aria-expanded={open}
                      data-testid="user-combobox"
                      className="w-full justify-between"
                    >
                      {selectedUser
                        ? `${selectedUser.name} (${selectedUser.email})`
                        : "Select a user..."}
                      <ChevronsUpDownIcon className="ml-2 size-4 shrink-0 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-[--radix-popover-trigger-width] p-0">
                    <Command>
                      <CommandInput placeholder="Search by name or email..." />
                      <CommandList>
                        <CommandEmpty>No user found.</CommandEmpty>
                        <CommandGroup>
                          {users.map((u) => (
                            <CommandItem
                              key={u.id}
                              value={`${u.name} ${u.email}`}
                              onSelect={() => {
                                setUserId(u.id)
                                setOpen(false)
                              }}
                            >
                              <CheckIcon
                                className={cn(
                                  "mr-2 size-4",
                                  userId === u.id ? "opacity-100" : "opacity-0"
                                )}
                              />
                              <span>
                                {u.name} ({u.email})
                              </span>
                              <span className="ml-auto text-xs text-muted-foreground">
                                {u.role}
                              </span>
                            </CommandItem>
                          ))}
                        </CommandGroup>
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
              </div>
            )}
            <div className="grid gap-2">
              <Label htmlFor="offer">Related Offer (optional)</Label>
              <Select value={offerId} onValueChange={setOfferId}>
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="None — general notification" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">None — general notification</SelectItem>
                  {loadingOffers ? (
                    <SelectItem value="__loading" disabled>Loading offers...</SelectItem>
                  ) : offers.length === 0 ? (
                    <SelectItem value="__empty" disabled>No offers available</SelectItem>
                  ) : (
                    offers.map((o) => (
                      <SelectItem key={o.id} value={o.id}>
                        {o.restaurant_name} — {o.title}
                      </SelectItem>
                    ))
                  )}
                </SelectContent>
              </Select>
            </div>
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

      <Card>
        <CardHeader>
          <CardTitle>Notification History</CardTitle>
          <CardDescription>Previously sent push notifications</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Body</TableHead>
                <TableHead>User</TableHead>
                <TableHead>Sent At</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loadingHistory ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">
                    Loading...
                  </TableCell>
                </TableRow>
              ) : history.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} className="text-center py-8 text-muted-foreground">
                    No notifications sent yet
                  </TableCell>
                </TableRow>
              ) : (
                history.map((n: any) => (
                  <TableRow key={n.id}>
                    <TableCell className="font-medium">{n.title}</TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                      {n.body}
                    </TableCell>
                    <TableCell>{n.user_name || "All Users"}</TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {new Date(n.created_at).toLocaleString()}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>

          <PaginationBar page={page} perPage={PER_PAGE} total={total} onPageChange={setPage} />
        </CardContent>
      </Card>
    </div>
    </ErrorBoundary>
  )
}
