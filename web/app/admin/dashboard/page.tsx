import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { HugeiconsIcon } from "@hugeicons/react"
import {
  People,
  Book01Icon,
  Alert02Icon,
  Archive01Icon,
  Clock01Icon,
} from "@hugeicons/core-free-icons"
import { createAdminClient } from "@/lib/supabase/server"

const quickActions = [
  { label: "Add Handbook Entry", href: "/admin/handbook", icon: Book01Icon, badge: "Handbook" },
  { label: "Review Incident Reports", href: "/admin/incident-report", icon: Alert02Icon, badge: "Incidents" },
  { label: "Manage Lost & Found", href: "/admin/lost-and-found", icon: Archive01Icon, badge: "Lost & Found" },
]

const systemServices = [
  { name: "Database", status: "Operational" },
  { name: "API Server", status: "Operational" },
  { name: "Auth Service", status: "Operational" },
]

export default async function DashboardPage() {
  const supabase = await createAdminClient()

  const [
    { count: articleCount },
    { count: incidentCount },
    { count: lostFoundCount },
    { data: usersData },
  ] = await Promise.all([
    supabase.from("articles").select("*", { count: "exact", head: true }),
    supabase.from("incident_reports").select("*", { count: "exact", head: true }).in("status", ["pending", "under_review"]),
    supabase.from("lost_found_reports").select("*", { count: "exact", head: true }).in("status", ["open", "under_review"]),
    supabase.auth.admin.listUsers({ perPage: 1 }),
  ])

  // `total` exists on the paginated response when pagination is supported
  const userCount = (usersData as { total?: number } | null)?.total ?? (usersData?.users?.length ?? 0)

  const stats = [
    {
      title: "Total Users",
      value: String(userCount),
      description: "Registered accounts",
      icon: People,
    },
    {
      title: "Handbook Entries",
      value: String(articleCount ?? 0),
      description: "Published articles",
      icon: Book01Icon,
    },
    {
      title: "Incident Reports",
      value: String(incidentCount ?? 0),
      description: "Pending / Under review",
      icon: Alert02Icon,
    },
    {
      title: "Lost & Found",
      value: String(lostFoundCount ?? 0),
      description: "Open / Under review",
      icon: Archive01Icon,
    },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground tracking-tight">Dashboard</h1>
        <p className="text-sm text-muted-foreground mt-1">
          Welcome back. Here&apos;s an overview of your system.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title} className="bg-white border shadow-sm">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#006633]/10">
                <HugeiconsIcon icon={stat.icon} size={18} className="text-[#006633]" strokeWidth={1.8} />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold text-foreground">{stat.value}</div>
              <p className="text-xs text-muted-foreground mt-1">
                {stat.description}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card className="bg-white border shadow-sm">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-base font-semibold">Recent Activity</CardTitle>
                <CardDescription className="text-xs mt-0.5">
                  Latest events across all modules
                </CardDescription>
              </div>
              <HugeiconsIcon icon={Clock01Icon} size={16} className="text-muted-foreground" strokeWidth={1.8} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted mb-3">
                <HugeiconsIcon icon={Clock01Icon} size={20} className="text-muted-foreground" strokeWidth={1.5} />
              </div>
              <p className="text-sm font-medium text-foreground">No recent activity</p>
              <p className="text-xs text-muted-foreground mt-1">
                Activity will appear here once data is available.
              </p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border shadow-sm">
          <CardHeader className="pb-3">
            <CardTitle className="text-base font-semibold">Quick Actions</CardTitle>
            <CardDescription className="text-xs mt-0.5">
              Frequently used admin actions
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-2">
            {quickActions.map((action) => (
              <a
                key={action.href}
                href={action.href}
                className="flex items-center justify-between rounded-lg border border-border bg-background px-4 py-3 text-sm transition-colors hover:bg-[#006633]/5 hover:border-[#006633]/30 group"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-md bg-[#006633]/10 group-hover:bg-[#006633]/15">
                    <HugeiconsIcon icon={action.icon} size={16} className="text-[#006633]" strokeWidth={1.8} />
                  </div>
                  <span className="font-medium text-foreground">{action.label}</span>
                </div>
                <Badge variant="secondary" className="text-xs font-normal">
                  {action.badge}
                </Badge>
              </a>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card className="bg-white border shadow-sm">
        <CardHeader className="pb-3">
          <div className="flex items-center gap-2">
            <div className="h-2 w-2 rounded-full bg-[#006633] animate-pulse" />
            <CardTitle className="text-base font-semibold">System Status</CardTitle>
          </div>
          <CardDescription className="text-xs">All systems are operational</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
            {systemServices.map((service) => (
              <div
                key={service.name}
                className="flex items-center justify-between rounded-lg border border-border bg-background px-4 py-3"
              >
                <span className="text-sm font-medium text-foreground">{service.name}</span>
                <Badge
                  variant="secondary"
                  className="bg-[#006633]/10 text-[#006633] border-0 text-xs font-medium"
                >
                  {service.status}
                </Badge>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
