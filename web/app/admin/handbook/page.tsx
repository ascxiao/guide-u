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
import { ArticleFormSheet, DeleteArticleButton } from "./article-form-sheet"
import type { Article } from "@/lib/supabase/types"

export default async function HandbookPage({
  searchParams,
}: {
  searchParams: Promise<{ chapter?: string }>
}) {
  const { chapter } = await searchParams
  const supabase = await createAdminClient()

  let query = supabase
    .from("articles")
    .select("*")
    .order("chapter_id", { ascending: true })
    .order("section_id", { ascending: true })
    .order("sub_section_id", { ascending: true })

  if (chapter && chapter !== "all") {
    query = query.eq("chapter_title", chapter)
  }

  const { data: articles = [] } = await query
  const typedArticles = (articles ?? []) as Article[]

  // Get distinct chapters for filter
  const { data: allArticles } = await supabase
    .from("articles")
    .select("chapter_title")
    .order("chapter_title", { ascending: true })

  const chapters = [...new Set((allArticles ?? []).map((a) => a.chapter_title).filter(Boolean))] as string[]

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-foreground tracking-tight">Handbook</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Manage student handbook articles.
          </p>
        </div>
        <ArticleFormSheet />
      </div>

      {/* Chapter filters */}
      {chapters.length > 0 && (
        <div className="flex flex-wrap gap-2">
          <Link
            href="/admin/handbook"
            className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
              !chapter || chapter === "all"
                ? "border-[#006633] bg-[#006633] text-white"
                : "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
            }`}
          >
            All Chapters
            <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${!chapter || chapter === "all" ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
              {(allArticles ?? []).length}
            </span>
          </Link>
          {chapters.map((ch) => {
            const isActive = chapter === ch
            const count = (allArticles ?? []).filter((a) => a.chapter_title === ch).length
            return (
              <Link
                key={ch}
                href={`/admin/handbook?chapter=${encodeURIComponent(ch)}`}
                className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                  isActive
                    ? "border-[#006633] bg-[#006633] text-white"
                    : "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
                }`}
              >
                {ch}
                <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${isActive ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
                  {count}
                </span>
              </Link>
            )
          })}
        </div>
      )}

      <Card className="bg-white border shadow-sm">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base font-semibold">Articles</CardTitle>
              <CardDescription className="text-xs mt-0.5">
                {typedArticles.length} {typedArticles.length === 1 ? "article" : "articles"}
                {chapter && chapter !== "all" ? ` in "${chapter}"` : " total"}
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {typedArticles.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <p className="text-sm font-medium text-foreground">No articles yet</p>
              <p className="text-xs text-muted-foreground mt-1 max-w-xs">
                Add your first article using the &quot;+ New Article&quot; button above, or import articles from your handbook data.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Title</TableHead>
                  <TableHead>Chapter</TableHead>
                  <TableHead>Section</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Page</TableHead>
                  <TableHead className="pr-6 text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {typedArticles.map((article) => (
                  <TableRow key={article.id}>
                    <TableCell className="pl-6 font-medium max-w-[200px]">
                      <p className="truncate">{article.title ?? "Untitled"}</p>
                      {article.sub_section_title && (
                        <p className="text-xs text-muted-foreground truncate">{article.sub_section_title}</p>
                      )}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      <p className="text-xs">{article.chapter_title ?? "—"}</p>
                      {article.chapter_id && (
                        <p className="text-[10px] text-muted-foreground/70">#{article.chapter_id}</p>
                      )}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      <p className="text-xs">{article.section_title ?? "—"}</p>
                      {article.section_id && (
                        <p className="text-[10px] text-muted-foreground/70">§{article.section_id}</p>
                      )}
                    </TableCell>
                    <TableCell>
                      {article.content_type ? (
                        <Badge variant="secondary" className="text-xs capitalize">
                          {article.content_type}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-xs">
                      {article.page_approx ?? "—"}
                    </TableCell>
                    <TableCell className="pr-6">
                      <div className="flex items-center justify-end gap-1">
                        <ArticleFormSheet article={article} />
                        <DeleteArticleButton id={article.id} />
                      </div>
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

