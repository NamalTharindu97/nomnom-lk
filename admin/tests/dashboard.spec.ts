import { test, expect } from "@playwright/test"
import { DashboardPage } from "./pages/dashboard.page"

test.describe("Dashboard", () => {
  let dashboard: DashboardPage

  test.beforeEach(async ({ page }) => {
    dashboard = new DashboardPage(page)
    await dashboard.goto()
  })

  test("should display all stat cards with values", async () => {
    await dashboard.expectStatCardsVisible()
    await dashboard.expectStatValuesLoaded()
  })

  test("should display activity chart", async () => {
    await expect(dashboard.activityChart).toBeVisible()
  })

  test("should navigate to offers page via quick action", async ({ page }) => {
    await dashboard.manageOffersLink.click()
    await expect(page).toHaveURL("/dashboard/offers")
    await expect(page.getByRole("heading", { name: "Offers" })).toBeVisible()
  })

  test("should navigate to restaurants page via quick action", async ({ page }) => {
    await dashboard.manageRestaurantsLink.click()
    await expect(page).toHaveURL("/dashboard/restaurants")
    await expect(page.getByRole("heading", { name: "Restaurants" })).toBeVisible()
  })

  test("should navigate to notifications page via quick action", async ({ page }) => {
    await dashboard.sendNotificationLink.click()
    await expect(page).toHaveURL("/dashboard/notifications")
    await expect(page.getByRole("heading", { name: "Push Notifications" })).toBeVisible()
  })
})
