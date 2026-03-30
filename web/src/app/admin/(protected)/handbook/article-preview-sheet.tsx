"use client"

import { useState } from "react"
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import type { Article } from "@/lib/supabase/types"

interface ArticlePreviewSheetProps {
  article: Article
  trigger: React.ReactNode
}

export function ArticlePreviewSheet({ article, trigger }: ArticlePreviewSheetProps) {
  const [open, setOpen] = useState(false)

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={<button type="button" className="w-full cursor-pointer text-left" />}
      >
        {trigger}
      </SheetTrigger>

      <SheetContent
        side="center"
        showCloseButton={false}
        className="flex h-fit max-h-[85vh] w-[min(90vw,64rem)] flex-col overflow-hidden rounded-2xl border-0 p-0 shadow-2xl data-starting-style:opacity-0 data-ending-style:opacity-0 data-starting-style:scale-[0.97] data-ending-style:scale-[0.97]"
      >
        <SheetHeader className="px-8 pt-6 pb-4">
          <div className="flex items-start justify-between gap-4">
            <div>
              <SheetTitle className="text-lg font-semibold text-foreground">
                {article.title ?? "Untitled"}
              </SheetTitle>
              <div className="mt-2 flex flex-wrap items-center gap-2">
                {article.content_type && (
                  <Badge variant="secondary" className="text-[10px] capitalize">
                    {article.content_type}
                  </Badge>
                )}
                {article.chapter_id && (
                  <span className="text-[10px] text-muted-foreground">Chapter #{article.chapter_id}</span>
                )}
                {article.section_id && (
                  <span className="text-[10px] text-muted-foreground">Section {article.section_id}</span>
                )}
                {article.page_approx && (
                  <span className="text-[10px] text-muted-foreground">Page {article.page_approx}</span>
                )}
              </div>
            </div>

            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setOpen(false)}
              className="h-8 w-8 p-0 rounded-full text-muted-foreground hover:text-foreground"
            >
              ✕
            </Button>
          </div>
        </SheetHeader>

        <Separator />

        <div className="overflow-y-auto px-8 py-6">
          {article.body_text ? (
            <p className="whitespace-pre-line text-sm leading-7 text-foreground">{article.body_text}</p>
          ) : (
            <p className="text-sm text-muted-foreground">No article content available.</p>
          )}
        </div>
      </SheetContent>
    </Sheet>
  )
}