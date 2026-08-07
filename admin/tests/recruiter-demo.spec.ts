import { expect, test, type Page } from "@playwright/test"

async function openDemo(page: Page) {
  await page.goto("/login")
  await page.getByRole("button", { name: "Explore read-only demo" }).click()
  await expect(page).toHaveURL("/dashboard")
  await expect(page.getByRole("status", { name: "Recruiter demo read-only mode" })).toBeVisible()
}

test.describe("Recruiter demo", () => {
  test.describe.configure({ mode: "serial" })
  test.use({
    storageState: { cookies: [], origins: [] },
    extraHTTPHeaders: { "X-Forwarded-For": "192.0.2.52" },
  })

  test.beforeEach(async ({ context }) => {
    await context.clearCookies()
  })

  test("opens a one-click read-only session with dedicated navigation", async ({ page }) => {
    await openDemo(page)

    const labels = [
      "Dashboard", "Restaurants", "Offers", "Banners", "Categories",
      "Cuisine Tags", "Order Platforms", "Social Platforms",
    ]
    for (const label of labels) {
      await expect(page.locator("nav a", { hasText: label })).toBeVisible()
    }
    for (const label of ["Users", "Owners", "Push Notifications", "Templates", "Coupons", "Audit Log", "Settings"]) {
      await expect(page.locator("nav a", { hasText: label })).not.toBeVisible()
    }
    await expect(page.getByText("Explore portfolio-safe platform analytics")).toBeVisible()
    await expect(page.getByText("Devices", { exact: true })).not.toBeVisible()
    await expect(page.getByText("Recent Activity", { exact: true })).not.toBeVisible()
  })

  test("redirects sensitive routes, omits controls, and rejects direct mutations", async ({ page, context }) => {
    await openDemo(page)
    for (const path of [
      "/dashboard/users",
      "/dashboard/owners",
      "/dashboard/notifications",
      "/dashboard/notification-templates",
      "/dashboard/coupons",
      "/dashboard/audit-log",
      "/dashboard/settings",
    ]) {
      await page.goto(path)
      await expect(page).toHaveURL("/dashboard")
    }

    await page.goto("/dashboard/restaurants")
    await expect(page.getByRole("heading", { name: "Restaurants" })).toBeVisible()
    for (const name of ["New Restaurant", "Export CSV", "Approve", "Reject", "Delete"]) {
      await expect(page.getByRole("button", { name, exact: false })).toHaveCount(0)
    }

    await page.goto("/dashboard/banners")
    await expect(page.getByRole("heading", { name: "Banners" })).toBeVisible()
    await expect(page.getByRole("button", { name: "New Banner" })).toHaveCount(0)
    await expect(page.getByText("All Status")).toBeVisible()

    for (const route of ["categories", "cuisine-tags", "order-platforms", "social-platforms"]) {
      await page.goto(`/dashboard/${route}`)
      for (const name of ["Add", "Create", "Edit", "Delete", "Save", "Upload"]) {
        await expect(page.getByRole("button", { name, exact: false })).toHaveCount(0)
      }
    }

    const csrf = (await context.cookies()).find(cookie => cookie.name === "nomnom_csrf")
    expect(csrf).toBeDefined()

    const response = await page.request.post("/api/v1/dashboard/restaurants", {
      data: { name: "Blocked demo mutation" },
      headers: { "X-CSRF-Token": csrf!.value },
    })
    expect(response.status()).toBe(403)
    expect((await response.json()).error.code).toBe("PORTFOLIO_DEMO_READ_ONLY")
  })

  test("supports responsive one-click login, mobile navigation, logout, and repeat login", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto("/login")
    await expect(page.getByText("Recruiter Demo", { exact: true })).toBeVisible()
    const demoButton = page.getByRole("button", { name: "Explore read-only demo" })
    await expect(demoButton).toBeVisible()
    const buttonBox = await demoButton.boundingBox()
    expect(buttonBox).not.toBeNull()
    expect(buttonBox!.x + buttonBox!.width).toBeLessThanOrEqual(390)
    expect(buttonBox!.y + buttonBox!.height).toBeLessThanOrEqual(844)
    await demoButton.click()
    await expect(page).toHaveURL("/dashboard")
    await page.getByRole("button", { name: "Open navigation" }).click()
    await expect(page.locator("nav a", { hasText: "Restaurants" })).toBeVisible()
    await expect(page.getByRole("status", { name: "Recruiter demo read-only mode" })).toBeVisible()

    await page.getByRole("button", { name: "Log out" }).click()
    await expect(page).toHaveURL("/login")
    await expect(page.getByRole("button", { name: "Explore read-only demo" })).toBeVisible()
    await page.getByRole("button", { name: "Explore read-only demo" }).click()
    await expect(page).toHaveURL("/dashboard")
  })
})
