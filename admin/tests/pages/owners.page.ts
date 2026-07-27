import { Page, Locator, expect } from "@playwright/test"

export class OwnersPage {
  readonly page: Page
  readonly heading: Locator
  readonly table: Locator
  readonly tableRows: Locator
  readonly deleteDialog: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Owners" })
    this.table = page.getByRole("table")
    this.tableRows = this.table.getByRole("row")
    this.deleteDialog = page.getByRole("alertdialog")
  }

  async goto() {
    await this.page.goto("/dashboard/owners")
    await expect(this.heading).toBeVisible()
  }

  async expectStatsVisible() {
    await expect(this.heading).toBeVisible()
    await expect(this.table).toBeVisible()
  }

  async expectTableVisible() {
    await expect(this.table).toBeVisible()
    await expect(this.tableRows.first()).toBeVisible()
  }

  async clickSuspend(rowText: string) {
    const row = this.page.locator("tr", { hasText: rowText })
    await row.getByRole("button", { name: "Suspend" }).click()
  }

  async clickActivate(rowText: string) {
    const row = this.page.locator("tr", { hasText: rowText })
    await row.getByRole("button", { name: "Activate" }).click()
  }

  async confirmAction() {
    await this.deleteDialog.getByRole("button", { name: /Suspend|Activate/ }).click()
  }

  async expectStatus(rowText: string, status: string) {
    const row = this.page.locator("tr", { hasText: rowText })
    await expect(row.getByText(status)).toBeVisible()
  }

  async expectRowVisible(text: string) {
    const row = this.page.locator("tr", { hasText: text })
    await expect(row).toBeVisible()
  }
}
