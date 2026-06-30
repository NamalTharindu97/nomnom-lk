import { test, expect } from "@playwright/test"
import { OffersPage, OfferDialog } from "./pages/offers.page"

test.describe("Offers CRUD", () => {
  let listPage: OffersPage

  test.beforeEach(async ({ page }) => {
    listPage = new OffersPage(page)
    await listPage.goto()
  })

  test("should show the offers table", async () => {
    await expect(listPage.table).toBeVisible()
    await expect(listPage.newOfferButton).toBeVisible()
  })

  test("should open and close the new offer dialog", async ({ page }) => {
    await listPage.clickNewOffer()
    const dialog = new OfferDialog(page)
    await dialog.expectOpen()

    await dialog.clickCancel()
    await dialog.expectClosed()
  })

  test("should show validation errors when required fields are empty", async ({ page }) => {
    await listPage.clickNewOffer()
    const dialog = new OfferDialog(page)

    await dialog.clickSubmit()
    await expect(page.getByText("Title is required")).toBeVisible()
    await expect(page.getByText("Description is required")).toBeVisible()
    await expect(page.getByText("Restaurant is required")).toBeVisible()
    await dialog.expectOpen()
  })

  test("should create a new offer", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)

    const fmtDate = (d: Date) => d.toISOString().slice(0, 10)

    await listPage.clickNewOffer()
    const dialog = new OfferDialog(page)
    await dialog.expectOpen()

    await dialog.fillTitle(`E2E Offer ${uniqueId}`)
    await dialog.fillDescription("Created during automated E2E testing.")
    await dialog.fillPrices(1500, 990)
    await dialog.fillDates(fmtDate(tomorrow), fmtDate(nextWeek))
    await dialog.selectRestaurant("Kottu House")

    await dialog.clickSubmit()
    await dialog.expectClosed()

    await expect(page.getByText("Offer created", { exact: true })).toBeVisible()
    await listPage.expectRowVisible(`E2E Offer ${uniqueId}`)
  })

  test("should edit an existing offer", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    const originalTitle = `E2E Edit Orig ${uniqueId}`
    const updatedTitle = `E2E Edit Updated ${uniqueId}`
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    const fmtDate = (d: Date) => d.toISOString().slice(0, 10)

    await listPage.clickNewOffer()
    let dialog = new OfferDialog(page)
    await dialog.expectOpen()
    await dialog.fillTitle(originalTitle)
    await dialog.fillDescription("Original description")
    await dialog.fillPrices(1000, 700)
    await dialog.fillDates(fmtDate(tomorrow), fmtDate(nextWeek))
    await dialog.selectRestaurant("Kottu House")
    await dialog.clickSubmit()
    await dialog.expectClosed()
    await expect(page.getByText("Offer created", { exact: true })).toBeVisible()

    await listPage.clickEdit(originalTitle)
    dialog = new OfferDialog(page)
    await dialog.expectOpen()
    await expect(dialog.dialog).toContainText("Edit Offer")

    await dialog.titleInput.clear()
    await dialog.fillTitle(updatedTitle)
    await dialog.clickSubmit()
    await dialog.expectClosed()

    await expect(page.getByText("Offer updated", { exact: true })).toBeVisible()
    await listPage.expectRowVisible(updatedTitle)
    await listPage.expectRowNotVisible(originalTitle)
  })

  test("should delete an offer", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    const title = `E2E Delete ${uniqueId}`
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    const fmtDate = (d: Date) => d.toISOString().slice(0, 10)

    await listPage.clickNewOffer()
    const dialog = new OfferDialog(page)
    await dialog.expectOpen()
    await dialog.fillTitle(title)
    await dialog.fillDescription("To be deleted")
    await dialog.fillPrices(800, 500)
    await dialog.fillDates(fmtDate(tomorrow), fmtDate(nextWeek))
    await dialog.selectRestaurant("Kottu House")
    await dialog.clickSubmit()
    await dialog.expectClosed()
    await expect(page.getByText("Offer created", { exact: true })).toBeVisible()

    page.on("dialog", async (dialog) => {
      expect(dialog.message()).toContain("delete")
      await dialog.accept()
    })

    await listPage.clickDelete(title)
    await expect(page.getByText("Offer deleted", { exact: true })).toBeVisible()
    await listPage.expectRowNotVisible(title)
  })
})
