import { test, expect } from "@playwright/test"

test.describe("Dashboard Analytics", () => {
  test("shows stat cards and charts", async ({ page }) => {
    await page.goto("/dashboard")
    await expect(page.getByRole("heading", { name: "Dashboard" })).toBeVisible()

    await expect(page.getByRole("main").getByText("Restaurants", { exact: true })).toBeVisible()
    await expect(page.getByRole("main").getByText("Users", { exact: true })).toBeVisible()
  })

  test("shows analytics sections", async ({ page }) => {
    await page.goto("/dashboard")
    await page.waitForTimeout(2000)
    await expect(page.getByText("Top Restaurants by Offers")).toBeVisible()
    await expect(page.getByText("Top Offers by Favorites")).toBeVisible()
    await expect(page.getByText("User Growth")).toBeVisible()
    await expect(page.getByText("Top Offers by Views")).toBeVisible()
  })
})
