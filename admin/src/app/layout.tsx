import type { Metadata } from "next"
import localFont from "next/font/local"
import "./globals.css"
import { Providers } from "./providers"

const geistSans = localFont({
  src: [
    { path: "../../public/fonts/Geist-Regular.woff2", weight: "400", style: "normal" },
    { path: "../../public/fonts/Geist-Medium.woff2", weight: "500", style: "normal" },
    { path: "../../public/fonts/Geist-Bold.woff2", weight: "700", style: "normal" },
  ],
  variable: "--font-geist-sans",
})

const geistMono = localFont({
  src: [
    { path: "../../public/fonts/GeistMono-Regular.woff2", weight: "400", style: "normal" },
    { path: "../../public/fonts/GeistMono-Medium.woff2", weight: "500", style: "normal" },
    { path: "../../public/fonts/GeistMono-Bold.woff2", weight: "700", style: "normal" },
  ],
  variable: "--font-geist-mono",
})

export const metadata: Metadata = {
  title: "NomNom LK Admin",
  description: "Admin dashboard for NomNom LK food offers",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="min-h-full">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
