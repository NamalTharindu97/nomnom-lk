import type { FullConfig } from "@playwright/test"

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1"

async function globalTeardown(config: FullConfig) {
  try {
    const loginRes = await fetch(`${API_BASE}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "admin@nomnom.lk", password: "Admin@123" }),
    })
    if (!loginRes.ok) {
      console.warn("[teardown] Login failed, skipping cleanup")
      return
    }
    const { access_token } = await loginRes.json()

    const authHeaders = {
      "Content-Type": "application/json",
      Authorization: `Bearer ${access_token}`,
    }

    // Delete E2E offers
    const offerRes = await fetch(`${API_BASE}/offers?q=E2E&per_page=100&status=all`, {
      headers: authHeaders,
    })
    if (offerRes.ok) {
      const { data: offers } = await offerRes.json()
      for (const offer of offers) {
        await fetch(`${API_BASE}/offers/${offer.id}`, {
          method: "DELETE",
          headers: authHeaders,
        })
      }
      if (offers.length > 0) console.log(`[teardown] Deleted ${offers.length} E2E offers`)
    }

    // Delete E2E restaurants
    const restRes = await fetch(`${API_BASE}/restaurants?q=E2E&per_page=100&status=all`, {
      headers: authHeaders,
    })
    if (restRes.ok) {
      const { data: restaurants } = await restRes.json()
      for (const restaurant of restaurants) {
        await fetch(`${API_BASE}/restaurants/${restaurant.id}`, {
          method: "DELETE",
          headers: authHeaders,
        })
      }
      if (restaurants.length > 0) console.log(`[teardown] Deleted ${restaurants.length} E2E restaurants`)
    }
  } catch (err) {
    console.warn("[teardown] Cleanup error:", err)
  }
}

export default globalTeardown
