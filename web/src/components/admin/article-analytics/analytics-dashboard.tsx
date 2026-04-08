"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

import { AnalyticsLineChart } from "./line-chart";
import type {
  ArticleRow,
  ChapterViewsRow,
  PeriodComparison,
  TimeSeriesPoint,
} from "./types";

type AnalyticsDashboardProps = {
  rows: ArticleRow[];
  mostViewed: ArticleRow | null;
  topViewedRows: ArticleRow[];
  topChapterViews: ChapterViewsRow[];
  totalViews: number;
  viewedArticles: number;
  dailyViewsSeries: TimeSeriesPoint[];
  dailyUniqueViewersSeries: TimeSeriesPoint[];
  periodComparison: PeriodComparison | null;
};

function formatDate(value: string | null) {
  if (!value) return "-";
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value));
}

function TopPagesCard({ topViewedRows }: { topViewedRows: ArticleRow[] }) {
  const maxTopArticleViews = topViewedRows[0]?.views ?? 0;

  return (
    <Card className="border bg-white shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-base font-semibold">
          Top 5 Most Viewed Pages
        </CardTitle>
        <CardDescription className="text-xs">
          Leaderboard by article opens
        </CardDescription>
      </CardHeader>
      <CardContent>
        {topViewedRows.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No view data available yet.
          </p>
        ) : (
          <div className="space-y-3">
            {topViewedRows.map((row, index) => {
              const percent =
                maxTopArticleViews > 0
                  ? (row.views / maxTopArticleViews) * 100
                  : 0;

              return (
                <div key={row.id} className="space-y-1.5">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="text-sm font-medium text-foreground">
                        {index + 1}. {row.title}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Chapter {row.chapter} • Section {row.section}
                      </p>
                    </div>
                    <p className="text-sm font-semibold text-foreground">
                      {row.views}
                    </p>
                  </div>

                  <div className="h-2 w-full rounded-full bg-muted">
                    <div
                      className="h-2 rounded-full bg-emerald-500"
                      style={{
                        width: `${Math.max(percent, row.views > 0 ? 8 : 0)}%`,
                      }}
                    />
                  </div>

                  <p className="text-[11px] text-muted-foreground">
                    {row.uniqueViewers} unique viewers • Last viewed{" "}
                    {formatDate(row.lastViewedAt)}
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ChapterBarsCard({
  topChapterViews,
  totalViews,
}: {
  topChapterViews: ChapterViewsRow[];
  totalViews: number;
}) {
  const maxTopChapterViews = topChapterViews[0]?.views ?? 0;

  return (
    <Card className="border bg-white shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-base font-semibold">
          Views by Chapter
        </CardTitle>
        <CardDescription className="text-xs">
          Top chapters ranked by total opens
        </CardDescription>
      </CardHeader>
      <CardContent>
        {topChapterViews.length === 0 || totalViews === 0 ? (
          <p className="text-sm text-muted-foreground">
            No chapter-level view data available yet.
          </p>
        ) : (
          <div className="space-y-3">
            {topChapterViews.map((chapterRow) => {
              const percent =
                maxTopChapterViews > 0
                  ? (chapterRow.views / maxTopChapterViews) * 100
                  : 0;
              const totalShare = (chapterRow.views / totalViews) * 100;

              return (
                <div key={chapterRow.chapter} className="space-y-1.5">
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-medium text-foreground">
                      Chapter {chapterRow.chapter}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {chapterRow.views} views ({totalShare.toFixed(1)}%)
                    </p>
                  </div>

                  <div className="h-2 w-full rounded-full bg-muted">
                    <div
                      className="h-2 rounded-full bg-sky-500"
                      style={{
                        width: `${Math.max(percent, chapterRow.views > 0 ? 8 : 0)}%`,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function ComparisonCard({
  periodComparison,
}: {
  periodComparison: PeriodComparison | null;
}) {
  if (!periodComparison) {
    return (
      <Card className="border bg-white shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-base font-semibold">
            Before vs After
          </CardTitle>
          <CardDescription className="text-xs">
            Needs enough historical events to compare periods
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Not enough timeline data yet for a before/after comparison.
          </p>
        </CardContent>
      </Card>
    );
  }

  const isUp = periodComparison.deltaViews >= 0;
  const deltaLabel = isUp ? "increase" : "decrease";

  return (
    <Card className="border bg-white shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-base font-semibold">
          Before vs After
        </CardTitle>
        <CardDescription className="text-xs">
          Compares first half and second half of tracked activity
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div className="rounded-lg border border-border px-3 py-2">
            <p className="text-xs text-muted-foreground">
              {periodComparison.beforeLabel}
            </p>
            <p className="mt-1 text-xl font-semibold text-foreground">
              {periodComparison.beforeViews}
            </p>
            <p className="text-xs text-muted-foreground">
              {periodComparison.beforeAvgDailyViews.toFixed(1)} avg daily views
            </p>
          </div>
          <div className="rounded-lg border border-border px-3 py-2">
            <p className="text-xs text-muted-foreground">
              {periodComparison.afterLabel}
            </p>
            <p className="mt-1 text-xl font-semibold text-foreground">
              {periodComparison.afterViews}
            </p>
            <p className="text-xs text-muted-foreground">
              {periodComparison.afterAvgDailyViews.toFixed(1)} avg daily views
            </p>
          </div>
        </div>

        <div className="rounded-lg border border-border bg-muted/20 px-3 py-2">
          <p className="text-xs text-muted-foreground">Delta</p>
          <p
            className={`mt-1 text-sm font-semibold ${isUp ? "text-emerald-700" : "text-rose-700"}`}
          >
            {Math.abs(periodComparison.deltaViews)} views {deltaLabel}
            {periodComparison.deltaPercent !== null
              ? ` (${Math.abs(periodComparison.deltaPercent).toFixed(1)}%)`
              : ""}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}

function AllArticlesTable({ rows }: { rows: ArticleRow[] }) {
  return (
    <Card className="border bg-white shadow-sm">
      <CardHeader className="pb-3">
        <CardTitle className="text-base font-semibold">All Articles</CardTitle>
        <CardDescription className="text-xs">
          Sorted by chapter order (1 and up)
        </CardDescription>
      </CardHeader>
      <CardContent className="p-0">
        {rows.length === 0 ? (
          <div className="py-14 text-center">
            <p className="text-sm font-medium text-foreground">
              No articles found
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
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
                  <TableCell className="max-w-85 truncate pl-6 font-medium">
                    {row.title}
                  </TableCell>
                  <TableCell>{row.chapter}</TableCell>
                  <TableCell>{row.section}</TableCell>
                  <TableCell className="text-right">{row.views}</TableCell>
                  <TableCell className="text-right">
                    {row.uniqueViewers}
                  </TableCell>
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
  );
}

export function AnalyticsDashboard({
  rows,
  mostViewed,
  topViewedRows,
  topChapterViews,
  totalViews,
  viewedArticles,
  dailyViewsSeries,
  dailyUniqueViewersSeries,
  periodComparison,
}: AnalyticsDashboardProps) {
  return (
    <Tabs defaultValue="performance">
      <TabsList>
        <TabsTrigger value="performance">Performance</TabsTrigger>
        <TabsTrigger value="trends">Line Trends</TabsTrigger>
        <TabsTrigger value="comparison">Before vs After</TabsTrigger>
      </TabsList>

      <TabsContent value="performance">
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
          <Card className="border bg-white shadow-sm lg:col-span-1">
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold">
                Most Viewed Page
              </CardTitle>
              <CardDescription className="text-xs">
                Based on tracked article opens
              </CardDescription>
            </CardHeader>
            <CardContent>
              {mostViewed ? (
                <div className="space-y-1.5">
                  <p className="text-base font-semibold text-foreground">
                    {mostViewed.title}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Chapter {mostViewed.chapter} • Section {mostViewed.section}
                  </p>
                  <p className="text-sm text-foreground">
                    {mostViewed.views} views • {mostViewed.uniqueViewers} unique
                    viewers
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Last viewed: {formatDate(mostViewed.lastViewedAt)}
                  </p>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">
                  No article data available yet.
                </p>
              )}
            </CardContent>
          </Card>

          <Card className="border bg-white shadow-sm lg:col-span-2">
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold">
                Overview
              </CardTitle>
              <CardDescription className="text-xs">
                All-time article view summary
              </CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-3">
              <div className="rounded-lg border border-border px-3 py-2">
                <p className="text-xs text-muted-foreground">Total Articles</p>
                <p className="mt-1 text-xl font-semibold text-foreground">
                  {rows.length}
                </p>
              </div>
              <div className="rounded-lg border border-border px-3 py-2">
                <p className="text-xs text-muted-foreground">Articles Viewed</p>
                <p className="mt-1 text-xl font-semibold text-foreground">
                  {viewedArticles}
                </p>
              </div>
              <div className="rounded-lg border border-border px-3 py-2">
                <p className="text-xs text-muted-foreground">Total Views</p>
                <p className="mt-1 text-xl font-semibold text-foreground">
                  {totalViews}
                </p>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <TopPagesCard topViewedRows={topViewedRows} />
          <ChapterBarsCard
            topChapterViews={topChapterViews}
            totalViews={totalViews}
          />
        </div>
      </TabsContent>

      <TabsContent value="trends">
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <Card className="border bg-white shadow-sm">
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold">
                Daily Article Opens
              </CardTitle>
              <CardDescription className="text-xs">
                Line chart of opens over time
              </CardDescription>
            </CardHeader>
            <CardContent>
              <AnalyticsLineChart
                data={dailyViewsSeries}
                strokeClassName="text-emerald-600"
              />
            </CardContent>
          </Card>

          <Card className="border bg-white shadow-sm">
            <CardHeader className="pb-2">
              <CardTitle className="text-base font-semibold">
                Daily Unique Viewers
              </CardTitle>
              <CardDescription className="text-xs">
                Distinct users per day
              </CardDescription>
            </CardHeader>
            <CardContent>
              <AnalyticsLineChart
                data={dailyUniqueViewersSeries}
                strokeClassName="text-sky-600"
              />
            </CardContent>
          </Card>
        </div>
      </TabsContent>

      <TabsContent value="comparison">
        <ComparisonCard periodComparison={periodComparison} />
      </TabsContent>

      <AllArticlesTable rows={rows} />
    </Tabs>
  );
}
