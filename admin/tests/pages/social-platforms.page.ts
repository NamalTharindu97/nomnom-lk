import { Page, Locator, expect } from "@playwright/test"

export class SocialPlatformsPage {
  readonly page: Page
  readonly heading: Locator
  readonly nameInput: Locator
  readonly displayNameInput: Locator
  readonly saveButton: Locator
  readonly cancelButton: Locator
  readonly addButton: Locator
  readonly deleteDialog: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Social Platforms" })
    this.nameInput = this.page.getByPlaceholder("e.g. Instagram").first()
    this.displayNameInput = this.page.getByPlaceholder("e.g. Visit Instagram")
    this.saveButton = page.getByRole("button", { name: "Save" })
    this.cancelButton = page.getByRole("button", { name: "Cancel" })
    this.addButton = page.getByRole("button", { name: "Add Platform" })
    this.deleteDialog = page.getByRole("alertdialog")
  }

  async goto() {
    await this.page.goto("/dashboard/social-platforms")
    await expect(this.heading).toBeVisible()
  }

  async fillForm(data: { name?: string; displayName?: string }) {
    if (data.name) await this.nameInput.fill(data.name)
    if (data.displayName) await this.displayNameInput.fill(data.displayName)
  }

  async clickAddPlatform() {
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
