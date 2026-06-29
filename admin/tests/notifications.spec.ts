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

  test("should show user id field when target is specific user", async () => {
    await notifPage.selectTarget("user")
    await expect(notifPage.userIdInput).toBeVisible()
  })

  test("should hide user id field when target is all users", async () => {
    await notifPage.selectTarget("user")
    await expect(notifPage.userIdInput).toBeVisible()

    await notifPage.selectTarget("all")
    await expect(notifPage.userIdInput).not.toBeVisible()
  })
})
