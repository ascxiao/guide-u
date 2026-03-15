import Link from "next/link"
import { createAdminClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import {
	Table,
	TableBody,
	TableCell,
	TableHead,
	TableHeader,
	TableRow,
} from "@/components/ui/table"
import { ArticleFormSheet, DeleteArticleButton } from "./article-form-sheet"
import { ArticlePreviewSheet } from "./article-preview-sheet"
import type { Article } from "@/lib/supabase/types"

function getMajorChapterId(value: string | null | undefined) {
	if (!value) return null
	const major = value.trim().split(".")[0]
	return /^\d+$/.test(major) ? major : null
}

function compareHierarchicalIds(a: string | null | undefined, b: string | null | undefined) {
	const aParts = String(a ?? "")
		.split(".")
		.map((part) => Number.parseInt(part, 10))
	const bParts = String(b ?? "")
		.split(".")
		.map((part) => Number.parseInt(part, 10))

	const maxLen = Math.max(aParts.length, bParts.length)
	for (let i = 0; i < maxLen; i += 1) {
		const aPart = Number.isFinite(aParts[i]) ? aParts[i] : -1
		const bPart = Number.isFinite(bParts[i]) ? bParts[i] : -1
		if (aPart !== bPart) return aPart - bPart
	}

	return String(a ?? "").localeCompare(String(b ?? ""))
}

export default async function HandbookPage({
	searchParams,
}: {
	searchParams: Promise<{ chapter?: string; q?: string }>
}) {
	const { chapter, q } = await searchParams
	const activeChapter = chapter ?? "all"
	const searchQuery = (q ?? "").trim()
	const supabase = await createAdminClient()

	let query = supabase
		.from("articles")
		.select("*")
		.order("chapter_id", { ascending: true })
		.order("section_id", { ascending: true })
		.order("sub_section_id", { ascending: true })

	if (searchQuery) {
		query = query.or(
			[
				`title.ilike.%${searchQuery}%`,
				`chapter_title.ilike.%${searchQuery}%`,
				`section_title.ilike.%${searchQuery}%`,
				`sub_section_title.ilike.%${searchQuery}%`,
				`body_text.ilike.%${searchQuery}%`,
			].join(",")
		)
	}

	const { data: articles = [] } = await query

	const { data: allArticles } = await supabase
		.from("articles")
		.select("chapter_id, chapter_title")

	const chapterGroups = new Map<string, { title: string; count: number }>()
	for (const article of allArticles ?? []) {
		const majorId = getMajorChapterId(article.chapter_id)
		if (!majorId) continue

		const existing = chapterGroups.get(majorId)
		if (existing) {
			chapterGroups.set(majorId, { ...existing, count: existing.count + 1 })
			continue
		}

		chapterGroups.set(majorId, {
			title: article.chapter_title ?? `Chapter ${majorId}`,
			count: 1,
		})
	}

	const chapters = [...chapterGroups.entries()]
		.sort((a, b) => Number.parseInt(a[0], 10) - Number.parseInt(b[0], 10))
		.map(([id, meta]) => ({ id, title: meta.title, count: meta.count }))

	const filteredArticles = (articles ?? []).filter((article) => {
		if (activeChapter === "all") return true
		return getMajorChapterId(article.chapter_id) === activeChapter
	}) as Article[]

	const sortedArticles = [...filteredArticles].sort((a, b) => {
		return (
			compareHierarchicalIds(a.chapter_id, b.chapter_id) ||
			compareHierarchicalIds(a.section_id, b.section_id) ||
			compareHierarchicalIds(a.sub_section_id, b.sub_section_id)
		)
	})

	function buildHref(ch: string, searchValue: string) {
		const params = new URLSearchParams()
		if (ch !== "all") params.set("chapter", ch)
		if (searchValue) params.set("q", searchValue)
		const qs = params.toString()
		return `/admin/handbook${qs ? `?${qs}` : ""}`
	}

	return (
		<div className="space-y-6">
			<div className="flex items-start justify-between">
				<div>
					<h1 className="text-2xl font-semibold text-foreground tracking-tight">Handbook</h1>
					<p className="text-sm text-muted-foreground mt-1">
						Manage student handbook articles.
					</p>
				</div>
				<ArticleFormSheet />
			</div>

			<Card className="bg-white border shadow-sm">
				<CardContent className="p-3">
					<div className="flex flex-col gap-3">
						<form action="/admin/handbook" method="get" className="flex flex-col gap-2 sm:flex-row sm:items-center">
							{chapter && chapter !== "all" && <input type="hidden" name="chapter" value={chapter} />}
							<Input
								name="q"
								defaultValue={searchQuery}
								placeholder="Search by title, chapter, section, or content"
								className="h-9 w-full bg-background px-3 text-sm"
							/>
							<div className="flex items-center gap-2">
								<Button type="submit" className="h-9 bg-[#006633] px-4 text-white hover:bg-[#005229]">
									Search
								</Button>
								{(searchQuery || (chapter && chapter !== "all")) && (
									<Link
										href="/admin/handbook"
										className="inline-flex h-9 items-center justify-center rounded-md border border-border bg-background px-3 text-xs font-medium text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
									>
										Clear
									</Link>
								)}
							</div>
						</form>

						{chapters.length > 0 && (
							<div className="flex flex-wrap items-center gap-2">
								<span className="text-xs font-medium text-muted-foreground">Chapter filters</span>
								<Link
									href={buildHref("all", searchQuery)}
									className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium shadow-sm transition-colors ${
										activeChapter === "all"
											? "border-[#006633] bg-[#006633] text-white"
											: "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
									}`}
								>
									All Chapters
									<span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${activeChapter === "all" ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
										{(allArticles ?? []).length}
									</span>
								</Link>
								{chapters.map((ch) => {
									const isActive = activeChapter === ch.id
									return (
										<Link
											key={ch.id}
											href={buildHref(ch.id, searchQuery)}
											className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium shadow-sm transition-colors ${
												isActive
													? "border-[#006633] bg-[#006633] text-white"
													: "border-border bg-background text-muted-foreground hover:border-[#006633]/40 hover:text-foreground"
											}`}
										>
											{ch.id}
											<span className={`rounded-full px-1.5 py-0.5 text-[10px] font-semibold ${isActive ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
												{ch.count}
											</span>
										</Link>
									)
								})}
							</div>
						)}
					</div>
				</CardContent>
			</Card>

			<Card className="bg-white border shadow-sm">
				<CardHeader className="pb-3">
					<CardTitle className="text-base font-semibold">Articles</CardTitle>
					<CardDescription className="text-xs mt-0.5">
						{sortedArticles.length} {sortedArticles.length === 1 ? "article" : "articles"}
						{activeChapter !== "all" ? ` in chapter ${activeChapter}` : " total"}
						{searchQuery ? ` matching "${searchQuery}"` : ""}
					</CardDescription>
				</CardHeader>
				<CardContent className="p-0">
					{sortedArticles.length === 0 ? (
						<div className="flex flex-col items-center justify-center py-16 text-center">
							<p className="text-sm font-medium text-foreground">No articles found</p>
							<p className="text-xs text-muted-foreground mt-1 max-w-xs">
								{searchQuery
									? "Try a different search term or clear chapter filters."
									: "Add your first article or import articles from your handbook data."}
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
								{sortedArticles.map((article) => (
									<TableRow key={article.id}>
										<TableCell className="pl-6 font-medium max-w-[220px]">
											<ArticlePreviewSheet
												article={article}
												trigger={
													<span className="block cursor-pointer truncate text-foreground transition-colors hover:text-[#006633]">
														{article.title ?? "Untitled"}
													</span>
												}
											/>
											{article.sub_section_title && (
												<p className="text-xs text-muted-foreground truncate">{article.sub_section_title}</p>
											)}
										</TableCell>
										<TableCell className="text-muted-foreground">
											<p className="text-xs">{article.chapter_title ?? "-"}</p>
											{article.chapter_id && (
												<p className="text-[10px] text-muted-foreground/70">#{article.chapter_id}</p>
											)}
										</TableCell>
										<TableCell className="text-muted-foreground">
											<p className="text-xs">{article.section_title ?? "-"}</p>
											{article.section_id && (
												<p className="text-[10px] text-muted-foreground/70">Section {article.section_id}</p>
											)}
										</TableCell>
										<TableCell>
											{article.content_type ? (
												<Badge variant="secondary" className="text-xs capitalize">
													{article.content_type}
												</Badge>
											) : (
												<span className="text-xs text-muted-foreground">-</span>
											)}
										</TableCell>
										<TableCell className="text-muted-foreground text-xs">
											{article.page_approx ?? "-"}
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
