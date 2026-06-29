import { Page, Locator, expect } from "@playwright/test"

export class NotificationsPage {
  readonly page: Page

  readonly heading: Locator
  readonly titleInput: Locator
  readonly bodyInput: Locator
  readonly targetSelect: Locator
  readonly userIdInput: Locator
  readonly sendButton: Locator
  readonly resultMessage: Locator
  readonly historyTable: Locator
  readonly historyRows: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Push Notifications" })
    this.titleInput = page.getByLabel("Title")
    this.bodyInput = page.getByLabel("Body")
    this.targetSelect = page.getByRole("combobox")
    this.userIdInput = page.getByLabel("User ID")
    this.sendButton = page.getByRole("button", { name: "Send Push Notification" })
    this.resultMessage = page.getByText(/sent|failed|error/i)
    this.historyTable = page.getByRole("table")
    this.historyRows = this.historyTable.getByRole("row")
  }

  async goto() {
    await this.page.goto("/dashboard/notifications")
    await expect(this.heading).toBeVisible()
  }

  async fillForm(title: string, body: string) {
    await this.titleInput.fill(title)
    await this.bodyInput.fill(body)
  }

  async selectTarget(target: "all" | "user") {
    await this.targetSelect.click()
    const optionLabel = target === "all" ? "All Users" : "Specific User"
    await this.page.getByRole("option", { name: optionLabel }).click()
  }

  async expectFormVisible() {
    await expect(this.titleInput).toBeVisible()
    await expect(this.bodyInput).toBeVisible()
    await expect(this.sendButton).toBeVisible()
  }

  async expectHistoryVisible() {
    await expect(this.page.getByText("Notification History")).toBeVisible()
  }
}
