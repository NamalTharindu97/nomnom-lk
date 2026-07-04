import { test, expect } from "@playwright/test"

test.describe("Analytics", () => {
  test("page loads with stat cards", async ({ page }) => {
    await page.goto("/dashboard/analytics")
    await expect(page.locator("h1")).toContainText("Analytics")

    await expect(page.getByText("Total")).toBeVisible()
    await expect(page.getByText("Approved")).toBeVisible()
    await expect(page.getByText("Pending")).toBeVisible()
  })

  test("charts render without errors", async ({ page }) => {
    await page.goto("/dashboard/analytics")
    await page.waitForTimeout(2000)
    await expect(page.getByText("Top Restaurants by Offers")).toBeVisible()
    await expect(page.getByText("Top Offers by Favorites")).toBeVisible()
    await expect(page.getByText("User Growth")).toBeVisible()
    await expect(page.getByText("Top Offers by Views")).toBeVisible()
  })
})
