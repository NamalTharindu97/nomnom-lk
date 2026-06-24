"use client"

import { useEffect, useState } from "react"
import { api } from "@/lib/api"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Store, Tag, Users, Bell } from "lucide-react"

export default function DashboardPage() {
  const [stats, setStats] = useState({
    restaurants: 0,
    offers: 0,
    pendingRestaurants: 0,
    pendingOffers: 0,
  })

  useEffect(() => {
    async function load() {
      try {
        const [restRes, offerRes] = await Promise.all([
          api.get<{ pagination: { total: number } }>("/restaurants?per_page=1"),
          api.get<{ pagination: { total: number } }>("/offers?per_page=1"),
        ])
        setStats((prev) => ({
          ...prev,
          restaurants: restRes.pagination?.total || 0,
          offers: offerRes.pagination?.total || 0,
        }))
      } catch {}
    }
    load()
  }, [])

  const cards = [
    { title: "Total Restaurants", value: stats.restaurants, icon: Store, color: "text-blue-600" },
    { title: "Total Offers", value: stats.offers, icon: Tag, color: "text-green-600" },
    { title: "Pending Restaurants", value: stats.pendingRestaurants, icon: Bell, color: "text-amber-600" },
    { title: "Pending Offers", value: stats.pendingOffers, icon: Bell, color: "text-red-600" },
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
                <Icon className={`size-4 ${card.color}`} />
              </CardHeader>
              <CardContent>
                <p className="text-2xl font-bold">{card.value}</p>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
