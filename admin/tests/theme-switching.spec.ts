import { test, expect } from "@playwright/test"

test.describe("Theme Switching", () => {
  test("dark mode toggle on login page", async ({ page }) => {
    await page.goto("/login")

    await expect(page.getByText("Light")).toBeVisible()
    await expect(page.getByText("Dark")).toBeVisible()

    await page.getByText("Dark").click()

    const htmlClass = await page.locator("html").getAttribute("class")
    expect(htmlClass).toContain("dark")
  })

  test("switches back to light from dark", async ({ page }) => {
    await page.goto("/login")

    await page.getByText("Dark").click()
    await expect(page.locator("html")).toHaveClass(/dark/)

    await page.getByText("Light").click()
    await expect(page.locator("html")).not.toHaveClass(/dark/)
  })
})
