import { test, expect } from "@playwright/test"
import { RestaurantsPage, RestaurantDialog } from "./pages/restaurants.page"

test.describe("Restaurant CRUD", () => {
  let listPage: RestaurantsPage

  test.beforeEach(async ({ page }) => {
    const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"
    const res = await page.request.post(`${apiBase}/auth/login`, {
      data: { email: "admin@nomnom.lk", password: "Admin@123" },
    })
    const { access_token, user } = await res.json()

    await page.goto("/login")
    await page.evaluate(
      ({ token, userData }) => {
        localStorage.setItem("token", token)
        localStorage.setItem("user", JSON.stringify(userData))
      },
      { token: access_token, userData: user }
    )

    listPage = new RestaurantsPage(page)
    await listPage.goto()
  })

  test("should create a new restaurant with all fields", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    await listPage.clickNewRestaurant()
    const dialog = new RestaurantDialog(page)
    await dialog.expectOpen()
    await expect(dialog.dialog).toContainText("New Restaurant")

    await dialog.fillName(`E2E Create ${uniqueId}`)
    await dialog.fillSlug(`e2e-create-${uniqueId}`)
    await dialog.fillAddress("123 Test Street, Colombo 05")
    await dialog.fillPhone("+94 11 234 5678")
    await dialog.fillCuisineTags("E2E, Playwright")
    await dialog.fillDescription("A restaurant created during automated E2E testing.")
    await dialog.fillNameSi("පරීක්ෂණ අවන්හල")
    await dialog.fillDescriptionSi("ස්වයංක්‍රීය පරීක්ෂණයක් අතරතුර නිර්මාණය කරන ලද අවන්හලක්.")
    await dialog.fillNameTa("சோதனை உணவகம்")
    await dialog.fillDescriptionTa("தானியங்கி E2E சோதனையின் போது உருவாக்கப்பட்ட உணவகம்.")

    await dialog.clickSubmit()
    await dialog.expectClosed()

    await expect(page.getByText("Restaurant created", { exact: true })).toBeVisible()
    await listPage.expectRowVisible(`E2E Create ${uniqueId}`)
  })

  test("should show validation error when name and slug are empty", async ({ page }) => {
    await listPage.clickNewRestaurant()
    const dialog = new RestaurantDialog(page)
    await dialog.expectOpen()

    await dialog.clickSubmit()
    await expect(page.getByText("Name and slug are required", { exact: true })).toBeVisible()
    await dialog.expectOpen()
  })

  test("should edit an existing restaurant", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    const originalName = `E2E Edit Orig ${uniqueId}`
    const updatedName = `E2E Edit Updated ${uniqueId}`

    await listPage.clickNewRestaurant()
    let dialog = new RestaurantDialog(page)
    await dialog.expectOpen()
    await dialog.fillName(originalName)
    await dialog.fillSlug(`e2e-edit-${uniqueId}`)
    await dialog.fillAddress("123 Test Street")
    await dialog.clickSubmit()
    await dialog.expectClosed()
    await expect(page.getByText("Restaurant created", { exact: true })).toBeVisible()

    await listPage.clickEdit(originalName)
    dialog = new RestaurantDialog(page)
    await dialog.expectOpen()
    await expect(dialog.dialog).toContainText("Edit Restaurant")

    await dialog.nameInput.clear()
    await dialog.fillName(updatedName)
    await dialog.clickSubmit()
    await dialog.expectClosed()

    await expect(page.getByText("Restaurant updated", { exact: true })).toBeVisible()
    await listPage.expectRowVisible(updatedName)
    await listPage.expectRowNotVisible(originalName)
  })

  test("should delete a restaurant", async ({ page }) => {
    const uniqueId = Date.now().toString(36)
    const name = `E2E Delete ${uniqueId}`

    await listPage.clickNewRestaurant()
    const dialog = new RestaurantDialog(page)
    await dialog.expectOpen()
    await dialog.fillName(name)
    await dialog.fillSlug(`e2e-delete-${uniqueId}`)
    await dialog.fillAddress("123 Test Street")
    await dialog.clickSubmit()
    await dialog.expectClosed()
    await expect(page.getByText("Restaurant created", { exact: true })).toBeVisible()

    page.on("dialog", async (dialog) => {
      expect(dialog.message()).toContain("delete")
      await dialog.accept()
    })

    await listPage.clickDelete(name)
    await expect(page.getByText("Restaurant deleted", { exact: true })).toBeVisible()
    await listPage.expectRowNotVisible(name)
  })
})
