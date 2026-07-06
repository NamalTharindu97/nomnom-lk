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
    // Delete E2E coupons
    const couponRes = await fetch(`${API_BASE}/admin/coupons`, {
      headers: authHeaders,
    })
    if (couponRes.ok) {
      const { data: coupons } = await couponRes.json()
      for (const c of coupons) {
        if (c.code?.startsWith("E2E")) {
          await fetch(`${API_BASE}/admin/coupons/${c.id}`, {
            method: "DELETE",
            headers: authHeaders,
          })
        }
      }
      if (coupons.length > 0) console.log(`[teardown] Deleted E2E coupons`)
    }

    // Delete E2E categories
    const catRes = await fetch(`${API_BASE}/admin/categories`, {
      headers: authHeaders,
    })
    if (catRes.ok) {
      const { data: categories } = await catRes.json()
      for (const c of categories) {
        if (c.name?.startsWith("E2E")) {
          await fetch(`${API_BASE}/admin/categories/${c.id}`, {
            method: "DELETE",
            headers: authHeaders,
          })
        }
      }
      if (categories.length > 0) console.log(`[teardown] Deleted E2E categories`)
    }

    // Delete E2E users
    const userRes = await fetch(`${API_BASE}/users?per_page=100`, {
      headers: authHeaders,
    })
    if (userRes.ok) {
      const { data: users } = await userRes.json()
      for (const u of users) {
        if (u.email?.toLowerCase().startsWith("e2e_")) {
          await fetch(`${API_BASE}/users/${u.id}`, {
            method: "DELETE",
            headers: authHeaders,
          })
        }
      }
      const e2eUsers = users.filter((u: any) => u.email?.toLowerCase().startsWith("e2e_"))
      if (e2eUsers.length > 0) console.log(`[teardown] Deleted ${e2eUsers.length} E2E users`)
    }

    // Delete E2E notification templates
    const tplRes = await fetch(`${API_BASE}/admin/notification-templates`, {
      headers: authHeaders,
    })
    if (tplRes.ok) {
      const { data: templates } = await tplRes.json()
      for (const t of templates) {
        if (t.name?.startsWith("E2E")) {
          await fetch(`${API_BASE}/admin/notification-templates/${t.id}`, {
            method: "DELETE",
            headers: authHeaders,
          })
        }
      }
      if (templates.length > 0) console.log(`[teardown] Deleted E2E templates`)
    }
  } catch (err) {
    console.warn("[teardown] Cleanup error:", err)
  }
}

export default globalTeardown
