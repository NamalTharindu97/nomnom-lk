import { Page, Locator, expect } from "@playwright/test"

export class CuisineTagsPage {
  readonly page: Page
  readonly heading: Locator
  readonly nameInput: Locator
  readonly saveButton: Locator
  readonly cancelButton: Locator
  readonly addButton: Locator
  readonly deleteDialog: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Cuisine Tags" })
    this.nameInput = page.locator("#tag-name")
    this.saveButton = page.getByRole("button", { name: "Save" })
    this.cancelButton = page.getByRole("button", { name: "Cancel" })
    this.addButton = page.getByRole("button", { name: "Add Tag" })
    this.deleteDialog = page.getByRole("alertdialog")
  }

  async goto() {
    await this.page.goto("/dashboard/cuisine-tags")
    await expect(this.heading).toBeVisible()
  }

  async fillName(name: string) {
    await this.nameInput.fill(name)
  }

  async clickAddTag() {
    await this.addButton.click()
  }

  async clickSave() {
    await this.saveButton.click()
  }

  async clickEdit(rowText: string) {
    const row = this.page.locator("tr", { hasText: rowText })
    await row.getByRole("button").first().click()
  }

  async clickDelete(rowText: string) {
    const row = this.page.locator("tr", { hasText: rowText })
    await row.getByRole("button").last().click()
  }

  async confirmDelete() {
    await this.deleteDialog.getByRole("button", { name: "Delete" }).click()
  }

  async expectRowVisible(text: string) {
    const row = this.page.locator("tr", { hasText: text })
    await expect(row).toBeVisible()
  }

  async expectRowNotVisible(text: string) {
    const row = this.page.locator("tr", { hasText: text })
    await expect(row).toHaveCount(0)
  }
}
