import { createAdminClient } from "@/lib/supabase/server"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

type AnalyticsArticle = {
  id: string
  title: string | null
  chapter_id: string | null
  section_id: string | null
  created_at: string
}

type ArticleViewEventRow = {
  article_id: string
  user_id: string
  opened_at: string
}

type ArticleRow = {
  id: string
  title: string
  chapter: string
  section: string
  views: number
  uniqueViewers: number
  lastViewedAt: string | null
}

function formatDate(value: string | null) {
  if (!value) return "-"
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value))
}

function compareHierarchicalIds(a: string, b: string) {
  const aParts = a
    .split(".")
    .map((part) => Number.parseInt(part, 10))
  const bParts = b
    .split(".")
    .map((part) => Number.parseInt(part, 10))

  const maxLen = Math.max(aParts.length, bParts.length)
  for (let i = 0; i < maxLen; i += 1) {
    const aPart = Number.isFinite(aParts[i]) ? aParts[i] : Number.MAX_SAFE_INTEGER
    const bPart = Number.isFinite(bParts[i]) ? bParts[i] : Number.MAX_SAFE_INTEGER
    if (aPart !== bPart) return aPart - bPart
  }

  return a.localeCompare(b)
}

export default async function ArticleAnalyticsPage() {
  const supabase = await createAdminClient()

  const [{ data: articles = [] }, { data: events = [] }] = await Promise.all([
    supabase
      .from("articles")
      .select("id,title,chapter_id,section_id,created_at")
      .order("chapter_id", { ascending: true })
      .order("section_id", { ascending: true })
      .order("title", { ascending: true }),
    supabase
      .from("article_view_events")
      .select("article_id,user_id,opened_at")
      .order("opened_at", { ascending: false }),
  ])

  const eventRows = (events ?? []) as ArticleViewEventRow[]

  const metricsByArticle = new Map<
    string,
    { views: number; viewers: Set<string>; lastViewedAt: string | null }
  >()

  for (const event of eventRows) {
    const existing =
      metricsByArticle.get(event.article_id) ?? {
        views: 0,
        viewers: new Set<string>(),
        lastViewedAt: null,
      }

    existing.views += 1
    existing.viewers.add(event.user_id)
    if (!existing.lastViewedAt || event.opened_at > existing.lastViewedAt) {
      existing.lastViewedAt = event.opened_at
    }

    metricsByArticle.set(event.article_id, existing)
  }

  const rows: ArticleRow[] = ((articles ?? []) as AnalyticsArticle[]).map((article) => {
    const metric = metricsByArticle.get(article.id)
    return {
      id: article.id,
      title: article.title ?? "Untitled Article",
      chapter: article.chapter_id ?? "-",
      section: article.section_id ?? "-",
      views: metric?.views ?? 0,
      uniqueViewers: metric?.viewers.size ?? 0,
      lastViewedAt: metric?.lastViewedAt ?? null,
    }
  })

  rows.sort((a, b) => {
    const chapterCompare = compareHierarchicalIds(a.chapter, b.chapter)
    if (chapterCompare !== 0) return chapterCompare

    const sectionCompare = compareHierarchicalIds(a.section, b.section)
    if (sectionCompare !== 0) return sectionCompare

    return a.title.localeCompare(b.title)
  })

  const mostViewed =
    rows.length === 0
      ? null
      : [...rows].sort((a, b) => {
          if (b.views !== a.views) return b.views - a.views
          return a.title.localeCompare(b.title)
        })[0]
  const totalViews = rows.reduce((sum, row) => sum + row.views, 0)
  const viewedArticles = rows.filter((row) => row.views > 0).length

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground tracking-tight">Article Analytics</h1>
        <p className="text-sm text-muted-foreground mt-1">
          See all handbook articles and identify the most viewed page from mobile activity.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="bg-white border shadow-sm lg:col-span-1">
          <CardHeader className="pb-2">
            <CardTitle className="text-base font-semibold">Most Viewed Page</CardTitle>
            <CardDescription className="text-xs">Based on tracked article opens</CardDescription>
          </CardHeader>
          <CardContent>
            {mostViewed ? (
              <div className="space-y-1.5">
                <p className="text-base font-semibold text-foreground">{mostViewed.title}</p>
                <p className="text-xs text-muted-foreground">
                  Chapter {mostViewed.chapter} • Section {mostViewed.section}
                </p>
                <p className="text-sm text-foreground">
                  {mostViewed.views} views • {mostViewed.uniqueViewers} unique viewers
                </p>
                <p className="text-xs text-muted-foreground">
                  Last viewed: {formatDate(mostViewed.lastViewedAt)}
                </p>
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No article data available yet.</p>
            )}
          </CardContent>
        </Card>

        <Card className="bg-white border shadow-sm lg:col-span-2">
          <CardHeader className="pb-2">
            <CardTitle className="text-base font-semibold">Overview</CardTitle>
            <CardDescription className="text-xs">All-time article view summary</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-3">
            <div className="rounded-lg border border-border px-3 py-2">
              <p className="text-xs text-muted-foreground">Total Articles</p>
              <p className="mt-1 text-xl font-semibold text-foreground">{rows.length}</p>
            </div>
            <div className="rounded-lg border border-border px-3 py-2">
              <p className="text-xs text-muted-foreground">Articles Viewed</p>
              <p className="mt-1 text-xl font-semibold text-foreground">{viewedArticles}</p>
            </div>
            <div className="rounded-lg border border-border px-3 py-2">
              <p className="text-xs text-muted-foreground">Total Views</p>
              <p className="mt-1 text-xl font-semibold text-foreground">{totalViews}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="bg-white border shadow-sm">
        <CardHeader className="pb-3">
          <CardTitle className="text-base font-semibold">All Articles</CardTitle>
          <CardDescription className="text-xs">Sorted by chapter order (1 and up)</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          {rows.length === 0 ? (
            <div className="py-14 text-center">
              <p className="text-sm font-medium text-foreground">No articles found</p>
              <p className="text-xs text-muted-foreground mt-1">
                Create articles in the handbook module to see analytics here.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Title</TableHead>
                  <TableHead>Chapter</TableHead>
                  <TableHead>Section</TableHead>
                  <TableHead className="text-right">Views</TableHead>
                  <TableHead className="text-right">Unique Viewers</TableHead>
                  <TableHead className="pr-6 text-right">Last Viewed</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.id}>
                    <TableCell className="pl-6 font-medium max-w-[340px] truncate">{row.title}</TableCell>
                    <TableCell>{row.chapter}</TableCell>
                    <TableCell>{row.section}</TableCell>
                    <TableCell className="text-right">{row.views}</TableCell>
                    <TableCell className="text-right">{row.uniqueViewers}</TableCell>
                    <TableCell className="pr-6 text-right text-xs text-muted-foreground">
                      {formatDate(row.lastViewedAt)}
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
