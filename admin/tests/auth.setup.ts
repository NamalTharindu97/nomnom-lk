import { expect, test as setup } from "@playwright/test"

setup("authenticate as admin", async ({ page }) => {
  const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"
  const res = await page.request.post(`${apiBase}/auth/login`, {
    data: { email: "admin@nomnom.lk", password: "Admin@123" },
  })
  expect(res.status()).toBe(200)
  const { access_token, user } = await res.json()

  await page.goto("/login")
  await page.evaluate(
    ({ token, userData }) => {
      localStorage.setItem("token", token)
      localStorage.setItem("user", JSON.stringify(userData))
    },
    { token: access_token, userData: user }
  )

  await page.goto("/dashboard")
  await page.context().storageState({ path: ".auth/user.json" })
})
