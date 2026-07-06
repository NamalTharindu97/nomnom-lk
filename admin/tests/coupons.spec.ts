import { test, expect } from "@playwright/test"

test.describe.serial("Coupons", () => {
  const couponCode = `E2E${Date.now().toString().slice(-6)}`

  test("create a coupon", async ({ page }) => {
    await page.goto("/dashboard/coupons")

    await page.getByPlaceholder("SAVE20").fill(couponCode)
    await page.locator("#discount").fill("10")
    await page.getByRole("button", { name: "Create" }).click()

    await expect(page.getByText(couponCode)).toBeVisible()
  })

  test("activate and deactivate a coupon", async ({ page }) => {
    await page.goto("/dashboard/coupons")
    await page.waitForLoadState("networkidle")

    const row = page.getByRole("row", { name: new RegExp(couponCode) })
    await row.getByRole("button", { name: "Deactivate" }).click()
    await page.getByRole("alertdialog").getByRole("button", { name: "Deactivate" }).click()

    await expect(row.getByText("Inactive")).toBeVisible()

    await row.getByRole("button", { name: "Activate" }).click()
    await page.getByRole("alertdialog").getByRole("button", { name: "Activate" }).click()
    await expect(row.getByText("Active")).toBeVisible()
  })

  test("delete a coupon", async ({ page }) => {
    await page.goto("/dashboard/coupons")
    await page.waitForLoadState("networkidle")

    const row = page.getByRole("row", { name: new RegExp(couponCode) })
    await row.getByRole("button").last().click()

    await page.getByRole("button", { name: "Delete" }).last().click()
    await page.waitForTimeout(500)
    await expect(page.getByText(couponCode)).toHaveCount(0)
  })
})
