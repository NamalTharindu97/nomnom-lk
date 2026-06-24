<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# NomNom LK Admin Dashboard

## Goal
- An admin dashboard for managing restaurants, offers, users, and push notifications for the NomNom LK app.

## Stack
- Next.js 16 + Tailwind v4 + shadcn/ui + recharts + lucide-react.

## Key Patterns
- **Theme:** Custom `ThemeProvider` (not `next-themes`) with light/dark/system toggle stored in `localStorage` key `nomnom-theme`. Uses `@variant dark` in Tailwind.
- **Auth:** JWT token in `localStorage` under key `token`. `AuthProvider` context with `login()`, `logout()`, `user`, `token`. Redirects to `/login` if no token.
- **API client:** `src/lib/api.ts` — thin fetch wrapper that injects `Bearer` token from localStorage. Supports GET/POST/PUT/DELETE.
- **Brand palette:** Curry orange primary (`oklch(0.65 0.16 70)`), deep charcoal sidebar (`oklch(0.15)` light / `oklch(0.08)` dark).
- **Offers CRUD:** Modal dialog (`_offer-dialog.tsx`) reused for both Create and Edit. Restaurant dropdown loads from `/restaurants` endpoint.

## State
- All screens built: Login, Dashboard (stats + chart), Restaurants, Offers (CRUD), Users, Notifications.
- Backend `GET /users` endpoint added at `/api/v1/users` (admin-only).
- Offer images are URL strings (upload support not yet added).

## Default Credentials
- `admin@nomnom.lk` / `Admin@123`
