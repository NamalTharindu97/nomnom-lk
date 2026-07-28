import { test, expect } from "@playwright/test"

test.describe.serial("Order Platforms", () => {
  const platformName = `E2E Platform ${Date.now()}`
  const displayName = `E2E Display ${Date.now()}`
  const updatedDisplayName = `${displayName} Updated`

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
    const row = page.locator("tr", { hasText: displayName })
    await row.getByRole("button").first().click()

    await page.getByPlaceholder("e.g. Uber Eats").nth(1).fill(updatedDisplayName)
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: updatedDisplayName })).toBeVisible()
  })

  test("delete an order platform", async ({ page }) => {
    await page.goto("/dashboard/order-platforms")
    const row = page.locator("tr", { hasText: updatedDisplayName })
    await row.getByRole("button").last().click()

    await page.getByRole("alertdialog").getByRole("button", { name: "Delete" }).click()
    await expect(page.locator("tr", { hasText: updatedDisplayName })).toHaveCount(0)
  })
})
