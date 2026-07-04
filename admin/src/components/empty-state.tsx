import { cn } from "@/lib/utils"
import { TableCell, TableRow } from "@/components/ui/table"
import { PackageOpen } from "lucide-react"

interface EmptyStateProps {
  icon?: React.ReactNode
  title?: string
  description?: string
  action?: React.ReactNode
  className?: string
}

export function EmptyState({
  icon,
  title = "Nothing found",
  description = "No items to display.",
  action,
  className,
}: EmptyStateProps) {
  return (
    <TableRow>
      <TableCell colSpan={99} className={cn("text-center py-12", className)}>
        <div className="flex flex-col items-center gap-3">
          {icon ?? <PackageOpen className="size-10 text-muted-foreground/50" />}
          <div>
            <p className="font-medium text-muted-foreground">{title}</p>
            <p className="text-sm text-muted-foreground/60">{description}</p>
          </div>
          {action && <div className="mt-1">{action}</div>}
        </div>
      </TableCell>
    </TableRow>
  )
}
