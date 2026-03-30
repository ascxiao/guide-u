import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { unstable_cache } from "next/cache"
import { createAdminClient } from "@/lib/supabase/server"

const DASHBOARD_STATS_REVALIDATE_SECONDS = 30

interface RecentArticleOpen {
  opened_at: string
  user_id: string
  title: string | null
}

const getDashboardStats = unstable_cache(
  async () => {
    const supabase = await createAdminClient()
    const sevenDaysAgoIso = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

    const [
      { count: articleCount },
      { count: incidentCount },
      { count: lostFoundCount },
      { count: userCount },
      articleOpenResult,
      recentOpensResult,
    ] = await Promise.all([
      supabase.from("articles").select("id", { count: "estimated", head: true }),
      supabase
        .from("incident_reports")
        .select("id", { count: "estimated", head: true })
        .in("status", ["pending", "under_review"]),
      supabase
        .from("lost_found_reports")
        .select("id", { count: "estimated", head: true })
        .in("status", ["open", "under_review"]),
      // Counting profiles is significantly faster than auth.admin.listUsers in most setups.
      supabase.from("profiles").select("id", { count: "estimated", head: true }),
      supabase
        .from("article_view_events")
        .select("id", { count: "exact", head: true })
        .gte("opened_at", sevenDaysAgoIso),
      supabase
        .from("article_view_events")
        .select("opened_at,user_id,article:articles(title)")
        .order("opened_at", { ascending: false })
        .limit(8),
    ])

    const articleOpen7d = articleOpenResult.error ? 0 : articleOpenResult.count ?? 0
    const recentArticleOpens: RecentArticleOpen[] = recentOpensResult.error
      ? []
      : (recentOpensResult.data ?? []).map((event: any) => ({
          opened_at: event.opened_at,
          user_id: event.user_id,
          title: event.article?.title ?? null,
        }))

    return {
      articleCount: articleCount ?? 0,
      incidentCount: incidentCount ?? 0,
      lostFoundCount: lostFoundCount ?? 0,
      userCount: userCount ?? 0,
      articleOpen7d,
      recentArticleOpens,
    }
  },
  ["admin-dashboard-stats"],
  { revalidate: DASHBOARD_STATS_REVALIDATE_SECONDS }
)

const quickActions = [
  { label: "Add Handbook Entry", href: "/admin/handbook", icon: "H", badge: "Handbook" },
  { label: "View Article Analytics", href: "/admin/article-analytics", icon: "A", badge: "Analytics" },
  { label: "Review Incident Reports", href: "/admin/incident-report", icon: "I", badge: "Incidents" },
  { label: "Manage Lost & Found", href: "/admin/lost-and-found", icon: "L", badge: "Lost & Found" },
]

const systemServices = [
  { name: "Database", status: "Operational" },
  { name: "API Server", status: "Operational" },
  { name: "Auth Service", status: "Operational" },
]

export default async function DashboardPage() {
  const { articleCount, incidentCount, lostFoundCount, userCount, articleOpen7d, recentArticleOpens } = await getDashboardStats()

  const dateFormatter = new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  })

  const stats = [
    {
      title: "Total Users",
      value: String(userCount),
      description: "Registered accounts",
      icon: "U",
    },
    {
      title: "Handbook Entries",
      value: String(articleCount),
      description: "Published articles",
      icon: "H",
    },
    {
      title: "Incident Reports",
      value: String(incidentCount),
      description: "Pending / Under review",
      icon: "I",
    },
    {
      title: "Lost & Found",
      value: String(lostFoundCount),
      description: "Open / Under review",
      icon: "L",
    },
    {
      title: "Article Opens (7d)",
      value: String(articleOpen7d),
      description: "Tracked mobile article views",
      icon: "A",
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

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {stats.map((stat) => (
          <Card key={stat.title} className="bg-white border shadow-sm">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#006633]/10">
                <span className="text-sm font-semibold text-[#006633]">{stat.icon}</span>
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
              <span className="text-sm text-muted-foreground">T</span>
            </div>
          </CardHeader>
          <CardContent>
            {recentArticleOpens.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-10 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted mb-3">
                  <span className="text-sm font-semibold text-muted-foreground">A</span>
                </div>
                <p className="text-sm font-medium text-foreground">No recent article opens</p>
                <p className="text-xs text-muted-foreground mt-1">
                  Article opens from the mobile app will appear here.
                </p>
              </div>
            ) : (
              <div className="space-y-2">
                {recentArticleOpens.map((event, index) => (
                  <div
                    key={`${event.user_id}-${event.opened_at}-${index}`}
                    className="flex items-start justify-between gap-3 rounded-lg border border-border bg-background px-3 py-2"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-foreground truncate">
                        {event.title ?? "Untitled Article"}
                      </p>
                      <p className="text-xs text-muted-foreground truncate">
                        User {event.user_id.slice(0, 8)}
                      </p>
                    </div>
                    <p className="text-xs text-muted-foreground whitespace-nowrap">
                      {dateFormatter.format(new Date(event.opened_at))}
                    </p>
                  </div>
                ))}
              </div>
            )}
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
                    <span className="text-xs font-semibold text-[#006633]">{action.icon}</span>
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
