"use client"

import { useState, useTransition } from "react"
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { createArticle, updateArticle, deleteArticle } from "./actions"
import type { Article } from "@/lib/supabase/types"

interface ArticleFormSheetProps {
  article?: Article
  trigger?: React.ReactNode
}

export function ArticleFormSheet({ article, trigger }: ArticleFormSheetProps) {
  const [open, setOpen] = useState(false)
  const [isPending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const isEdit = !!article

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError(null)
    const formData = new FormData(e.currentTarget)
    startTransition(async () => {
      const result = isEdit
        ? await updateArticle(article.id, formData)
        : await createArticle(formData)
      if (result.error) {
        setError(result.error)
      } else {
        setOpen(false)
      }
    })
  }

  const triggerEl = isEdit ? (
    <Button variant="ghost" size="sm" className="h-7 text-xs" />
  ) : (
    <Button size="sm" className="bg-[#006633] hover:bg-[#005229] text-white h-8 px-4 text-xs font-medium" />
  )

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger
        render={
          trigger
            ? <button type="button" className="cursor-pointer text-left" />
            : triggerEl
        }
      >
        {trigger ?? (isEdit ? "Edit" : "+ New Article")}
      </SheetTrigger>

      <SheetContent
        side="center"
        showCloseButton={false}
        className="flex h-fit max-h-[85vh] w-[min(90vw,72rem)] flex-col overflow-hidden rounded-2xl border-0 p-0 shadow-2xl data-starting-style:opacity-0 data-ending-style:opacity-0 data-starting-style:scale-[0.97] data-ending-style:scale-[0.97]"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-8 pt-6 pb-4 shrink-0">
          <div>
            <SheetTitle className="text-lg font-semibold text-foreground">
              {isEdit ? "Edit Article" : "New Article"}
            </SheetTitle>
            <p className="text-xs text-muted-foreground mt-0.5">
              {isEdit ? "Update the article details below." : "Fill in the details to add a new handbook article."}
            </p>
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

        <Separator />

        {/* Two-column landscape body */}
        <form id="article-form" onSubmit={handleSubmit} className="flex min-h-0 flex-1 overflow-hidden">

          {/* Left — Content */}
          <div className="flex w-1/2 flex-col gap-4 overflow-y-auto border-r px-8 py-6">
            <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Content</p>
            <div className="space-y-1.5">
              <Label htmlFor="title" className="text-sm font-medium">
                Title <span className="text-muted-foreground font-normal">(required)</span>
              </Label>
              <Input id="title" name="title" defaultValue={article?.title ?? ""} placeholder="e.g. Academic Integrity Policy" className="h-9" />
            </div>
            <div className="flex flex-1 flex-col space-y-1.5">
              <Label htmlFor="body_text" className="text-sm font-medium">Body Text</Label>
              <textarea
                id="body_text"
                name="body_text"
                defaultValue={article?.body_text ?? ""}
                placeholder="Write the article content here..."
                className="flex-1 min-h-[220px] w-full rounded-lg border border-input bg-background px-3 py-2.5 text-sm leading-relaxed placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006633]/40 resize-none"
              />
            </div>
            {error && (
              <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}
          </div>

          {/* Right — Structure + Metadata */}
          <div className="flex w-1/2 flex-col gap-6 overflow-y-auto px-8 py-6">
            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Structure</p>
              <div className="grid grid-cols-2 gap-x-4 gap-y-3">
                <div className="space-y-1.5">
                  <Label htmlFor="chapter_id" className="text-sm font-medium">Chapter ID</Label>
                  <Input id="chapter_id" name="chapter_id" defaultValue={article?.chapter_id ?? ""} placeholder="e.g. 1" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="chapter_title" className="text-sm font-medium">Chapter Title</Label>
                  <Input id="chapter_title" name="chapter_title" defaultValue={article?.chapter_title ?? ""} placeholder="e.g. Student Conduct" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="section_id" className="text-sm font-medium">Section ID</Label>
                  <Input id="section_id" name="section_id" defaultValue={article?.section_id ?? ""} placeholder="e.g. 1.1" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="section_title" className="text-sm font-medium">Section Title</Label>
                  <Input id="section_title" name="section_title" defaultValue={article?.section_title ?? ""} placeholder="e.g. Code of Ethics" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="sub_section_id" className="text-sm font-medium">Sub-section ID</Label>
                  <Input id="sub_section_id" name="sub_section_id" defaultValue={article?.sub_section_id ?? ""} placeholder="e.g. 1.1.1" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="sub_section_title" className="text-sm font-medium">Sub-section Title</Label>
                  <Input id="sub_section_title" name="sub_section_title" defaultValue={article?.sub_section_title ?? ""} placeholder="e.g. Definitions" className="h-9" />
                </div>
              </div>
            </div>

            <Separator />

            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Metadata</p>
              <div className="grid grid-cols-2 gap-x-4 gap-y-3">
                <div className="space-y-1.5">
                  <Label htmlFor="content_type" className="text-sm font-medium">Content Type</Label>
                  <Input id="content_type" name="content_type" defaultValue={article?.content_type ?? ""} placeholder="e.g. policy" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="page_approx" className="text-sm font-medium">Page (Approx.)</Label>
                  <Input id="page_approx" name="page_approx" type="number" defaultValue={article?.page_approx ?? ""} placeholder="e.g. 12" className="h-9" />
                </div>
                <div className="col-span-2 space-y-1.5">
                  <Label htmlFor="institution" className="text-sm font-medium">Institution</Label>
                  <Input id="institution" name="institution" defaultValue={article?.institution ?? ""} placeholder="e.g. USTP" className="h-9" />
                </div>
              </div>
            </div>
          </div>
        </form>

        <Separator />

        {/* Footer */}
        <div className="flex items-center justify-end gap-2 px-8 py-4 shrink-0">
          <Button type="button" variant="outline" onClick={() => setOpen(false)} className="h-9 px-5 text-sm">
            Cancel
          </Button>
          <Button type="submit" form="article-form" disabled={isPending} className="h-9 px-5 text-sm bg-[#006633] hover:bg-[#005229] text-white">
            {isPending ? "Saving..." : isEdit ? "Save Changes" : "Create Article"}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}

export function DeleteArticleButton({ id }: { id: string }) {
  const [confirm, setConfirm] = useState(false)
  const [isPending, startTransition] = useTransition()

  function handleClick() {
    if (!confirm) {
      setConfirm(true)
      setTimeout(() => setConfirm(false), 3000)
      return
    }
    startTransition(async () => {
      await deleteArticle(id)
    })
  }

  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={handleClick}
      disabled={isPending}
      className={`h-7 text-xs transition-colors ${
        confirm ? "bg-red-50 text-red-600 hover:bg-red-100" : "text-muted-foreground hover:text-destructive"
      }`}
    >
      {isPending ? "Deleting..." : confirm ? "Confirm?" : "Delete"}
    </Button>
  )
}
