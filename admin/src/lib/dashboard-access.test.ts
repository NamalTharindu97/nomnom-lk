import { describe, expect, it } from "vitest"
import { canAccessDashboardRoute, isPortfolioViewer } from "./dashboard-access"

describe("dashboard role access", () => {
  it("allows viewer portfolio routes and restaurant details", () => {
    expect(canAccessDashboardRoute("portfolio_viewer", "/dashboard/categories")).toBe(true)
    expect(canAccessDashboardRoute("portfolio_viewer", "/dashboard/restaurants/example-id")).toBe(true)
  })

  it("redirects viewers away from sensitive routes", () => {
    for (const path of [
      "/dashboard/users",
      "/dashboard/owners",
      "/dashboard/notifications",
      "/dashboard/notification-templates",
      "/dashboard/coupons",
      "/dashboard/audit-log",
      "/dashboard/settings",
    ]) {
      expect(canAccessDashboardRoute("portfolio_viewer", path)).toBe(false)
    }
  })

  it("preserves owner and admin access rules", () => {
    expect(canAccessDashboardRoute("restaurant_owner", "/dashboard/settings")).toBe(true)
    expect(canAccessDashboardRoute("restaurant_owner", "/dashboard/categories")).toBe(false)
    expect(canAccessDashboardRoute("admin", "/dashboard/audit-log")).toBe(true)
    expect(isPortfolioViewer("portfolio_viewer")).toBe(true)
  })

  it("denies unknown and missing roles instead of treating them as owners", () => {
    expect(canAccessDashboardRoute("user", "/dashboard")).toBe(false)
    expect(canAccessDashboardRoute("unexpected_role", "/dashboard/settings")).toBe(false)
    expect(canAccessDashboardRoute(undefined, "/dashboard")).toBe(false)
  })
})
