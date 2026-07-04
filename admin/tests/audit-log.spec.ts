import { test, expect } from "@playwright/test"

test.describe("Audit Log", () => {
  test("page loads with table", async ({ page }) => {
    await page.goto("/dashboard/audit-log")

    await expect(page.getByRole("heading", { name: "Audit Log" })).toBeVisible()
    await expect(page.getByText("Activity History")).toBeVisible()
  })

  test("table has correct headers", async ({ page }) => {
    await page.goto("/dashboard/audit-log")

    await expect(page.getByRole("columnheader", { name: "Admin" })).toBeVisible()
    await expect(page.getByRole("columnheader", { name: "Action" })).toBeVisible()
    await expect(page.getByRole("columnheader", { name: "Entity" })).toBeVisible()
    await expect(page.getByRole("columnheader", { name: "Date" })).toBeVisible()
  })
})
