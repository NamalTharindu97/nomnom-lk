"use client"

import { useEffect, useState } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ErrorBoundary } from "@/components/error-boundary"
import { Skeleton } from "@/components/ui/skeleton"
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip, LineChart, Line, Cell } from "recharts"

interface TopRestaurant {
  restaurant_id: string
  name: string
  offer_count: number
}

interface TopOffer {
  offer_id: string
  title: string
  favorite_count: number
}

interface OfferByViews {
  offer_id: string
  title: string
  view_count: number
}

interface GrowthEntry {
  date: string
  count: number
}

interface OfferStats {
  total: number
  approved: number
  pending: number
  rejected: number
  expired: number
  approval_rate: number
}

export default function AnalyticsPage() {
  const [topRestaurants, setTopRestaurants] = useState<TopRestaurant[]>([])
  const [topByFavorites, setTopByFavorites] = useState<TopOffer[]>([])
  const [topByViews, setTopByViews] = useState<OfferByViews[]>([])
  const [userGrowth, setUserGrowth] = useState<GrowthEntry[]>([])
  const [offerStats, setOfferStats] = useState<OfferStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [chartColors, setChartColors] = useState<string[]>([
    "oklch(0.65 0.16 70)",
    "oklch(0.55 0.12 250)",
    "oklch(0.6 0.15 150)",
    "oklch(0.6 0.15 340)",
    "oklch(0.5 0.1 180)",
  ])

  useEffect(() => {
    const style = getComputedStyle(document.documentElement)
    const colors = [1, 2, 3, 4, 5].map(i => style.getPropertyValue(`--chart-${i}`).trim())
    if (colors.some(Boolean)) setChartColors(colors)
  }, [])

  useEffect(() => {
    setLoading(true)
    Promise.all([
      api.get<{ data: TopRestaurant[] }>("/admin/analytics/top-restaurants"),
      api.get<{ data: { by_favorites: TopOffer[]; by_views: OfferByViews[] } }>("/admin/analytics/top-offers"),
      api.get<{ data: GrowthEntry[] }>("/admin/analytics/user-growth"),
      api.get<{ data: OfferStats }>("/admin/analytics/offer-stats"),
    ])
      .then(([restaurantsRes, offersRes, growthRes, statsRes]) => {
        setTopRestaurants(restaurantsRes.data || [])
        setTopByFavorites(offersRes.data?.by_favorites || [])
        setTopByViews(offersRes.data?.by_views || [])
        setUserGrowth(growthRes.data || [])
        setOfferStats(statsRes.data || null)
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  const tooltipStyle = {
    borderRadius: 8,
    border: "1px solid var(--border)",
    background: "var(--card)",
    color: "var(--card-foreground)",
  }

  const growthChart = userGrowth.map((g) => ({
    name: g.date.slice(5),
    users: g.count,
  }))

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Analytics</h1>
          <p className="text-muted-foreground">Platform performance insights</p>
        </div>

        {loading ? (
          <div className="space-y-6">
            <div className="grid gap-4 sm:grid-cols-5">
              {[1, 2, 3, 4, 5].map((i) => (
                <Card key={i}>
                  <CardHeader className="pb-2"><Skeleton className="h-4 w-16" /></CardHeader>
                  <CardContent><Skeleton className="h-7 w-12" /></CardContent>
                </Card>
              ))}
            </div>
            <div className="grid gap-6 lg:grid-cols-2">
              <Card><CardContent className="p-6"><Skeleton className="h-64 w-full" /></CardContent></Card>
              <Card><CardContent className="p-6"><Skeleton className="h-64 w-full" /></CardContent></Card>
            </div>
          </div>
        ) : (
          <>
            <div className="grid gap-4 sm:grid-cols-5">
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">Total</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold">{offerStats?.total ?? 0}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">Approved</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold text-success">{offerStats?.approved ?? 0}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">Pending</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold">{offerStats?.pending ?? 0}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">Rejected</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold text-destructive">{offerStats?.rejected ?? 0}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-xs font-medium text-muted-foreground">Approval</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-2xl font-bold">{offerStats?.approval_rate.toFixed(0) ?? 0}%</p>
                </CardContent>
              </Card>
            </div>

            <div className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Top Restaurants by Offers</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={topRestaurants} layout="vertical" margin={{ left: 20, right: 20 }}>
                        <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                        <YAxis dataKey="name" type="category" width={120} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                        <Tooltip contentStyle={tooltipStyle} />
                        <Bar dataKey="offer_count" name="Offers" radius={[0, 4, 4, 0]}>
                          {topRestaurants.map((_, i) => (
                            <Cell key={i} fill={chartColors[i % chartColors.length]} />
                          ))}
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Top Offers by Favorites</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64">
                    {topByFavorites.length === 0 ? (
                      <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                        No favorites yet
                      </div>
                    ) : (
                      <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={topByFavorites} layout="vertical" margin={{ left: 20, right: 20 }}>
                          <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                          <YAxis dataKey="title" type="category" width={140} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                          <Tooltip contentStyle={tooltipStyle} />
                          <Bar dataKey="favorite_count" name="Favorites" radius={[0, 4, 4, 0]}>
                            {topByFavorites.map((_, i) => (
                              <Cell key={i} fill={chartColors[i % chartColors.length]} />
                            ))}
                          </Bar>
                        </BarChart>
                      </ResponsiveContainer>
                    )}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">User Growth (30 days)</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64">
                    {growthChart.length === 0 ? (
                      <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                        No data available
                      </div>
                    ) : (
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={growthChart}>
                          <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                          <Tooltip contentStyle={tooltipStyle} />
                          <Line
                            type="monotone"
                            dataKey="users"
                            name="New Users"
                            stroke="oklch(0.65 0.16 70)"
                            strokeWidth={2}
                            dot={false}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                    )}
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Top Offers by Views</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="h-64">
                    {topByViews.length === 0 ? (
                      <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                        No views yet
                      </div>
                    ) : (
                      <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={topByViews} layout="vertical" margin={{ left: 20, right: 20 }}>
                          <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                          <YAxis dataKey="title" type="category" width={140} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                          <Tooltip contentStyle={tooltipStyle} />
                          <Bar dataKey="view_count" name="Views" radius={[0, 4, 4, 0]}>
                            {topByViews.map((_, i) => (
                              <Cell key={i} fill={chartColors[i % chartColors.length]} />
                            ))}
                          </Bar>
                        </BarChart>
                      </ResponsiveContainer>
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>
          </>
        )}
      </div>
    </ErrorBoundary>
  )
}
