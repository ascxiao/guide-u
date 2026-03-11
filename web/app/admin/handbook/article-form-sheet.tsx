"use client"

import { useState, useTransition } from "react"
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { createArticle, updateArticle, deleteArticle } from "./actions"
import type { Article } from "@/lib/supabase/types"

/* ─────────────────────────────────────────────
   New / Edit article sheet
───────────────────────────────────────────── */
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
    <Button size="sm" className="bg-[#006633] hover:bg-[#005229] text-white h-8 text-xs" />
  )

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={trigger ? <span className="cursor-pointer" /> : triggerEl}>
        {trigger ?? (isEdit ? "Edit" : "+ New Article")}
      </SheetTrigger>

      <SheetContent side="right" className="w-full sm:max-w-xl overflow-y-auto">
        <SheetHeader className="mb-5">
          <SheetTitle className="text-base font-semibold">
            {isEdit ? "Edit Article" : "New Article"}
          </SheetTitle>
        </SheetHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Title */}
          <div className="space-y-1.5">
            <Label htmlFor="title" className="text-xs font-medium">Title</Label>
            <Input
              id="title"
              name="title"
              defaultValue={article?.title ?? ""}
              placeholder="Article title"
              className="text-sm"
            />
          </div>

          {/* Body text */}
          <div className="space-y-1.5">
            <Label htmlFor="body_text" className="text-xs font-medium">Body Text</Label>
            <textarea
              id="body_text"
              name="body_text"
              defaultValue={article?.body_text ?? ""}
              placeholder="Article content..."
              rows={6}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-y"
            />
          </div>

          {/* Chapter */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="chapter_id" className="text-xs font-medium">Chapter ID</Label>
              <Input
                id="chapter_id"
                name="chapter_id"
                defaultValue={article?.chapter_id ?? ""}
                placeholder="e.g. 1"
                className="text-sm"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="chapter_title" className="text-xs font-medium">Chapter Title</Label>
              <Input
                id="chapter_title"
                name="chapter_title"
                defaultValue={article?.chapter_title ?? ""}
                placeholder="Chapter name"
                className="text-sm"
              />
            </div>
          </div>

          {/* Section */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="section_id" className="text-xs font-medium">Section ID</Label>
              <Input
                id="section_id"
                name="section_id"
                defaultValue={article?.section_id ?? ""}
                placeholder="e.g. 1.1"
                className="text-sm"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="section_title" className="text-xs font-medium">Section Title</Label>
              <Input
                id="section_title"
                name="section_title"
                defaultValue={article?.section_title ?? ""}
                placeholder="Section name"
                className="text-sm"
              />
            </div>
          </div>

          {/* Sub-section */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="sub_section_id" className="text-xs font-medium">Sub-section ID</Label>
              <Input
                id="sub_section_id"
                name="sub_section_id"
                defaultValue={article?.sub_section_id ?? ""}
                placeholder="e.g. 1.1.1"
                className="text-sm"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="sub_section_title" className="text-xs font-medium">Sub-section Title</Label>
              <Input
                id="sub_section_title"
                name="sub_section_title"
                defaultValue={article?.sub_section_title ?? ""}
                placeholder="Sub-section name"
                className="text-sm"
              />
            </div>
          </div>

          {/* Meta */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="content_type" className="text-xs font-medium">Content Type</Label>
              <Input
                id="content_type"
                name="content_type"
                defaultValue={article?.content_type ?? ""}
                placeholder="e.g. policy, procedure"
                className="text-sm"
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="page_approx" className="text-xs font-medium">Page (Approx.)</Label>
              <Input
                id="page_approx"
                name="page_approx"
                type="number"
                defaultValue={article?.page_approx ?? ""}
                placeholder="Page number"
                className="text-sm"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="institution" className="text-xs font-medium">Institution</Label>
            <Input
              id="institution"
              name="institution"
              defaultValue={article?.institution ?? ""}
              placeholder="e.g. University of Example"
              className="text-sm"
            />
          </div>

          {error && (
            <p className="rounded-md bg-destructive/10 px-3 py-2 text-xs text-destructive">
              {error}
            </p>
          )}

          <div className="flex gap-2 pt-2">
            <Button
              type="submit"
              disabled={isPending}
              className="bg-[#006633] hover:bg-[#005229] text-white text-sm"
            >
              {isPending ? "Saving…" : isEdit ? "Save Changes" : "Create Article"}
            </Button>
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
              className="text-sm"
            >
              Cancel
            </Button>
          </div>
        </form>
      </SheetContent>
    </Sheet>
  )
}

/* ─────────────────────────────────────────────
   Delete article button with confirm state
───────────────────────────────────────────── */
export function DeleteArticleButton({ id }: { id: string }) {
  const [confirm, setConfirm] = useState(false)
  const [isPending, startTransition] = useTransition()

  function handleClick() {
    if (!confirm) {
      setConfirm(true)
      // Auto-reset confirm state after 3 seconds
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
        confirm
          ? "bg-red-50 text-red-600 hover:bg-red-100"
          : "text-muted-foreground hover:text-destructive"
      }`}
    >
      {isPending ? "Deleting…" : confirm ? "Confirm?" : "Delete"}
    </Button>
  )
}
