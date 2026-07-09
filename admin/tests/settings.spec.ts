import { test, expect } from "@playwright/test"

test.describe("Settings", () => {
  test("change password form renders", async ({ page }) => {
    await page.goto("/dashboard/settings")

    await expect(page.getByText("Change Password")).toBeVisible()
    await expect(page.getByLabel("Current Password")).toBeVisible()
    await expect(page.getByRole("textbox", { name: "New Password", exact: true })).toBeVisible()
    await expect(page.getByRole("textbox", { name: "Confirm New Password" })).toBeVisible()
    await expect(page.getByRole("button", { name: "Update Password" })).toBeVisible()
  })

  test("shows validation error for empty fields", async ({ page }) => {
    await page.goto("/dashboard/settings")

    await page.getByRole("button", { name: "Update Password" }).click()
    await expect(page.getByText("Current password is required", { exact: true })).toBeVisible()
  })
})
