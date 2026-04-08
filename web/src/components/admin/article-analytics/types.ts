export type ArticleViewEventRow = {
  article_id: string;
  user_id: string;
  opened_at: string;
};

export type ArticleRow = {
  id: string;
  title: string;
  chapter: string;
  section: string;
  views: number;
  uniqueViewers: number;
  lastViewedAt: string | null;
};

export type ChapterViewsRow = {
  chapter: string;
  views: number;
};

export type TimeSeriesPoint = {
  dateKey: string;
  label: string;
  value: number;
};

export type PeriodComparison = {
  beforeLabel: string;
  afterLabel: string;
  beforeViews: number;
  afterViews: number;
  beforeAvgDailyViews: number;
  afterAvgDailyViews: number;
  deltaViews: number;
  deltaPercent: number | null;
};
