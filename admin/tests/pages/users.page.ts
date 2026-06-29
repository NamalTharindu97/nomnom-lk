import { Page, Locator, expect } from "@playwright/test"

export class UsersPage {
  readonly page: Page

  readonly heading: Locator
  readonly table: Locator
  readonly tableRows: Locator
  readonly paginationBar: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Users" })
    this.table = page.getByRole("table")
    this.tableRows = this.table.getByRole("row")
    this.paginationBar = page.locator("[data-testid=pagination-bar]")
  }

  async goto() {
    await this.page.goto("/dashboard/users")
    await expect(this.heading).toBeVisible()
  }

  async getRowByEmail(email: string): Promise<Locator> {
    return this.table.getByRole("row").filter({ hasText: email })
  }

  async getRoleSelect(email: string): Promise<Locator> {
    const row = await this.getRowByEmail(email)
    return row.getByRole("combobox")
  }

  async changeRole(email: string, newRole: string) {
    const select = await this.getRoleSelect(email)
    await select.click()
    await this.page.getByRole("option", { name: newRole }).click()
  }

  async clickDelete(email: string) {
    const row = await this.getRowByEmail(email)
    await row.getByRole("button").click()
  }

  async expectUserVisible(email: string) {
    const row = await this.getRowByEmail(email)
    await expect(row).toBeVisible()
  }

  async expectRole(email: string, role: string) {
    const row = await this.getRowByEmail(email)
    await expect(row).toContainText(role)
  }
}
