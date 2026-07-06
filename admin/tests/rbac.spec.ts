import { test, expect, type Page, type BrowserContext } from "@playwright/test"

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"

async function loginAs(page: Page, email: string, password: string) {
  const res = await page.request.post(`${API_BASE}/auth/login`, {
    data: { email, password },
  })
  expect(res.status()).toBe(200)
  const { access_token, user } = await res.json()
  await page.evaluate(
    ({ token, userData }) => {
      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify(userData))
      document.cookie = `token=${token}; path=/; max-age=86400; SameSite=Lax`
      document.cookie = `user=${JSON.stringify(userData)}; path=/; max-age=86400; SameSite=Lax`
    },
    { token: access_token, userData: user }
  )
}

async function clearAuth(page: Page, context: BrowserContext) {
  await context.clearCookies()
  await page.evaluate(() => localStorage.clear())
}

test.describe("RBAC", () => {
  test.describe("Admin role", () => {
    test.beforeEach(async ({ page, context }) => {
      await page.goto("/login")
      await clearAuth(page, context)
      await loginAs(page, "admin@nomnom.lk", "Admin@123")
    })

    test("should see all 12 nav items", async ({ page }) => {
      await page.goto("/dashboard")
      await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible()

      const labels = [
        "Dashboard", "Restaurants", "Offers", "Users", "Owners",
        "Push Notifications", "Templates", "Coupons", "Categories",
        "Analytics", "Audit Log", "Settings",
      ]
      for (const label of labels) {
        await expect(page.locator("nav a", { hasText: label })).toBeVisible()
      }
    })

    test("should access admin-only pages without redirect", async ({ page }) => {
      const pages = [
        { path: "/dashboard/users", heading: "Users" },
        { path: "/dashboard/owners", heading: "Owners" },
        { path: "/dashboard/analytics", heading: "Analytics" },
        { path: "/dashboard/audit-log", heading: "Audit Log" },
      ]
      for (const { path, heading } of pages) {
        await page.goto(path)
        await expect(page.getByRole("heading", { name: heading })).toBeVisible()
      }
    })
  })

  test.describe("Owner role", () => {
    test.beforeEach(async ({ page, context }) => {
      await page.goto("/login")
      await clearAuth(page, context)
      await loginAs(page, "owner@nomnom.lk", "Owner@123")
      await page.goto("/dashboard")
      await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible()
    })

    test("should see 5 nav items", async ({ page }) => {
      const ownerLabels = ["Dashboard", "My Restaurants", "My Offers", "Notifications", "Settings"]
      for (const label of ownerLabels) {
        await expect(page.locator("nav a", { hasText: label })).toBeVisible()
      }

      const hidden = ["Users", "Owners", "Templates", "Coupons", "Categories", "Analytics", "Audit Log"]
      await expect(page.locator("nav a", { hasText: "Users" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Owners" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Templates" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Coupons" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Categories" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Analytics" })).not.toBeVisible()
      await expect(page.locator("nav a", { hasText: "Audit Log" })).not.toBeVisible()
    })

    test("should be redirected from admin-only paths", async ({ page }) => {
      const adminOnlyPaths = [
        "/dashboard/users",
        "/dashboard/owners",
        "/dashboard/analytics",
        "/dashboard/audit-log",
        "/dashboard/coupons",
        "/dashboard/categories",
        "/dashboard/notification-templates",
      ]
      for (const path of adminOnlyPaths) {
        await page.goto(path)
        await expect(page).toHaveURL("/dashboard")
      }
    })
  })

  test.describe("Regular user blocked", () => {
    let regularEmail: string

    test.beforeAll(async ({ request }) => {
      const adminRes = await request.post(`${API_BASE}/auth/login`, {
        data: { email: "admin@nomnom.lk", password: "Admin@123" },
      })
      expect(adminRes.status()).toBe(200)
      const { access_token } = await adminRes.json()

      regularEmail = `e2e_rbac_${Date.now()}@nomnom.lk`
      const createRes = await request.post(`${API_BASE}/users`, {
        data: {
          email: regularEmail,
          password: "Test@123",
          name: "RBAC Test User",
          role: "user",
          is_active: true,
        },
        headers: { Authorization: `Bearer ${access_token}` },
      })
      expect(createRes.status()).toBe(200)
    })

    test("should be redirected from dashboard to login", async ({ page, context }) => {
      await page.goto("/login")
      await clearAuth(page, context)
      await loginAs(page, regularEmail, "Test@123")

      await page.goto("/dashboard")
      await expect(page).toHaveURL(/\/login/)
    })
  })
})
