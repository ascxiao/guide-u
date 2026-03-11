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
import { IncidentDetailSheet, StatusBadge } from "./incident-detail-sheet"
import type { IncidentReport, IncidentStatus } from "@/lib/supabase/types"

const STATUS_FILTERS: { value: string; label: string }[] = [
  { value: "all", label: "All" },
  { value: "pending", label: "Pending" },
  { value: "under_review", label: "Under Review" },
  { value: "resolved", label: "Resolved" },
  { value: "closed", label: "Closed" },
]

export default async function IncidentReportPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>
}) {
  const { status } = await searchParams
  const activeFilter = status ?? "all"

  const supabase = await createAdminClient()

  let query = supabase
    .from("incident_reports")
    .select("*")
    .order("created_at", { ascending: false })

  if (activeFilter !== "all") {
    query = query.eq("status", activeFilter)
  }

  const { data: reports = [] } = await query
  const typedReports = (reports ?? []) as IncidentReport[]

  // Count by status for the header badges
  const { data: counts } = await supabase
    .from("incident_reports")
    .select("status")

  const statusCounts = (counts ?? []).reduce<Record<string, number>>((acc, r) => {
    acc[r.status] = (acc[r.status] ?? 0) + 1
    return acc
  }, {})

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground tracking-tight">Incident Reports</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Review and manage submitted incident reports from the mobile app.
        </p>
      </div>

      {/* Status count pills */}
      <div className="flex flex-wrap gap-2">
        {STATUS_FILTERS.map((f) => {
          const isActive = activeFilter === f.value
          const count =
            f.value === "all"
              ? (counts ?? []).length
              : (statusCounts[f.value] ?? 0)
          return (
            <Link
              key={f.value}
              href={f.value === "all" ? "/admin/incident-report" : `/admin/incident-report?status=${f.value}`}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                isActive
                  ? "border-[#006633] bg-[#006633] text-white"
                  : "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
              }`}
            >
              {f.label}
              <span
                className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${
                  isActive ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"
                }`}
              >
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
                {typedReports.length} {typedReports.length === 1 ? "report" : "reports"} found
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {typedReports.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <p className="text-sm font-medium text-foreground">No reports found</p>
              <p className="text-xs text-muted-foreground mt-1">
                {activeFilter !== "all"
                  ? `No reports with status "${activeFilter}".`
                  : "Incident reports submitted from the mobile app will appear here."}
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Title</TableHead>
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
                    <TableCell className="pl-6 font-medium max-w-[200px] truncate">
                      {report.title ?? "Untitled"}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {report.location ?? "—"}
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={report.status} />
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
                      <IncidentDetailSheet report={report} />
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
