import { test, expect } from "@playwright/test"

test.describe.serial("Order Platforms", () => {
  const platformName = `E2E Platform ${Date.now()}`
  const displayName = `E2E Display ${Date.now()}`

  test("create an order platform", async ({ page }) => {
    await page.goto("/dashboard/order-platforms")
    await page.getByRole("button", { name: "Add Platform" }).click()

    await page.getByPlaceholder("e.g. Uber Eats").first().fill(platformName)
    await page.getByPlaceholder("e.g. Uber Eats").nth(1).fill(displayName)
    await page.getByPlaceholder("e.g. ubereats://").fill("e2etest://")
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: displayName })).toBeVisible()
  })

  test("edit an order platform", async ({ page }) => {
    await page.goto("/dashboard/order-platforms")
    const updatedName = `${displayName} Updated`
    const row = page.locator("tr", { hasText: displayName })
    await row.getByRole("button").first().click()

    await page.getByPlaceholder("e.g. Uber Eats").nth(1).fill(updatedName)
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: updatedName })).toBeVisible()
  })

  test("delete an order platform", async ({ page }) => {
    await page.goto("/dashboard/order-platforms")
    const row = page.locator("tr", { hasText: platformName })
    await row.getByRole("button").last().click()

    await page.getByRole("alertdialog").getByRole("button", { name: "Delete" }).click()
    await expect(page.locator("tr", { hasText: displayName })).toHaveCount(0)
  })
})
