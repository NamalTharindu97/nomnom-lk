export type DashboardRole = "admin" | "restaurant_owner" | "portfolio_viewer"

export const VIEWER_ROUTES = [
  "/dashboard",
  "/dashboard/restaurants",
  "/dashboard/offers",
  "/dashboard/banners",
  "/dashboard/categories",
  "/dashboard/cuisine-tags",
  "/dashboard/order-platforms",
  "/dashboard/social-platforms",
] as const

export const OWNER_ROUTES = [
  "/dashboard",
  "/dashboard/restaurants",
  "/dashboard/offers",
  "/dashboard/banners",
  "/dashboard/settings",
] as const

function routeMatches(pathname: string, route: string) {
  return pathname === route || (route !== "/dashboard" && pathname.startsWith(`${route}/`))
}

export function canAccessDashboardRoute(role: string | undefined, pathname: string) {
  if (role === "admin") return true
  const allowed = role === "portfolio_viewer"
    ? VIEWER_ROUTES
    : role === "restaurant_owner"
      ? OWNER_ROUTES
      : []
  return allowed.some((route) => routeMatches(pathname, route))
}

export function isPortfolioViewer(role: string | undefined) {
  return role === "portfolio_viewer"
}
