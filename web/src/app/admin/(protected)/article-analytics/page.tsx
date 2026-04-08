import { createAdminClient } from "@/lib/supabase/server";
import { AnalyticsDashboard } from "@/components/admin/article-analytics/analytics-dashboard";

function compareHierarchicalIds(a, b) {
  const aParts = a.split(".").map((part) => Number.parseInt(part, 10));
  const bParts = b.split(".").map((part) => Number.parseInt(part, 10));

  const maxLen = Math.max(aParts.length, bParts.length);
  for (let i = 0; i < maxLen; i += 1) {
    const aPart = Number.isFinite(aParts[i])
      ? aParts[i]
      : Number.MAX_SAFE_INTEGER;
    const bPart = Number.isFinite(bParts[i])
      ? bParts[i]
      : Number.MAX_SAFE_INTEGER;
    if (aPart !== bPart) return aPart - bPart;
  }

  return a.localeCompare(b);
}

function formatCompactDate(value) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
  }).format(new Date(`${value}T00:00:00.000Z`));
}

function buildPeriodComparison(sortedDates, dailyViewsMap) {
  if (sortedDates.length < 4) {
    return null;
  }

  const splitIndex = Math.floor(sortedDates.length / 2);
  const beforeDates = sortedDates.slice(0, splitIndex);
  const afterDates = sortedDates.slice(splitIndex);

  if (beforeDates.length === 0 || afterDates.length === 0) {
    return null;
  }

  const beforeViews = beforeDates.reduce(
    (sum, day) => sum + (dailyViewsMap.get(day) ?? 0),
    0,
  );
  const afterViews = afterDates.reduce(
    (sum, day) => sum + (dailyViewsMap.get(day) ?? 0),
    0,
  );

  const beforeAvgDailyViews = beforeViews / beforeDates.length;
  const afterAvgDailyViews = afterViews / afterDates.length;
  const deltaViews = afterViews - beforeViews;

  const deltaPercent =
    beforeViews === 0 ? null : (deltaViews / beforeViews) * 100;

  const beforeLabel = `Before (${formatCompactDate(beforeDates[0])} - ${formatCompactDate(beforeDates[beforeDates.length - 1])})`;
  const afterLabel = `After (${formatCompactDate(afterDates[0])} - ${formatCompactDate(afterDates[afterDates.length - 1])})`;

  return {
    beforeLabel,
    afterLabel,
    beforeViews,
    afterViews,
    beforeAvgDailyViews,
    afterAvgDailyViews,
    deltaViews,
    deltaPercent,
  };
}

export default async function ArticleAnalyticsPage() {
  const supabase = await createAdminClient();

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
  ]);

  const eventRows = events ?? [];

  const metricsByArticle = new Map();

  const dailyViewsMap = new Map();
  const dailyUniqueViewersMap = new Map();

  for (const event of eventRows) {
    const existing = metricsByArticle.get(event.article_id) ?? {
      views: 0,
      viewers: new Set(),
      lastViewedAt: null,
    };

    existing.views += 1;
    existing.viewers.add(event.user_id);
    if (!existing.lastViewedAt || event.opened_at > existing.lastViewedAt) {
      existing.lastViewedAt = event.opened_at;
    }

    metricsByArticle.set(event.article_id, existing);

    const day = event.opened_at.slice(0, 10);
    dailyViewsMap.set(day, (dailyViewsMap.get(day) ?? 0) + 1);

    const dailyViewers = dailyUniqueViewersMap.get(day) ?? new Set();
    dailyViewers.add(event.user_id);
    dailyUniqueViewersMap.set(day, dailyViewers);
  }

  const rows = (articles ?? []).map((article) => {
    const metric = metricsByArticle.get(article.id);
    return {
      id: article.id,
      title: article.title ?? "Untitled Article",
      chapter: article.chapter_id ?? "-",
      section: article.section_id ?? "-",
      views: metric?.views ?? 0,
      uniqueViewers: metric?.viewers.size ?? 0,
      lastViewedAt: metric?.lastViewedAt ?? null,
    };
  });

  rows.sort((a, b) => {
    const chapterCompare = compareHierarchicalIds(a.chapter, b.chapter);
    if (chapterCompare !== 0) return chapterCompare;

    const sectionCompare = compareHierarchicalIds(a.section, b.section);
    if (sectionCompare !== 0) return sectionCompare;

    return a.title.localeCompare(b.title);
  });

  const mostViewed =
    rows.length === 0
      ? null
      : [...rows].sort((a, b) => {
          if (b.views !== a.views) return b.views - a.views;
          return a.title.localeCompare(b.title);
        })[0];

  const topViewedRows = [...rows]
    .sort((a, b) => {
      if (b.views !== a.views) return b.views - a.views;
      return a.title.localeCompare(b.title);
    })
    .slice(0, 5);

  const chapterViewsMap = new Map();
  for (const row of rows) {
    const chapterKey = row.chapter === "-" ? "Unassigned" : row.chapter;
    chapterViewsMap.set(
      chapterKey,
      (chapterViewsMap.get(chapterKey) ?? 0) + row.views,
    );
  }

  const chapterViews = [...chapterViewsMap.entries()]
    .map(([chapter, views]) => ({ chapter, views }))
    .sort((a, b) => {
      if (b.views !== a.views) return b.views - a.views;
      return compareHierarchicalIds(a.chapter, b.chapter);
    });

  const topChapterViews = chapterViews.slice(0, 6);

  const totalViews = rows.reduce((sum, row) => sum + row.views, 0);
  const viewedArticles = rows.filter((row) => row.views > 0).length;

  const sortedDates = [...dailyViewsMap.keys()].sort((a, b) =>
    a.localeCompare(b),
  );

  const dailyViewsSeries = sortedDates.map((dateKey) => ({
    dateKey,
    label: formatCompactDate(dateKey),
    value: dailyViewsMap.get(dateKey) ?? 0,
  }));

  const dailyUniqueViewersSeries = sortedDates.map((dateKey) => ({
    dateKey,
    label: formatCompactDate(dateKey),
    value: dailyUniqueViewersMap.get(dateKey)?.size ?? 0,
  }));

  const periodComparison = buildPeriodComparison(sortedDates, dailyViewsMap);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          Article Analytics
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Explore top pages, timeline trends, and before-vs-after performance
          from mobile activity.
        </p>
      </div>

      <AnalyticsDashboard
        rows={rows}
        mostViewed={mostViewed}
        topViewedRows={topViewedRows}
        topChapterViews={topChapterViews}
        totalViews={totalViews}
        viewedArticles={viewedArticles}
        dailyViewsSeries={dailyViewsSeries}
        dailyUniqueViewersSeries={dailyUniqueViewersSeries}
        periodComparison={periodComparison}
      />
    </div>
  );
}
