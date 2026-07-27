import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

const API_TARGET = process.env.API_PROXY_TARGET || "http://localhost:8080"

export async function middleware(request: NextRequest) {
  const { pathname, search } = request.nextUrl

  if (pathname.startsWith("/api/v1/")) {
    const targetUrl = `${API_TARGET}${pathname}${search}`

    let body: BodyInit | null | undefined
    if (request.body) {
      body = await request.clone().arrayBuffer()
    }

    const headers = new Headers()
    request.headers.forEach((value, key) => {
      if (!["host", "connection"].includes(key.toLowerCase())) {
        headers.set(key, value)
      }
    })

    try {
      const res = await fetch(targetUrl, {
        method: request.method,
        headers,
        body,
        redirect: "manual",
      })

      const responseHeaders = new Headers(res.headers)
      responseHeaders.delete("content-encoding")
      responseHeaders.delete("transfer-encoding")

      return new NextResponse(res.body, {
        status: res.status,
        statusText: res.statusText,
        headers: responseHeaders,
      })
    } catch {
      return NextResponse.json(
        { error: { code: "PROXY_ERROR", message: "Backend unavailable" } },
        { status: 502 }
      )
    }
  }

  if (pathname.startsWith("/dashboard")) {
    const session = request.cookies.get("nomnom_access")?.value
    if (!session) {
      return NextResponse.redirect(new URL("/login", request.url))
    }
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/api/v1/:path*", "/dashboard/:path*"],
}
