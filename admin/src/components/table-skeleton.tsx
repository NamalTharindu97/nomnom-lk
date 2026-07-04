import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Skeleton } from "@/components/ui/skeleton"

interface TableSkeletonProps {
  rows?: number
  columns: number
}

export function TableSkeleton({ rows = 5, columns }: TableSkeletonProps) {
  return (
    <TableBody>
      {Array.from({ length: rows }, (_, i) => (
        <TableRow key={i}>
          {Array.from({ length: columns }, (_, j) => (
            <TableCell key={j}>
              <Skeleton className="h-4 w-full" />
            </TableCell>
          ))}
        </TableRow>
      ))}
    </TableBody>
  )
}
