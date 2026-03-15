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
import { createLostFoundReport } from "./actions"

export function LostFoundFormSheet() {
  const [open, setOpen] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setError(null)
    const formData = new FormData(e.currentTarget)

    startTransition(async () => {
      const result = await createLostFoundReport(formData)
      if (result.error) {
        setError(result.error)
        return
      }
      setOpen(false)
    })
  }

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger render={<Button size="sm" className="bg-[#006633] hover:bg-[#005229] text-white h-8 px-4 text-xs font-medium" />}>
        + Add Report
      </SheetTrigger>

      <SheetContent
        side="center"
        showCloseButton={false}
        className="flex h-fit max-h-[85vh] w-[min(90vw,72rem)] flex-col overflow-hidden rounded-2xl border-0 p-0 shadow-2xl data-starting-style:opacity-0 data-ending-style:opacity-0 data-starting-style:scale-[0.97] data-ending-style:scale-[0.97]"
      >
        <div className="flex items-center justify-between px-8 pt-6 pb-4 shrink-0">
          <div>
            <SheetTitle className="text-lg font-semibold text-foreground">New Lost &amp; Found Report</SheetTitle>
            <p className="text-xs text-muted-foreground mt-0.5">
              Fill in the details to create a lost or found report entry.
            </p>
          </div>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={() => setOpen(false)}
            className="h-8 w-8 p-0 rounded-full text-muted-foreground hover:text-foreground"
          >
            X
          </Button>
        </div>

        <Separator />

        <form id="lost-found-form" onSubmit={handleSubmit} className="flex min-h-0 flex-1 overflow-hidden">
          <div className="flex w-1/2 flex-col gap-4 overflow-y-auto border-r px-8 py-6">
            <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Item Details</p>

            <div className="space-y-1.5">
              <Label htmlFor="item_name" className="text-sm font-medium">
                Item Name <span className="text-muted-foreground font-normal">(required)</span>
              </Label>
              <Input id="item_name" name="item_name" placeholder="e.g. Blue umbrella" className="h-9" required />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="report_type" className="text-sm font-medium">Report Type</Label>
              <select
                id="report_type"
                name="report_type"
                className="h-9 w-full rounded-md border border-input bg-background px-3 text-sm"
                defaultValue="lost"
              >
                <option value="lost">Lost</option>
                <option value="found">Found</option>
              </select>
            </div>

            <div className="flex flex-1 flex-col space-y-1.5">
              <Label htmlFor="description" className="text-sm font-medium">Description</Label>
              <textarea
                id="description"
                name="description"
                className="flex-1 min-h-[220px] w-full rounded-lg border border-input bg-background px-3 py-2.5 text-sm leading-relaxed placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006633]/40 resize-none"
                placeholder="Add identifying details..."
              />
            </div>

            {error && (
              <div className="rounded-lg border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-destructive">
                {error}
              </div>
            )}
          </div>

          <div className="flex w-1/2 flex-col gap-6 overflow-y-auto px-8 py-6">
            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Reporter Info</p>
              <div className="grid grid-cols-2 gap-x-4 gap-y-3">
                <div className="col-span-2 space-y-1.5">
                  <Label htmlFor="location" className="text-sm font-medium">Location</Label>
                  <Input id="location" name="location" placeholder="e.g. Library Lobby" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="reporter_student_id" className="text-sm font-medium">Reporter Student ID</Label>
                  <Input id="reporter_student_id" name="reporter_student_id" placeholder="Enter student ID" className="h-9" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="reporter_email" className="text-sm font-medium">Reporter Email</Label>
                  <Input id="reporter_email" name="reporter_email" type="email" placeholder="reporter@email.com" className="h-9" />
                </div>
              </div>
              <p className="text-[11px] text-muted-foreground">
                Status update notifications will be sent to this email when provided.
              </p>
            </div>

            <Separator />

            <div className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Attachments</p>
              <div className="space-y-1.5">
                <Label htmlFor="images" className="text-sm font-medium">Images (optional)</Label>
                <Input id="images" name="images" type="file" accept="image/*" multiple className="h-9" />
                <p className="text-[11px] text-muted-foreground">
                  Files will be uploaded to the lost-found-images storage bucket.
                </p>
              </div>
            </div>
          </div>
        </form>

        <Separator />

        <div className="flex items-center justify-end gap-2 px-8 py-4 shrink-0">
          <Button type="button" variant="outline" onClick={() => setOpen(false)} className="h-9 px-5 text-sm">
            Cancel
          </Button>
          <Button type="submit" form="lost-found-form" disabled={isPending} className="h-9 px-5 text-sm bg-[#006633] hover:bg-[#005229] text-white">
            {isPending ? "Saving..." : "Create Report"}
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}