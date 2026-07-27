import { test, expect } from "@playwright/test"

test.describe.serial("Owners", () => {
  const ownerEmail = "kfc@nomnom.lk"

  test("owners page loads with table", async ({ page }) => {
    await page.goto("/dashboard/owners")
    await expect(page.getByRole("heading", { name: "Owners" })).toBeVisible()
    await expect(page.getByRole("table")).toBeVisible()
    await expect(page.getByRole("row").filter({ hasText: ownerEmail })).toBeVisible()
  })

  test("shows owner stats in table", async ({ page }) => {
    await page.goto("/dashboard/owners")
    await page.waitForLoadState("networkidle")

    const row = page.locator("tr", { hasText: ownerEmail })
    await expect(row).toBeVisible()
    await expect(row.locator("td").nth(3)).toBeVisible()
    await expect(row.locator("td").nth(4)).toBeVisible()
  })

  test("suspend an owner", async ({ page }) => {
    await page.goto("/dashboard/owners")
    await page.waitForLoadState("networkidle")

    const row = page.locator("tr", { hasText: ownerEmail })
    await row.getByRole("button", { name: "Suspend" }).click()
    await page.getByRole("alertdialog").getByRole("button", { name: "Suspend" }).click()

    await expect(row.getByText("Suspended")).toBeVisible()
  })

  test("activate an owner", async ({ page }) => {
    await page.goto("/dashboard/owners")
    await page.waitForLoadState("networkidle")

    const row = page.locator("tr", { hasText: ownerEmail })
    await row.getByRole("button", { name: "Activate" }).click()
    await page.getByRole("alertdialog").getByRole("button", { name: "Activate" }).click()

    await expect(row.getByText("Active")).toBeVisible()
  })
})
