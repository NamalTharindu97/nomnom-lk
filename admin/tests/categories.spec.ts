import { test, expect } from "@playwright/test"

test.describe.serial("Categories", () => {
  const categoryName = `E2E Test ${Date.now()}`

  test("create a category", async ({ page }) => {
    await page.goto("/dashboard/categories")

    await page.getByPlaceholder("Pizza & Pasta").fill(categoryName)
    await page.getByRole("button", { name: "Create" }).click()

    await expect(page.getByText(categoryName)).toBeVisible()
  })

  test("edit a category", async ({ page }) => {
    await page.goto("/dashboard/categories")

    const updatedName = `${categoryName} Updated`
    const row = page.locator("tr", { hasText: categoryName })
    await row.getByRole("button").first().click()

    await page.getByPlaceholder("Pizza & Pasta").fill(updatedName)
    await page.getByRole("button", { name: "Update" }).click()

    await expect(page.getByText(updatedName)).toBeVisible()
  })

  test("delete a category", async ({ page }) => {
    await page.goto("/dashboard/categories")

    const row = page.locator("tr", { hasText: categoryName })
    await row.getByRole("button").last().click()

    await page.getByRole("button", { name: "Delete" }).last().click()
    await page.waitForTimeout(500)
    await expect(page.locator("tr", { hasText: categoryName })).toHaveCount(0)
  })
})
