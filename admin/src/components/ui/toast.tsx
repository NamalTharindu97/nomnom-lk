"use client"

import { useEffect, useState, useCallback } from "react"
import * as ToastPrimitive from "@radix-ui/react-toast"
import { X } from "lucide-react"

interface ToastData {
  id: number
  message: string
  type: "error" | "success"
}

let toastId = 0
let addToastFn: ((data: Omit<ToastData, "id">) => void) | null = null

export function notify(message: string, type: "error" | "success" = "error") {
  addToastFn?.({ message, type })
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<ToastData[]>([])

  const addToast = useCallback((data: Omit<ToastData, "id">) => {
    const id = ++toastId
    setToasts((prev) => [...prev, { ...data, id }])
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 4000)
  }, [])

  useEffect(() => {
    addToastFn = addToast
    return () => { addToastFn = null }
  }, [addToast])

  function remove(id: number) {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }

  return (
    <ToastPrimitive.Provider swipeDirection="right">
      {children}
      {toasts.map((t) => (
        <ToastPrimitive.Root
          key={t.id}
          className={`fixed bottom-4 right-4 z-100 flex items-center gap-3 rounded-lg border px-4 py-3 shadow-lg ${
            t.type === "error"
              ? "border-destructive/30 bg-destructive/10 text-destructive"
              : "border-green-500/30 bg-green-500/10 text-green-600"
          }`}
          onOpenChange={(open) => { if (!open) remove(t.id) }}
        >
          <ToastPrimitive.Description className="text-sm font-medium">
            {t.message}
          </ToastPrimitive.Description>
          <ToastPrimitive.Close className="shrink-0 rounded-md p-1 opacity-60 hover:opacity-100">
            <X className="size-4" />
          </ToastPrimitive.Close>
        </ToastPrimitive.Root>
      ))}
      <ToastPrimitive.Viewport />
    </ToastPrimitive.Provider>
  )
}
