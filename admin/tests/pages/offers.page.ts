import { Page, Locator, expect } from "@playwright/test"

export class OffersPage {
  readonly page: Page

  readonly heading: Locator
  readonly newOfferButton: Locator
  readonly table: Locator
  readonly tableRows: Locator
  readonly paginationBar: Locator

  constructor(page: Page) {
    this.page = page
    this.heading = page.getByRole("heading", { name: "Offers" })
    this.newOfferButton = page.getByRole("button", { name: "New Offer" })
    this.table = page.getByRole("table")
    this.tableRows = this.table.getByRole("row")
    this.paginationBar = page.locator("[data-testid=pagination-bar]")
  }

  async goto() {
    await this.page.goto("/dashboard/offers")
    await expect(this.heading).toBeVisible()
  }

  async getRowByTitle(title: string): Promise<Locator> {
    return this.table.getByRole("row").filter({ hasText: title })
  }

  async clickNewOffer() {
    await this.newOfferButton.click()
    await expect(this.page.getByRole("dialog")).toBeVisible()
  }

  async clickEdit(title: string) {
    const row = await this.getRowByTitle(title)
    await row.getByRole("button").first().click()
    await expect(this.page.getByRole("dialog")).toBeVisible()
  }

  async clickDelete(title: string) {
    const row = await this.getRowByTitle(title)
    const buttons = row.getByRole("button")
    await buttons.nth(1).click()
  }

  async expectRowVisible(title: string) {
    const row = await this.getRowByTitle(title)
    await expect(row).toBeVisible()
  }

  async expectRowNotVisible(title: string) {
    const row = this.table.getByRole("row").filter({ hasText: title })
    await expect(row).toHaveCount(0)
  }
}

export class OfferDialog {
  readonly page: Page

  readonly dialog: Locator
  readonly titleInput: Locator
  readonly descriptionInput: Locator
  readonly originalPriceInput: Locator
  readonly offerPriceInput: Locator
  readonly startDateInput: Locator
  readonly endDateInput: Locator
  readonly restaurantSelect: Locator
  readonly cancelButton: Locator
  readonly submitButton: Locator

  constructor(page: Page) {
    this.page = page
    this.dialog = page.getByRole("dialog")
    this.titleInput = page.getByLabel("Title").first()
    this.descriptionInput = page.locator("#description")
    this.originalPriceInput = page.getByLabel("Original Price (LKR)")
    this.offerPriceInput = page.getByLabel("Offer Price (LKR)")
    this.startDateInput = page.getByLabel("Start Date")
    this.endDateInput = page.getByLabel("End Date")
    this.restaurantSelect = page.getByRole("combobox")
    this.cancelButton = page.getByRole("button", { name: "Cancel" })
    this.submitButton = page.getByRole("button", { name: /Create|Update/ })
  }

  async expectOpen() {
    await expect(this.dialog).toBeVisible()
  }

  async expectClosed() {
    await expect(this.dialog).not.toBeVisible()
  }

  async fillTitle(title: string) {
    await this.titleInput.fill(title)
  }

  async fillDescription(description: string) {
    await this.descriptionInput.fill(description)
  }

  async fillPrices(original: number, offer: number) {
    await this.originalPriceInput.fill(original.toString())
    await this.offerPriceInput.fill(offer.toString())
  }

  async fillDates(start: string, end: string) {
    await this.startDateInput.fill(start)
    await this.endDateInput.fill(end)
  }

  async selectRestaurant(name: string) {
    await this.restaurantSelect.click()
    await this.page.getByRole("option", { name }).click()
  }

  async clickSubmit() {
    await this.submitButton.click()
  }

  async clickCancel() {
    await this.cancelButton.click()
  }
}
