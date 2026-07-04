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
    await expect(this.page.getByText("Total Restaurants")).toBeVisible()
    await expect(this.page.getByText("Total Offers")).toBeVisible()
    await expect(this.page.getByText("Total Users")).toBeVisible()
    await expect(this.page.getByText("Pending Reviews")).toBeVisible()
  }

  async expectStatValuesLoaded() {
    await expect(this.page.locator("p.font-bold")).toHaveCount(4, { timeout: 10000 })
  }
}
