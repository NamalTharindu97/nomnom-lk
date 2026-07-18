import { Page, Locator, expect } from "@playwright/test"

export class DashboardPage {
  readonly page: Page

  readonly heading: Locator
  readonly statCards: Locator
  readonly activityChart: Locator
  readonly quickActions: Locator

  readonly manageOffersLink: Locator
  readonly manageRestaurantsLink: Locator
  readonly sendNotificationLink: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Dashboard" })
    this.statCards = page.locator("div.grid > div").first()
    this.activityChart = page.getByText("Activity").first()
    this.quickActions = page.getByText("Quick Actions")

    this.manageOffersLink = page.getByRole("link", { name: "Manage Offers" })
    this.manageRestaurantsLink = page.getByRole("link", { name: "Manage Restaurants" })
    this.sendNotificationLink = page.getByRole("link", { name: "Send Notification" })
  }

  async goto() {
    await this.page.goto("/dashboard")
    await expect(this.heading).toBeVisible()
  }

  async getStatCardValue(title: string): Promise<string> {
    const card = this.page.getByRole("heading", { name: title }).locator("..")
    return (await card.locator("p.text-2xl").textContent()) || ""
  }

  async expectStatCardsVisible() {
    const main = this.page.getByRole("main")
    await expect(main.getByText("Restaurants", { exact: true }).first()).toBeVisible()
    await expect(main.getByText("Offers", { exact: true }).first()).toBeVisible()
    await expect(main.getByText("Users", { exact: true }).first()).toBeVisible()
    await expect(main.getByText("Pending", { exact: true }).first()).toBeVisible()
    await expect(main.getByText("Approval", { exact: true }).first()).toBeVisible()
    await expect(main.getByText("Devices", { exact: true }).first()).toBeVisible()
  }

  async expectStatValuesLoaded() {
    await expect(this.page.locator("p.text-2xl.font-bold").first()).toBeVisible({ timeout: 10000 })
  }
}
