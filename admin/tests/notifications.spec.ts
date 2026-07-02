import { test, expect } from "@playwright/test"
import { NotificationsPage } from "./pages/notifications.page"

test.describe("Push Notifications", () => {
  let notifPage: NotificationsPage

  test.beforeEach(async ({ page }) => {
    notifPage = new NotificationsPage(page)
    await notifPage.goto()
  })

  test("should display the send notification form", async () => {
    await notifPage.expectFormVisible()
    await expect(notifPage.targetSelect).toBeVisible()
  })

  test("should display notification history table", async () => {
    await notifPage.expectHistoryVisible()
  })

  test("should show user combobox when target is specific user", async () => {
    await notifPage.selectTarget("user")
    await expect(notifPage.userComboBox).toBeVisible()
  })

  test("should hide user combobox when target is all users", async () => {
    await notifPage.selectTarget("user")
    await expect(notifPage.userComboBox).toBeVisible()

    await notifPage.selectTarget("all")
    await expect(notifPage.userComboBox).not.toBeVisible()
  })

  test("should search and select a user from combobox", async ({ page }) => {
    await notifPage.selectTarget("user")
    await notifPage.userComboBox.click()
    await notifPage.userSearchInput.fill("admin")

    const adminOption = page.getByRole("option", { name: /admin@nomnom/ })
    await expect(adminOption).toBeVisible()
    await adminOption.click()

    await expect(notifPage.userComboBox).toContainText("admin@nomnom")
  })
})
