"use client"

import { useEffect, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { api } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"
import { ErrorBoundary } from "@/components/error-boundary"
import { ArrowLeft, Pencil, Store } from "lucide-react"

interface Restaurant {
  id: string
  name: string
  slug: string
  description: string
  address: string
  latitude: number
  longitude: number
  contact_phone: string
  cuisine_tags: string[]
  cover_image: string
  status: string
  created_at: string
}

export default function RestaurantDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [restaurant, setRestaurant] = useState<Restaurant | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const id = params.id as string
    if (!id) return
    setLoading(true)
    api.get<Restaurant>(`/restaurants/${id}`)
      .then(setRestaurant)
      .catch(() => setRestaurant(null))
      .finally(() => setLoading(false))
  }, [params.id])

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <Card>
          <CardContent className="p-6 space-y-4">
            <Skeleton className="h-6 w-64" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-3/4" />
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!restaurant) {
    return (
      <ErrorBoundary>
        <div className="space-y-6">
          <Button variant="ghost" onClick={() => router.push("/dashboard/restaurants")}>
            <ArrowLeft className="mr-2 size-4" />
            Back to Restaurants
          </Button>
          <Card>
            <CardContent className="p-12 text-center">
              <Store className="mx-auto size-12 text-muted-foreground/50" />
              <h2 className="mt-4 text-lg font-semibold">Restaurant not found</h2>
            </CardContent>
          </Card>
        </div>
      </ErrorBoundary>
    )
  }

  const statusBadge = (status: string) => {
    const variants: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
      approved: "default",
      pending: "secondary",
      rejected: "destructive",
    }
    return <Badge variant={variants[status] || "outline"}>{status}</Badge>
  }

  return (
    <ErrorBoundary>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <Button variant="ghost" onClick={() => router.push("/dashboard/restaurants")}>
            <ArrowLeft className="mr-2 size-4" />
            Back to Restaurants
          </Button>
          <Button variant="outline" onClick={() => router.push("/dashboard/restaurants")}>
            <Pencil className="mr-2 size-4" />
            Edit
          </Button>
        </div>

        {restaurant.cover_image && (
          <div className="relative h-48 w-full overflow-hidden rounded-lg bg-muted">
            <img
              src={restaurant.cover_image}
              alt={restaurant.name}
              className="size-full object-cover"
            />
          </div>
        )}

        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>{restaurant.name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <span className="text-sm text-muted-foreground">Slug</span>
                <p className="font-medium">{restaurant.slug}</p>
              </div>
              <div>
                <span className="text-sm text-muted-foreground">Status</span>
                <div className="mt-1">{statusBadge(restaurant.status)}</div>
              </div>
              {restaurant.description && (
                <div>
                  <span className="text-sm text-muted-foreground">Description</span>
                  <p className="mt-1 text-sm">{restaurant.description}</p>
                </div>
              )}
              <div>
                <span className="text-sm text-muted-foreground">Created</span>
                <p className="font-medium">{new Date(restaurant.created_at).toLocaleDateString()}</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <span className="text-sm text-muted-foreground">Address</span>
                <p className="font-medium">{restaurant.address}</p>
              </div>
              {restaurant.contact_phone && (
                <div>
                  <span className="text-sm text-muted-foreground">Contact</span>
                  <p className="font-medium">{restaurant.contact_phone}</p>
                </div>
              )}
              <div>
                <span className="text-sm text-muted-foreground">Coordinates</span>
                <p className="font-medium">
                  {restaurant.latitude?.toFixed(4)}, {restaurant.longitude?.toFixed(4)}
                </p>
              </div>
              <div>
                <span className="text-sm text-muted-foreground">Cuisine Tags</span>
                <div className="mt-1 flex gap-1 flex-wrap">
                  {restaurant.cuisine_tags?.map((tag) => (
                    <Badge key={tag} variant="outline">{tag}</Badge>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Offers</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              View offers for this restaurant in the{" "}
              <Button variant="link" className="h-auto p-0" onClick={() => router.push("/dashboard/offers")}>
                Offers page
              </Button>
              .
            </p>
          </CardContent>
        </Card>
      </div>
    </ErrorBoundary>
  )
}
