import { Page, Locator, expect } from "@playwright/test"

export class RestaurantsPage {
  readonly page: Page

  readonly heading: Locator
  readonly newRestaurantButton: Locator
  readonly table: Locator
  readonly tableRows: Locator
  readonly paginationBar: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Restaurants" })
    this.newRestaurantButton = page.getByRole("button", { name: "New Restaurant" })
    this.table = page.getByRole("table")
    this.tableRows = this.table.getByRole("row")
    this.paginationBar = page.locator("[data-testid=pagination-bar]")
  }

  async goto() {
    await this.page.goto("/dashboard/restaurants")
    await expect(this.heading).toBeVisible()
  }

  async getRowByName(name: string): Promise<Locator> {
    return this.table.getByRole("row").filter({ hasText: name })
  }

  async clickNewRestaurant() {
    await this.newRestaurantButton.click()
    await expect(this.page.getByRole("dialog")).toBeVisible()
  }

  async clickEdit(name: string) {
    const row = await this.getRowByName(name)
    await row.getByRole("button").first().click()
    await expect(this.page.getByRole("dialog")).toBeVisible()
  }

  async clickDelete(name: string) {
    const row = await this.getRowByName(name)
    const buttons = row.getByRole("button")
    const count = await buttons.count()
    await buttons.nth(1).click()
  }

  async confirmDeleteDialog() {
    await this.page.getByRole("button", { name: "Delete" }).last().click()
  }

  async clickApprove(name: string) {
    const row = await this.getRowByName(name)
    await row.getByRole("button", { name: "Approve" }).click()
  }

  async clickReject(name: string) {
    const row = await this.getRowByName(name)
    await row.getByRole("button", { name: "Reject" }).click()
  }

  async expectRowVisible(name: string) {
    const row = await this.getRowByName(name)
    await expect(row).toBeVisible()
  }

  async expectRowNotVisible(name: string) {
    const row = this.table.getByRole("row").filter({ hasText: name })
    await expect(row).toHaveCount(0)
  }
}

export class RestaurantDialog {
  readonly page: Page

  readonly dialog: Locator
  readonly nameInput: Locator
  readonly slugInput: Locator
  readonly addressInput: Locator
  readonly phoneInput: Locator
  readonly cuisineTagsInput: Locator
  readonly descriptionInput: Locator
  readonly nameSiInput: Locator
  readonly nameTaInput: Locator
  readonly descriptionSiInput: Locator
  readonly descriptionTaInput: Locator
  readonly coverImageInput: Locator
  readonly cancelButton: Locator
  readonly submitButton: Locator

  constructor(page: Page) {
    this.page = page
    this.dialog = page.getByRole("dialog")
    this.nameInput = page.getByLabel("Name").first()
    this.slugInput = page.getByLabel("Slug")
    this.addressInput = page.getByLabel("Address")
    this.phoneInput = page.getByLabel("Phone")
    this.cuisineTagsInput = page.getByLabel("Cuisine Tags (comma-separated)")
    this.descriptionInput = page.locator("#description")
    this.nameSiInput = page.locator("#name_si")
    this.nameTaInput = page.locator("#name_ta")
    this.descriptionSiInput = page.locator("#description_si")
    this.descriptionTaInput = page.locator("#description_ta")
    this.coverImageInput = page.locator('input[type="file"]')
    this.cancelButton = page.getByRole("button", { name: "Cancel" })
    this.submitButton = page.getByRole("button", { name: /Create|Update/ })
  }

  async expectOpen() {
    await expect(this.dialog).toBeVisible()
  }

  async expectClosed() {
    await expect(this.dialog).not.toBeVisible()
  }

  async fillName(name: string) {
    await this.nameInput.fill(name)
  }

  async fillSlug(slug: string) {
    await this.slugInput.fill(slug)
  }

  async fillAddress(address: string) {
    await this.addressInput.fill(address)
  }

  async fillPhone(phone: string) {
    await this.phoneInput.fill(phone)
  }

  async fillCuisineTags(tags: string) {
    await this.cuisineTagsInput.fill(tags)
  }

  async fillDescription(description: string) {
    await this.descriptionInput.fill(description)
  }

  async fillNameSi(name: string) {
    await this.nameSiInput.fill(name)
  }

  async fillNameTa(name: string) {
    await this.nameTaInput.fill(name)
  }

  async fillDescriptionSi(description: string) {
    await this.descriptionSiInput.fill(description)
  }

  async fillDescriptionTa(description: string) {
    await this.descriptionTaInput.fill(description)
  }

  async setCoverImage(filePath: string) {
    await this.coverImageInput.setInputFiles(filePath)
  }

  async clickSubmit() {
    await this.submitButton.dispatchEvent("click")
  }

  async clickCancel() {
    await this.cancelButton.click()
  }
}
