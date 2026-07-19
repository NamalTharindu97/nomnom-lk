import { test, expect, type Page } from "@playwright/test"

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"

async function authenticate(page: Page, email: string, password: string) {
  const response = await page.request.post(`${API_BASE}/auth/login`, {
    data: { email, password },
  })
  expect(response.status()).toBe(200)
  const { access_token, user } = await response.json()
  await page.evaluate(({ token, userData }) => {
    localStorage.setItem("token", token)
    localStorage.setItem("user", JSON.stringify(userData))
    document.cookie = `token=${token}; path=/; max-age=86400; SameSite=Lax`
    document.cookie = `user=${JSON.stringify(userData)}; path=/; max-age=86400; SameSite=Lax`
  }, { token: access_token, userData: user })
  return access_token as string
}

test("owner banner becomes active after admin approval and updates owner metrics", async ({ page }) => {
  const title = `E2E Owner Banner ${Date.now()}`
  let bannerId = ""

  await page.goto("/login")
  const ownerToken = await authenticate(page, "kfc@nomnom.lk", "Owner@123")
  await page.goto("/dashboard/banners")

  await page.getByRole("button", { name: "New Banner" }).click()
  await page.getByRole("combobox").click()
  await page.getByRole("option").first().click()
  await page.getByPlaceholder("Image URL").fill("https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=1024&h=360&fit=crop")
  await page.getByPlaceholder("e.g. Weekend Special!").fill(title)
  await page.getByRole("button", { name: "Submit for Approval" }).click()
  await expect(page.getByText("Banner submitted for approval", { exact: true })).toBeVisible()
  await expect(page.getByRole("row").filter({ hasText: title })).toContainText("Pending")

  const ownerList = await page.request.get(`${API_BASE}/dashboard/banners`, {
    headers: { Authorization: `Bearer ${ownerToken}` },
  })
  const ownerBanners = (await ownerList.json()).data as Array<{ id: string; title: string }>
  bannerId = ownerBanners.find((banner) => banner.title === title)?.id || ""
  expect(bannerId).not.toBe("")

  const adminToken = await authenticate(page, "admin@nomnom.lk", "Admin@123")
  await page.goto("/dashboard/banners")
  const adminRow = page.getByRole("row").filter({ hasText: title })
  await adminRow.getByRole("button", { name: "Approve" }).click()
  await expect(page.getByText("Banner approved", { exact: true })).toBeVisible()
  await expect(adminRow).toContainText("Approved")

  const activeResponse = await page.request.get(`${API_BASE}/banners/active`)
  expect(activeResponse.status()).toBe(200)
  const activeBanners = (await activeResponse.json()).data as Array<{ id: string }>
  expect(activeBanners.some((banner) => banner.id === bannerId)).toBe(true)

  const statsResponse = await page.request.get(`${API_BASE}/dashboard/stats`, {
    headers: { Authorization: `Bearer ${ownerToken}` },
  })
  expect(statsResponse.status()).toBe(200)
  const stats = (await statsResponse.json()).data as { total_banners: number; active_banners: number }
  expect(stats.total_banners).toBeGreaterThanOrEqual(1)
  expect(stats.active_banners).toBeGreaterThanOrEqual(1)

  await page.request.delete(`${API_BASE}/admin/banners/${bannerId}`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  })
})
