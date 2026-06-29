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

  test("should show admin user in the list", async () => {
    await usersPage.expectUserVisible("admin@nomnom.lk")
    await usersPage.expectRole("admin@nomnom.lk", "admin")
  })
})
