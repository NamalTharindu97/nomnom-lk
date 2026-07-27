import { test, expect } from "@playwright/test"

test.describe.serial("Cuisine Tags", () => {
  const tagName = `E2E Tag ${Date.now()}`

  test("create a cuisine tag", async ({ page }) => {
    await page.goto("/dashboard/cuisine-tags")
    await page.getByRole("button", { name: "Add Tag" }).click()
    await page.locator("#tag-name").fill(tagName)
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.locator("tr", { hasText: tagName })).toBeVisible()
  })

  test("edit a cuisine tag", async ({ page }) => {
    await page.goto("/dashboard/cuisine-tags")
    const updatedName = `${tagName} Updated`
    const row = page.locator("tr", { hasText: tagName })
    await row.getByRole("button").first().click()

    await row.getByRole("textbox").fill(updatedName)
    await row.getByRole("button").first().click()

    await expect(page.locator("tr", { hasText: updatedName })).toBeVisible()
  })

  test("delete a cuisine tag", async ({ page }) => {
    await page.goto("/dashboard/cuisine-tags")
    const row = page.locator("tr", { hasText: tagName })
    await row.getByRole("button").last().click()

    await page.getByRole("alertdialog").getByRole("button", { name: "Delete" }).click()
    await expect(page.locator("tr", { hasText: tagName })).toHaveCount(0)
  })

  test("shows validation for empty name", async ({ page }) => {
    await page.goto("/dashboard/cuisine-tags")
    await page.getByRole("button", { name: "Add Tag" }).click()
    await page.locator("#tag-name").fill("")
    await page.getByRole("button", { name: "Save" }).click()

    await expect(page.getByText("Name is required")).toBeVisible()
  })
})
