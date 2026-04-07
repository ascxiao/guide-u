import type { TimeSeriesPoint } from "./types";

type AnalyticsLineChartProps = {
  data: TimeSeriesPoint[];
  strokeClassName: string;
};

function createPolylinePoints(
  data: TimeSeriesPoint[],
  width: number,
  height: number,
) {
  if (data.length === 0) return "";

  const maxValue = Math.max(...data.map((item) => item.value), 1);

  return data
    .map((item, index) => {
      const x =
        data.length === 1 ? width / 2 : (index / (data.length - 1)) * width;
      const y = height - (item.value / maxValue) * (height - 8);
      return `${x},${y}`;
    })
    .join(" ");
}

export function AnalyticsLineChart({
  data,
  strokeClassName,
}: AnalyticsLineChartProps) {
  const width = 760;
  const height = 220;
  const points = createPolylinePoints(data, width, height);
  const maxValue = Math.max(...data.map((item) => item.value), 1);

  if (data.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        No trend data available yet.
      </p>
    );
  }

  const firstLabel = data[0]?.label ?? "";
  const midLabel = data[Math.floor(data.length / 2)]?.label ?? "";
  const lastLabel = data[data.length - 1]?.label ?? "";

  return (
    <div className="space-y-3">
      <div className="rounded-lg border border-border/80 bg-muted/20 p-3">
        <svg
          viewBox={`0 0 ${width} ${height}`}
          className="h-52 w-full"
          role="img"
          aria-label="Line chart"
        >
          <line
            x1="0"
            y1={height - 1}
            x2={width}
            y2={height - 1}
            stroke="currentColor"
            className="text-border"
          />

          <polyline
            fill="none"
            stroke="currentColor"
            strokeWidth="3"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={points}
            className={strokeClassName}
          />

          {data.map((item, index) => {
            const x =
              data.length === 1
                ? width / 2
                : (index / (data.length - 1)) * width;
            const y = height - (item.value / maxValue) * (height - 8);
            return (
              <circle
                key={`${item.dateKey}-${item.value}`}
                cx={x}
                cy={y}
                r="3"
                fill="currentColor"
                className={strokeClassName}
              />
            );
          })}
        </svg>
      </div>

      <div className="flex items-center justify-between text-[11px] text-muted-foreground">
        <span>{firstLabel}</span>
        <span>{midLabel}</span>
        <span>{lastLabel}</span>
      </div>
    </div>
  );
}
