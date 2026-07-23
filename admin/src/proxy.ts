import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl

  if (!pathname.startsWith("/dashboard")) {
    return NextResponse.next()
  }

	const session = request.cookies.get("nomnom_access")?.value

	if (!session) {
		const loginUrl = new URL("/login", request.url)
		return NextResponse.redirect(loginUrl)
	}

	return NextResponse.next()
}

export const config = {
  matcher: ["/dashboard/:path*"],
}
