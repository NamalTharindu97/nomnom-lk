import { expect, test as setup } from "@playwright/test"

setup("authenticate as admin", async ({ page }) => {
  await page.goto("/login")
  const res = await page.request.post("/api/v1/auth/browser/login", {
    data: { email: "admin@nomnom.lk", password: "Admin@123" },
  })
  expect(res.status()).toBe(200)

  await page.goto("/dashboard")
  await page.context().storageState({ path: ".auth/user.json" })
})
