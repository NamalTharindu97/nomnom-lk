"use client"

import { useEffect, useState } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Store, Tag, Users, Bell } from "lucide-react"
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip } from "recharts"

interface Stats {
  total_restaurants: number
  total_offers: number
  total_users: number
  pending_restaurants: number
  pending_offers: number
}

interface TimelineEntry {
  date: string
  count: number
}

interface TimelineData {
  offers: TimelineEntry[]
  restaurants: TimelineEntry[]
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [timeline, setTimeline] = useState<TimelineData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get<{ data: Stats }>("/admin/stats"),
      api.get<{ data: TimelineData }>("/admin/stats/timeline?days=14"),
    ])
      .then(([statsRes, timelineRes]) => {
        setStats(statsRes.data)
        setTimeline(timelineRes.data)
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const cards = [
    { title: "Total Restaurants", value: stats?.total_restaurants ?? 0, icon: Store },
    { title: "Total Offers", value: stats?.total_offers ?? 0, icon: Tag },
    { title: "Total Users", value: stats?.total_users ?? 0, icon: Users },
    { title: "Pending Reviews", value: (stats?.pending_restaurants ?? 0) + (stats?.pending_offers ?? 0), icon: Bell },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">Overview of your platform</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {loading ? (
          <>
            {[1, 2, 3, 4].map((i) => (
              <Card key={i}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <div className="h-4 w-24 animate-pulse rounded bg-muted" />
                  <div className="size-4 animate-pulse rounded bg-muted" />
                </CardHeader>
                <CardContent>
                  <div className="h-7 w-16 animate-pulse rounded bg-muted" />
                </CardContent>
              </Card>
            ))}
          </>
        ) : (
          cards.map((card) => {
            const Icon = card.icon
            return (
              <Card key={card.title}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium">{card.title}</CardTitle>
                  <Icon className="size-4 text-primary" />
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold">{card.value}</p>
                </CardContent>
              </Card>
            )
          })
        )}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Activity (Last 14 Days)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              {loading ? (
                <div className="flex h-full items-center justify-center text-muted-foreground text-sm">
                  Loading...
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={(() => {
                    if (!timeline) return []
                    return timeline.offers.map((o, i) => ({
                      name: o.date.slice(5),
                      offers: o.count,
                      restaurants: timeline.restaurants[i]?.count ?? 0,
                    }))
                  })()}>
                    <XAxis dataKey="name" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                    <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                    <Tooltip
                      contentStyle={{
                        borderRadius: 8,
                        border: "1px solid var(--border)",
                        background: "var(--card)",
                        color: "var(--card-foreground)",
                      }}
                    />
                    <Bar dataKey="offers" name="Offers" fill="oklch(0.65 0.16 70)" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="restaurants" name="Restaurants" fill="oklch(0.55 0.12 250)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <a
              href="/dashboard/offers"
              className="flex items-center gap-3 rounded-lg border border-border p-3 text-sm transition-colors hover:bg-accent"
            >
              <Tag className="size-4 text-primary" />
              <span>Manage Offers</span>
            </a>
            <a
              href="/dashboard/restaurants"
              className="flex items-center gap-3 rounded-lg border border-border p-3 text-sm transition-colors hover:bg-accent"
            >
              <Store className="size-4 text-primary" />
              <span>Manage Restaurants</span>
            </a>
            <a
              href="/dashboard/notifications"
              className="flex items-center gap-3 rounded-lg border border-border p-3 text-sm transition-colors hover:bg-accent"
            >
              <Bell className="size-4 text-primary" />
              <span>Send Notification</span>
            </a>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
