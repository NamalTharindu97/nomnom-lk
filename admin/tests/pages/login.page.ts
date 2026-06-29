import { Page, Locator, expect } from "@playwright/test"

export class LoginPage {
  readonly page: Page

  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly signInButton: Locator
  readonly heading: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.getByLabel("Email")
    this.passwordInput = page.getByLabel("Password")
    this.signInButton = page.getByRole("button", { name: "Sign in" })
    this.heading = page.getByRole("heading", { name: "Sign in" })
  }

  async goto() {
    await this.page.goto("/login")
    await expect(this.heading).toBeVisible()
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.signInButton.click()
  }

  async expectRedirectToDashboard() {
    await this.page.waitForURL(/\/dashboard|\//)
    await expect(this.page.getByRole("heading", { name: "Dashboard" })).toBeVisible()
  }
}
