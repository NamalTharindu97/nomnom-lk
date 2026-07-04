import { test, expect } from "@playwright/test"

test.describe("Bulk Operations", () => {
  test("checkboxes appear and select all works on restaurants", async ({ page }) => {
    await page.goto("/dashboard/restaurants")

    const selectAll = page.locator("table thead input[type='checkbox']")
    await expect(selectAll).toBeVisible()

    await selectAll.click()

    await expect(page.getByText(/selected/)).toBeVisible()
  })

  test("bulk bar shows Approve, Reject, Delete buttons", async ({ page }) => {
    await page.goto("/dashboard/restaurants")

    const selectAll = page.locator("table thead input[type='checkbox']")
    await selectAll.click()

    await expect(page.getByText(/selected/)).toBeVisible()
    await expect(page.getByRole("button", { name: "Approve All" })).toBeVisible()
    await expect(page.getByRole("button", { name: "Reject All" })).toBeVisible()
    await expect(page.getByRole("button", { name: "Delete All" })).toBeVisible()
    await expect(page.getByRole("button", { name: "Clear" })).toBeVisible()
  })

  test("clear deselects all", async ({ page }) => {
    await page.goto("/dashboard/restaurants")

    const selectAll = page.locator("table thead input[type='checkbox']")
    await selectAll.click()
    await page.getByRole("button", { name: "Clear" }).click()

    await expect(page.getByText(/selected/)).toHaveCount(0)
  })
})
