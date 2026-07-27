import { test, expect } from "@playwright/test"

test.describe.serial("Social Platforms", () => {
  const platformName = `E2E Social ${Date.now()}`
  const displayName = `E2E Social Display ${Date.now()}`

  test("create a social platform", async ({ page }) => {
    await page.goto("/dashboard/social-platforms")
    await page.getByRole("button", { name: "Add Platform" }).click()

    await page.getByPlaceholder("e.g. Instagram").fill(platformName)
    await page.getByPlaceholder("e.g. Visit Instagram").fill(displayName)
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: displayName })).toBeVisible()
  })

  test("edit a social platform", async ({ page }) => {
    await page.goto("/dashboard/social-platforms")
    const updatedName = `${displayName} Updated`
    const row = page.locator("tr", { hasText: displayName })
    await row.getByRole("button").first().click()

    await page.getByPlaceholder("e.g. Visit Instagram").fill(updatedName)
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: updatedName })).toBeVisible()
  })

  test("delete a social platform", async ({ page }) => {
    await page.goto("/dashboard/social-platforms")
    const row = page.locator("tr", { hasText: displayName })
    await row.getByRole("button").last().click()

    await page.getByRole("alertdialog").getByRole("button", { name: "Delete" }).click()
    await expect(page.locator("tr", { hasText: displayName })).toHaveCount(0)
  })
})
