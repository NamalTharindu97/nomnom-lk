import { test, expect } from "@playwright/test"
import { UsersPage } from "./pages/users.page"
import { LoginPage } from "./pages/login.page"

test.describe("Users", () => {
  let usersPage: UsersPage

  test.beforeEach(async ({ page }) => {
    usersPage = new UsersPage(page)
    await usersPage.goto()
  })

  test("should display users table", async () => {
    await expect(usersPage.table).toBeVisible()
  })

  test("should show admin user in the list", async ({ page }) => {
    await page.getByPlaceholder("Search by email...").fill("admin@nomnom.lk")
    await page.waitForTimeout(500)
    await usersPage.expectUserVisible("admin@nomnom.lk")
    await usersPage.expectRole("admin@nomnom.lk", "admin")
  })
})
