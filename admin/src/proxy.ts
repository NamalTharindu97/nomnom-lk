import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl

  if (!pathname.startsWith("/dashboard")) {
    return NextResponse.next()
  }

  const token = request.cookies.get("token")?.value
  const userStr = request.cookies.get("user")?.value

  if (!token) {
    const loginUrl = new URL("/login", request.url)
    return NextResponse.redirect(loginUrl)
  }

  if (!userStr) {
    const loginUrl = new URL("/login", request.url)
    return NextResponse.redirect(loginUrl)
  }

  try {
    const user = JSON.parse(userStr)
    if (user.role !== "admin" && user.role !== "restaurant_owner") {
      const loginUrl = new URL("/login?error=forbidden", request.url)
      return NextResponse.redirect(loginUrl)
    }
  } catch {
    const loginUrl = new URL("/login", request.url)
    return NextResponse.redirect(loginUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/dashboard/:path*"],
}
