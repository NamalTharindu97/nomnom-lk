import { test, expect } from "@playwright/test"

test.describe.serial("Notification Templates", () => {
  const templateName = `E2E Template ${Date.now()}`

  test("create a template", async ({ page }) => {
    await page.goto("/dashboard/notification-templates")

    await page.getByPlaceholder("e.g., Welcome Message").fill(templateName)
    await page.getByPlaceholder("Hello {{name}}!").fill("E2E Title")
    await page.locator("#tbody").fill("E2E Body for testing")

    await page.getByRole("button", { name: "Create" }).click()

    await expect(page.getByText(templateName)).toBeVisible()
  })

  test("edit a template", async ({ page }) => {
    await page.goto("/dashboard/notification-templates")

    const row = page.locator("tr", { hasText: templateName })
    await row.getByRole("button").first().click()

    await page.getByPlaceholder("Hello {{name}}!").fill("Updated Title")
    await page.getByRole("button", { name: "Update" }).click()

    await expect(page.getByText("Updated Title")).toBeVisible()
  })

  test("delete a template", async ({ page }) => {
    await page.goto("/dashboard/notification-templates")

    const row = page.locator("tr", { hasText: templateName })
    await row.getByRole("button").last().click()

    await page.getByRole("button", { name: "Delete" }).last().click()

    await page.waitForTimeout(500)
    await expect(page.getByText(templateName)).toHaveCount(0)
  })
})
