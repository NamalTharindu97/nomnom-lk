import { Button } from "@/components/ui/button"
import { ChevronLeft, ChevronRight } from "lucide-react"

interface PaginationBarProps {
  page: number
  perPage: number
  total: number
  onPageChange: (page: number) => void
}

export function PaginationBar({ page, perPage, total, onPageChange }: PaginationBarProps) {
  const totalPages = Math.max(1, Math.ceil(total / perPage))

  if (total <= perPage) return null

  return (
    <div className="flex items-center justify-between pt-4">
      <p className="text-sm text-muted-foreground">
        Showing {(page - 1) * perPage + 1}–{Math.min(page * perPage, total)} of {total}
      </p>
      <div className="flex items-center gap-1">
        <Button
          variant="outline"
          size="icon"
          disabled={page <= 1}
          onClick={() => onPageChange(page - 1)}
        >
          <ChevronLeft className="size-4" />
        </Button>
        {Array.from({ length: totalPages }, (_, i) => i + 1)
          .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
          .map((p, idx, arr) => {
            const showEllipsis = idx > 0 && p - arr[idx - 1] > 1
            return (
              <span key={p} className="flex items-center">
                {showEllipsis && <span className="px-1 text-muted-foreground">...</span>}
                <Button
                  variant={p === page ? "default" : "outline"}
                  size="icon"
                  className="size-8 text-xs"
                  onClick={() => onPageChange(p)}
                >
                  {p}
                </Button>
              </span>
            )
          })}
        <Button
          variant="outline"
          size="icon"
          disabled={page >= totalPages}
          onClick={() => onPageChange(page + 1)}
        >
          <ChevronRight className="size-4" />
        </Button>
      </div>
    </div>
  )
}
