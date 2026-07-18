"use client"

import { useEffect, useState, useCallback } from "react"
import { api } from "@/lib/api"
import { useAuth } from "@/hooks/use-auth"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ErrorBoundary } from "@/components/error-boundary"
import { Skeleton } from "@/components/ui/skeleton"
import { Button } from "@/components/ui/button"
import {
  Store, Tag, Users, Bell, CheckCircle, Smartphone, Clock,
  BarChart3, Ticket, Send, ChevronRight,
} from "lucide-react"
import {
  BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip,
  LineChart, Line, Cell,
} from "recharts"

interface Stats {
  total_restaurants: number
  total_offers: number
  total_users: number
  pending_restaurants: number
  pending_offers: number
  total_banners: number
  pending_banners: number
  total_banner_clicks: number
  active_coupons: number
  total_coupon_redemptions: number
  total_notifications: number
}

interface TimelineEntry { date: string; count: number }
interface TimelineData { offers: TimelineEntry[]; restaurants: TimelineEntry[] }

interface TopRestaurant { restaurant_id: string; name: string; offer_count: number }
interface TopOffer { offer_id: string; title: string; favorite_count: number }
interface OfferByViews { offer_id: string; title: string; view_count: number }

interface GrowthEntry { date: string; count: number }

interface OfferStats {
  total: number; approved: number; pending: number;
  rejected: number; expired: number; approval_rate: number
}

interface ExpiringOffer {
  offer_id: string; title: string; restaurant_name: string; end_date: string
}

interface DeviceStats { ios: number; android: number }

interface AuditEntry {
  id: string; admin_name: string; action: string;
  entity_type: string; details: string; created_at: string
}

interface NotificationStats { total: number; sent: number; pending: number; failed: number }

const PRESETS = [
  { label: "7d", days: 7 },
  { label: "14d", days: 14 },
  { label: "30d", days: 30 },
]

const CHART_COLORS = [
  "oklch(0.65 0.16 70)",
  "oklch(0.55 0.12 250)",
  "oklch(0.6 0.15 150)",
  "oklch(0.6 0.15 340)",
  "oklch(0.5 0.1 180)",
]

const tooltipStyle = {
  borderRadius: 8,
  border: "1px solid var(--border)",
  background: "var(--card)",
  color: "var(--card-foreground)",
}

function formatRelativeTime(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return "just now"
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [timeline, setTimeline] = useState<TimelineData | null>(null)
  const [topRestaurants, setTopRestaurants] = useState<TopRestaurant[]>([])
  const [topByFavorites, setTopByFavorites] = useState<TopOffer[]>([])
  const [topByViews, setTopByViews] = useState<OfferByViews[]>([])
  const [userGrowth, setUserGrowth] = useState<GrowthEntry[]>([])
  const [offerStats, setOfferStats] = useState<OfferStats | null>(null)
  const [expiringOffers, setExpiringOffers] = useState<ExpiringOffer[]>([])
  const [deviceStats, setDeviceStats] = useState<DeviceStats | null>(null)
  const [recentActivity, setRecentActivity] = useState<AuditEntry[]>([])
  const [notifStats, setNotifStats] = useState<NotificationStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)
  const [days, setDays] = useState(14)

  const load = useCallback(async () => {
    setLoading(true)
    setError(false)
    try {
      const [statsRes, timelineRes, topRestRes, topOffersRes, growthRes, offerStatsRes, expiringRes, deviceRes, activityRes, notifRes] = await Promise.all([
        api.get<{ data: Stats }>("/admin/stats"),
        api.get<{ data: TimelineData }>(`/admin/stats/timeline?days=${days}`),
        api.get<{ data: TopRestaurant[] }>("/admin/analytics/top-restaurants"),
        api.get<{ data: { by_favorites: TopOffer[]; by_views: OfferByViews[] } }>("/admin/analytics/top-offers"),
        api.get<{ data: GrowthEntry[] }>("/admin/analytics/user-growth"),
        api.get<{ data: OfferStats }>("/admin/analytics/offer-stats"),
        api.get<{ data: ExpiringOffer[] }>("/admin/analytics/expiring-offers?days=7"),
        api.get<{ data: DeviceStats }>("/admin/analytics/device-stats"),
        api.get<{ data: AuditEntry[] }>("/admin/analytics/recent-activity"),
        api.get<{ data: NotificationStats }>("/admin/notification-analytics"),
      ])
      setStats(statsRes.data)
      setTimeline(timelineRes.data)
      setTopRestaurants(topRestRes.data || [])
      setTopByFavorites(topOffersRes.data?.by_favorites || [])
      setTopByViews(topOffersRes.data?.by_views || [])
      setUserGrowth(growthRes.data || [])
      setOfferStats(offerStatsRes.data || null)
      setExpiringOffers(expiringRes.data || [])
      setDeviceStats(deviceRes.data || null)
      setRecentActivity(activityRes.data || [])
      setNotifStats(notifRes.data || null)
    } catch {
      setError(true)
    } finally {
      setLoading(false)
    }
  }, [days])

  useEffect(() => { load() }, [load])

  const totalDevices = (deviceStats?.ios ?? 0) + (deviceStats?.android ?? 0)
  const totalPending = (stats?.pending_restaurants ?? 0) + (stats?.pending_offers ?? 0)

  const statCards = [
    { title: "Restaurants", value: stats?.total_restaurants ?? 0, icon: Store, color: "text-primary" },
    { title: "Offers", value: stats?.total_offers ?? 0, icon: Tag, color: "text-primary" },
    { title: "Users", value: stats?.total_users ?? 0, icon: Users, color: "text-primary" },
    { title: "Pending", value: totalPending, icon: Clock, color: "text-warning" },
    { title: "Approval", value: `${offerStats?.approval_rate?.toFixed(0) ?? 0}%`, icon: CheckCircle, color: "text-success" },
    { title: "Devices", value: totalDevices, icon: Smartphone, color: "text-info" },
  ]

  if (error && !loading) {
    return <Card className="p-6 text-center text-muted-foreground">Failed to load dashboard stats</Card>
  }

  const activityData = timeline
    ? timeline.offers.map((o, i) => ({
        name: o.date.slice(5),
        offers: o.count,
        restaurants: timeline.restaurants[i]?.count ?? 0,
      }))
    : []

  const growthData = userGrowth.map((g) => ({ name: g.date.slice(5), users: g.count }))

  return (
    <>
      {loading ? (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <Card key={i}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <Skeleton className="h-4 w-16" />
                  <Skeleton className="size-4" />
                </CardHeader>
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
          <div className="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {statCards.map((card) => {
              const Icon = card.icon
              return (
                <Card key={card.title}>
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <CardTitle className="text-sm font-medium">{card.title}</CardTitle>
                    <Icon className={`size-4 ${card.color}`} />
                  </CardHeader>
                  <CardContent>
                    <p className="text-2xl font-bold">{card.value}</p>
                  </CardContent>
                </Card>
              )
            })}
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm font-medium">Activity</CardTitle>
                  <div className="flex gap-1">
                    {PRESETS.map((p) => (
                      <Button
                        key={p.days}
                        variant={days === p.days ? "default" : "outline"}
                        size="sm"
                        className="h-7 px-2 text-xs"
                        onClick={() => setDays(p.days)}
                      >
                        {p.label}
                      </Button>
                    ))}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={activityData}>
                      <XAxis dataKey="name" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                      <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                      <Tooltip contentStyle={tooltipStyle} />
                      <Bar dataKey="offers" name="Offers" fill="oklch(0.65 0.16 70)" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="restaurants" name="Restaurants" fill="oklch(0.55 0.12 250)" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm font-medium">Top Restaurants by Offers</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  {topRestaurants.length === 0 ? (
                    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">No data</div>
                  ) : (
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={topRestaurants} layout="vertical" margin={{ left: 20, right: 20 }}>
                        <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                        <YAxis dataKey="name" type="category" width={120} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                        <Tooltip contentStyle={tooltipStyle} />
                        <Bar dataKey="offer_count" name="Offers" radius={[0, 4, 4, 0]}>
                          {topRestaurants.map((_, i) => (
                            <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
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
                <CardTitle className="text-sm font-medium">Top Offers by Favorites</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  {topByFavorites.length === 0 ? (
                    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">No favorites yet</div>
                  ) : (
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={topByFavorites} layout="vertical" margin={{ left: 20, right: 20 }}>
                        <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                        <YAxis dataKey="title" type="category" width={140} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                        <Tooltip contentStyle={tooltipStyle} />
                        <Bar dataKey="favorite_count" name="Favorites" radius={[0, 4, 4, 0]}>
                          {topByFavorites.map((_, i) => (
                            <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
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
                <CardTitle className="text-sm font-medium">Top Offers by Views</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  {topByViews.length === 0 ? (
                    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">No views yet</div>
                  ) : (
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={topByViews} layout="vertical" margin={{ left: 20, right: 20 }}>
                        <XAxis type="number" allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                        <YAxis dataKey="title" type="category" width={140} axisLine={false} tickLine={false} tick={{ fontSize: 11 }} />
                        <Tooltip contentStyle={tooltipStyle} />
                        <Bar dataKey="view_count" name="Views" radius={[0, 4, 4, 0]}>
                          {topByViews.map((_, i) => (
                            <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
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
                <CardTitle className="text-sm font-medium">User Growth (30d)</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  {growthData.length === 0 ? (
                    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">No data</div>
                  ) : (
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={growthData}>
                        <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                        <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                        <Tooltip contentStyle={tooltipStyle} />
                        <Line type="monotone" dataKey="users" name="New Users" stroke="oklch(0.65 0.16 70)" strokeWidth={2} dot={false} />
                      </LineChart>
                    </ResponsiveContainer>
                  )}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm font-medium">Offers by Status</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={[
                      { name: "Approved", value: offerStats?.approved ?? 0, fill: "oklch(0.6 0.15 150)" },
                      { name: "Pending", value: offerStats?.pending ?? 0, fill: "oklch(0.65 0.16 70)" },
                      { name: "Rejected", value: offerStats?.rejected ?? 0, fill: "oklch(0.6 0.15 340)" },
                      { name: "Expired", value: offerStats?.expired ?? 0, fill: "oklch(0.5 0.1 180)" },
                    ]}>
                      <XAxis dataKey="name" tick={{ fontSize: 12 }} axisLine={false} tickLine={false} />
                      <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                      <Tooltip contentStyle={tooltipStyle} />
                      <Bar dataKey="value" name="Offers" radius={[4, 4, 0, 0]}>
                        {[0, 1, 2, 3].map((i) => (
                          <Cell key={i} fill={["oklch(0.6 0.15 150)", "oklch(0.65 0.16 70)", "oklch(0.6 0.15 340)", "oklch(0.5 0.1 180)"][i]} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="text-sm font-medium">Recent Activity</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {recentActivity.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No activity yet</p>
                ) : (
                  recentActivity.map((entry) => (
                    <div key={entry.id} className="flex items-start gap-3 text-sm">
                      <div className="mt-1 size-2 shrink-0 rounded-full bg-primary" />
                      <div className="min-w-0 flex-1">
                        <p className="truncate">
                          <span className="font-medium">{entry.admin_name}</span>{" "}
                          <span className="text-muted-foreground">{entry.action.replace(/[._]/g, " ")}</span>
                        </p>
                        <p className="text-xs text-muted-foreground">{formatRelativeTime(entry.created_at)}</p>
                      </div>
                    </div>
                  ))
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="text-sm font-medium">Expiring Soon (7d)</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {expiringOffers.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No offers expiring soon</p>
                ) : (
                  expiringOffers.map((offer) => {
                    const daysLeft = Math.max(0, Math.ceil((new Date(offer.end_date).getTime() - Date.now()) / 86400000))
                    return (
                      <div key={offer.offer_id} className="flex items-center justify-between text-sm">
                        <div className="min-w-0 flex-1">
                          <p className="truncate font-medium">{offer.title}</p>
                          <p className="text-xs text-muted-foreground">{offer.restaurant_name}</p>
                        </div>
                        <span className={`ml-2 shrink-0 text-xs font-medium ${daysLeft <= 2 ? "text-destructive" : "text-warning"}`}>
                          {daysLeft}d left
                        </span>
                      </div>
                    )
                  })
                )}
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 lg:grid-cols-3">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium">Banners</CardTitle>
                <BarChart3 className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-3 gap-4 text-center">
                  <div>
                    <p className="text-2xl font-bold">{stats?.total_banners ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Total</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-warning">{stats?.pending_banners ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Pending</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{stats?.total_banner_clicks ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Clicks</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium">Coupons</CardTitle>
                <Ticket className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4 text-center">
                  <div>
                    <p className="text-2xl font-bold">{stats?.active_coupons ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Active</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold">{stats?.total_coupon_redemptions ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Redemptions</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium">Notifications</CardTitle>
                <Send className="size-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-3 gap-4 text-center">
                  <div>
                    <p className="text-2xl font-bold">{stats?.total_notifications ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Total</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-success">{notifStats?.sent ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Sent</p>
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-destructive">{notifStats?.failed ?? 0}</p>
                    <p className="text-xs text-muted-foreground">Failed</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-medium">Quick Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {[
                { href: "/dashboard/offers", icon: Tag, label: "Manage Offers" },
                { href: "/dashboard/restaurants", icon: Store, label: "Manage Restaurants" },
                { href: "/dashboard/notifications", icon: Send, label: "Send Notification" },
                { href: "/dashboard/audit-log", icon: ChevronRight, label: "View Audit Log" },
              ].map((action) => (
                <a
                  key={action.href}
                  href={action.href}
                  className="flex items-center gap-3 rounded-lg border border-border p-3 text-sm transition-colors hover:bg-accent"
                >
                  <action.icon className="size-4 text-primary" />
                  <span>{action.label}</span>
                </a>
              ))}
            </CardContent>
          </Card>
        </>
      )}
    </>
  )
}

function OwnerDashboard() {
  const [stats, setStats] = useState<{ total_restaurants: number; total_offers: number; pending_restaurants: number; pending_offers: number } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    api.get<{ data: typeof stats }>("/dashboard/stats")
      .then((res) => setStats(res.data))
      .catch(() => setError(true))
      .finally(() => setLoading(false))
  }, [])

  const cards = [
    { title: "My Restaurants", value: stats?.total_restaurants ?? 0, icon: Store },
    { title: "My Offers", value: stats?.total_offers ?? 0, icon: Tag },
    { title: "Pending Restaurants", value: stats?.pending_restaurants ?? 0, icon: Bell },
    { title: "Pending Offers", value: stats?.pending_offers ?? 0, icon: Bell },
  ]

  if (error && !loading) {
    return <Card className="p-6 text-center text-muted-foreground">Failed to load dashboard stats</Card>
  }

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {loading ? (
          <>
            {[1, 2, 3, 4].map((i) => (
              <Card key={i}>
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <Skeleton className="h-4 w-24" />
                  <Skeleton className="size-4" />
                </CardHeader>
                <CardContent>
                  <Skeleton className="h-7 w-16" />
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
            <span>My Offers</span>
          </a>
          <a
            href="/dashboard/restaurants"
            className="flex items-center gap-3 rounded-lg border border-border p-3 text-sm transition-colors hover:bg-accent"
          >
            <Store className="size-4 text-primary" />
            <span>My Restaurants</span>
          </a>
        </CardContent>
      </Card>
    </>
  )
}

export default function DashboardPage() {
  const { isOwner } = useAuth()

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">{isOwner ? "Your business overview" : "Platform overview & analytics"}</p>
        </div>
        {isOwner ? <OwnerDashboard /> : <AdminDashboard />}
      </div>
    </ErrorBoundary>
  )
}
