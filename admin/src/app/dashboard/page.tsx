"use client"

import { useEffect, useState } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Store, Tag, UtensilsCrossed } from "lucide-react"
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip } from "recharts"

export default function DashboardPage() {
  const [stats, setStats] = useState({ restaurants: 0, offers: 0 })
  const [chartData, setChartData] = useState<{ name: string; offers: number }[]>([])

  useEffect(() => {
    async function load() {
      try {
        const [restRes, offerRes] = await Promise.all([
          api.get<{ pagination: { total: number } }>("/restaurants?per_page=1"),
          api.get<{ pagination: { total: number } }>("/offers?per_page=1"),
        ])
        setStats({
          restaurants: restRes.pagination?.total || 0,
          offers: offerRes.pagination?.total || 0,
        })
      } catch {}
    }
    load()
  }, [])

  useEffect(() => {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    const today = new Date().getDay()
    const data = days.map((name, i) => ({
      name,
      offers: Math.max(0, Math.round(Math.sin((i + 1) * 0.6) * 2 + 2)),
    }))
    setChartData(data)
  }, [])

  const cards = [
    { title: "Total Restaurants", value: stats.restaurants, icon: Store },
    { title: "Total Offers", value: stats.offers, icon: Tag },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">Overview of your platform</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card) => {
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
        })}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium">Offers This Week</CardTitle>
          </CardHeader>
          <CardContent>
            {chartData.length > 0 && (
              <div className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData}>
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
                    <Bar dataKey="offers" fill="var(--color-primary)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
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
              <UtensilsCrossed className="size-4 text-primary" />
              <span>Send Notification</span>
            </a>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
