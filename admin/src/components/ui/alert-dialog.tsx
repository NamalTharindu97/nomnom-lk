"use client"

import * as AlertDialogPrimitive from "@radix-ui/react-alert-dialog"
import { cn } from "@/lib/utils"
import { buttonVariants } from "@/components/ui/button"

export function AlertDialog({ children, ...props }: AlertDialogPrimitive.AlertDialogProps) {
  return <AlertDialogPrimitive.Root {...props}>{children}</AlertDialogPrimitive.Root>
}

export function AlertDialogTrigger({ children, ...props }: AlertDialogPrimitive.AlertDialogTriggerProps) {
  return <AlertDialogPrimitive.Trigger {...props}>{children}</AlertDialogPrimitive.Trigger>
}

export function AlertDialogPortal({ children, ...props }: AlertDialogPrimitive.AlertDialogPortalProps) {
  return <AlertDialogPrimitive.Portal {...props}>{children}</AlertDialogPrimitive.Portal>
}

export function AlertDialogOverlay({ className, ...props }: AlertDialogPrimitive.AlertDialogOverlayProps) {
  return (
    <AlertDialogPrimitive.Overlay
      className={cn("alert-overlay fixed inset-0 z-50 bg-black/50", className)}
      {...props}
    />
  )
}

export function AlertDialogContent({ className, children, ...props }: AlertDialogPrimitive.AlertDialogContentProps) {
  return (
    <AlertDialogPortal>
      <AlertDialogOverlay />
      <AlertDialogPrimitive.Content
        className={cn(
          "alert-content fixed left-1/2 top-1/2 z-50 w-full max-w-md -translate-x-1/2 -translate-y-1/2 rounded-lg border bg-background p-6 shadow-lg",
          className
        )}
        {...props}
      >
        {children}
      </AlertDialogPrimitive.Content>
    </AlertDialogPortal>
  )
}

export function AlertDialogHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("flex flex-col gap-1.5 text-center sm:text-left", className)} {...props} />
}

export function AlertDialogFooter({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("flex flex-col-reverse sm:flex-row sm:justify-end sm:gap-2", className)} {...props} />
}

export function AlertDialogTitle({ className, ...props }: AlertDialogPrimitive.AlertDialogTitleProps) {
  return (
    <AlertDialogPrimitive.Title className={cn("text-lg font-semibold", className)} {...props} />
  )
}

export function AlertDialogDescription({ className, ...props }: AlertDialogPrimitive.AlertDialogDescriptionProps) {
  return (
    <AlertDialogPrimitive.Description className={cn("text-sm text-muted-foreground", className)} {...props} />
  )
}

export function AlertDialogAction({ className, ...props }: AlertDialogPrimitive.AlertDialogActionProps) {
  return <AlertDialogPrimitive.Action className={cn(buttonVariants(), className)} {...props} />
}

export function AlertDialogCancel({ className, ...props }: AlertDialogPrimitive.AlertDialogCancelProps) {
  return (
    <AlertDialogPrimitive.Cancel className={cn(buttonVariants({ variant: "outline" }), "mt-2 sm:mt-0", className)} {...props} />
  )
}
