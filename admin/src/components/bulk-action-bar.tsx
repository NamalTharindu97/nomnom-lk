"use client"

import { Button } from "@/components/ui/button"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Trash2, CheckCheck } from "lucide-react"

interface BulkAction {
  label: string
  variant?: "default" | "destructive" | "outline" | "secondary" | "ghost"
  onClick: () => void
}

interface BulkActionBarProps {
  count: number
  actions: BulkAction[]
  deleteAction?: () => void
  deleteLabel?: string
  onClear: () => void
}

export function BulkActionBar({ count, actions, deleteAction, deleteLabel = "Delete", onClear }: BulkActionBarProps) {
  return (
    <div className="flex items-center gap-2 pt-2 border-t mt-2">
      <span className="text-sm text-muted-foreground mr-2">
        <CheckCheck className="inline size-4 mr-1" />
        {count} selected
      </span>
      {actions.map((a, i) => (
        <Button key={i} size="sm" variant={a.variant || "default"} onClick={a.onClick}>
          {a.label}
        </Button>
      ))}
      {deleteAction && (
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <Button size="sm" variant="outline" className="text-destructive">
              <Trash2 className="size-4 mr-1" />
              {deleteLabel}
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{deleteLabel} Items</AlertDialogTitle>
              <AlertDialogDescription>
                Are you sure you want to delete {count} item(s)? This action cannot be undone.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancel</AlertDialogCancel>
              <AlertDialogAction onClick={deleteAction} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                {deleteLabel}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      )}
      <Button size="sm" variant="ghost" onClick={onClear}>Clear</Button>
    </div>
  )
}
