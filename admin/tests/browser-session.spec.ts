import { expect, test } from "@playwright/test"

test.describe("Browser session security", () => {
  test.beforeEach(async ({ page, context }) => {
    await context.clearCookies()
    await page.goto("/login")
  })

  test("login keeps tokens out of JSON and browser storage", async ({ page, context }) => {
    const response = await page.request.post("/api/v1/auth/browser/login", {
      data: { email: "admin@nomnom.lk", password: "Admin@123" },
    })
    expect(response.status()).toBe(200)
    const body = await response.json()
    expect(body.access_token).toBeUndefined()
    expect(body.refresh_token).toBeUndefined()

    const cookies = await context.cookies()
    const access = cookies.find((cookie) => cookie.name === "nomnom_access")
    const refresh = cookies.find((cookie) => cookie.name === "nomnom_refresh")
    const csrf = cookies.find((cookie) => cookie.name === "nomnom_csrf")
    expect(access).toMatchObject({ httpOnly: true, sameSite: "Lax", path: "/" })
    expect(refresh).toMatchObject({ httpOnly: true, sameSite: "Lax", path: "/api/v1/auth/browser" })
    expect(csrf).toMatchObject({ httpOnly: false, sameSite: "Lax", path: "/" })
    await expect(page.evaluate(() => localStorage.getItem("token"))).resolves.toBeNull()
    await expect(page.evaluate(() => localStorage.getItem("user"))).resolves.toBeNull()
  })

  test("cookie-authenticated mutations require CSRF proof", async ({ page }) => {
    const login = await page.request.post("/api/v1/auth/browser/login", {
      data: { email: "admin@nomnom.lk", password: "Admin@123" },
    })
    expect(login.status()).toBe(200)

    const response = await page.request.post("/api/v1/auth/browser/logout")
    expect(response.status()).toBe(403)
    expect((await response.json()).error.code).toBe("CSRF_VALIDATION_FAILED")
  })

  test("logout revokes the session and clears all browser cookies", async ({ page, context }) => {
    const login = await page.request.post("/api/v1/auth/browser/login", {
      data: { email: "admin@nomnom.lk", password: "Admin@123" },
    })
    expect(login.status()).toBe(200)
    const csrf = (await context.cookies()).find((cookie) => cookie.name === "nomnom_csrf")
    expect(csrf).toBeDefined()

    const response = await page.request.post("/api/v1/auth/browser/logout", {
      headers: { "X-CSRF-Token": csrf!.value },
    })
    expect(response.status()).toBe(204)
    const names = (await context.cookies()).map((cookie) => cookie.name)
    expect(names).not.toContain("nomnom_access")
    expect(names).not.toContain("nomnom_refresh")
    expect(names).not.toContain("nomnom_csrf")
  })
})
