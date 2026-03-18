import Link from "next/link"
import { createAdminClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  LostFoundDetailSheet,
  LostFoundStatusBadge,
  ReportTypeBadge,
} from "./lost-found-detail-sheet"
import { LostFoundFormSheet } from "./lost-found-form-sheet"
import type { LostFoundReport } from "@/lib/supabase/types"

const STATUS_FILTERS = [
  { value: "all", label: "All" },
  { value: "open", label: "Open" },
  { value: "under_review", label: "Under Review" },
  { value: "resolved", label: "Resolved" },
  { value: "closed", label: "Closed" },
]

const TYPE_FILTERS = [
  { value: "all", label: "All Types" },
  { value: "lost", label: "Lost" },
  { value: "found", label: "Found" },
]

export default async function LostAndFoundPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; type?: string }>
}) {
  const { status, type } = await searchParams
  const activeStatus = status ?? "all"
  const activeType = type ?? "all"

  const supabase = await createAdminClient()

  let query = supabase
    .from("lost_found_reports")
    .select("*")
    .order("created_at", { ascending: false })

  if (activeStatus !== "all") query = query.eq("status", activeStatus)
  if (activeType !== "all") query = query.eq("report_type", activeType)

  const { data: reports = [] } = await query
  const typedReports = (reports ?? []) as LostFoundReport[]

  // Counts for badges
  const { data: allReports } = await supabase
    .from("lost_found_reports")
    .select("status, report_type")

  const statusCounts = (allReports ?? []).reduce<Record<string, number>>((acc, r) => {
    acc[r.status] = (acc[r.status] ?? 0) + 1
    return acc
  }, {})

  const typeCounts = (allReports ?? []).reduce<Record<string, number>>((acc, r) => {
    if (r.report_type) acc[r.report_type] = (acc[r.report_type] ?? 0) + 1
    return acc
  }, {})

  function buildHref(s: string, t: string) {
    const params = new URLSearchParams()
    if (s !== "all") params.set("status", s)
    if (t !== "all") params.set("type", t)
    const qs = params.toString()
    return `/admin/lost-and-found${qs ? `?${qs}` : ""}`
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-foreground tracking-tight">Lost and Found</h1>
          <p className="text-sm text-muted-foreground mt-1">
            View and manage lost and found submissions from the mobile app.
          </p>
        </div>
        <LostFoundFormSheet />
      </div>

      {/* Status filters */}
      <div className="flex flex-wrap gap-2">
        {STATUS_FILTERS.map((f) => {
          const isActive = activeStatus === f.value
          const count = f.value === "all" ? (allReports ?? []).length : (statusCounts[f.value] ?? 0)
          return (
            <Link
              key={f.value}
              href={buildHref(f.value, activeType)}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                isActive
                  ? "border-[#006633] bg-[#006633] text-white"
                  : "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
              }`}
            >
              {f.label}
              <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${isActive ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
                {count}
              </span>
            </Link>
          )
        })}

        <div className="ml-2 h-6 w-px bg-border self-center" />

        {/* Type filters */}
        {TYPE_FILTERS.map((f) => {
          const isActive = activeType === f.value
          const count = f.value === "all" ? (allReports ?? []).length : (typeCounts[f.value] ?? 0)
          return (
            <Link
              key={f.value}
              href={buildHref(activeStatus, f.value)}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                isActive
                  ? "border-[#006633] bg-[#006633] text-white"
                  : "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
              }`}
            >
              {f.label}
              <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${isActive ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
                {count}
              </span>
            </Link>
          )
        })}
      </div>

      <Card className="bg-white border shadow-sm">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base font-semibold">Reports</CardTitle>
              <CardDescription className="text-xs mt-0.5">
                {typedReports.length} {typedReports.length === 1 ? "item" : "items"} found
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {typedReports.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <p className="text-sm font-medium text-foreground">No reports found</p>
              <p className="text-xs text-muted-foreground mt-1">
                Lost and found submissions from the mobile app will appear here.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Item</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Location</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Images</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="pr-6 text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {typedReports.map((report) => (
                  <TableRow key={report.id}>
                    <TableCell className="pl-6 font-medium max-w-[160px] truncate">
                      {report.item_name ?? "Unnamed"}
                    </TableCell>
                    <TableCell>
                      <ReportTypeBadge type={report.report_type} />
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {report.location ?? "—"}
                    </TableCell>
                    <TableCell>
                      <LostFoundStatusBadge status={report.status} />
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary" className="text-xs">
                        {report.image_urls?.length ?? 0} photo{(report.image_urls?.length ?? 0) !== 1 ? "s" : ""}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-xs">
                      {new Date(report.created_at).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </TableCell>
                    <TableCell className="pr-6 text-right">
                      <LostFoundDetailSheet report={report} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
