"use client"

import { useState, useTransition } from "react"
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { HugeiconsIcon } from "@hugeicons/react"
import { EyeIcon, Image01Icon, Loading01Icon } from "@hugeicons/core-free-icons"
import { getIncidentSignedUrls, updateIncidentStatus } from "./actions"
import type { IncidentReport, IncidentStatus } from "@/lib/supabase/types"

const STATUS_OPTIONS: { value: IncidentStatus; label: string }[] = [
  { value: "pending", label: "Pending" },
  { value: "under_review", label: "Under Review" },
  { value: "resolved", label: "Resolved" },
  { value: "closed", label: "Closed" },
]

const STATUS_CLASSES: Record<IncidentStatus, string> = {
  pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
  under_review: "bg-blue-100 text-blue-800 border-blue-200",
  resolved: "bg-green-100 text-green-800 border-green-200",
  closed: "bg-gray-100 text-gray-600 border-gray-200",
}

export function StatusBadge({ status }: { status: IncidentStatus }) {
  const label = STATUS_OPTIONS.find((s) => s.value === status)?.label ?? status
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2 py-0.5 text-xs font-medium ${STATUS_CLASSES[status]}`}
    >
      {label}
    </span>
  )
}

export function IncidentDetailSheet({ report }: { report: IncidentReport }) {
  const [open, setOpen] = useState(false)
  const [imageUrls, setImageUrls] = useState<string[]>([])
  const [imagesLoading, setImagesLoading] = useState(false)
  const [currentStatus, setCurrentStatus] = useState<IncidentStatus>(report.status)
  const [isPending, startTransition] = useTransition()
  const [lightbox, setLightbox] = useState<string | null>(null)

  function handleOpen(isOpen: boolean) {
    setOpen(isOpen)
    if (isOpen && report.image_urls.length > 0 && imageUrls.length === 0) {
      setImagesLoading(true)
      getIncidentSignedUrls(report.image_urls).then((urls) => {
        setImageUrls(urls)
        setImagesLoading(false)
      })
    }
  }

  function handleStatusChange(value: string | null) {
    if (!value) return
    const newStatus = value as IncidentStatus
    setCurrentStatus(newStatus)
    startTransition(async () => {
      await updateIncidentStatus(report.id, newStatus)
    })
  }

  return (
    <>
      <Sheet open={open} onOpenChange={handleOpen}>
        <SheetTrigger
          render={
            <Button variant="ghost" size="sm" className="h-7 gap-1.5 text-xs" />
          }
        >
          <HugeiconsIcon icon={EyeIcon} size={13} strokeWidth={1.8} />
          View
        </SheetTrigger>

        <SheetContent
          side="center"
          showCloseButton={false}
          className="flex h-fit max-h-[85vh] w-[min(90vw,72rem)] flex-col overflow-hidden rounded-2xl border-0 p-0 shadow-2xl data-starting-style:opacity-0 data-ending-style:opacity-0 data-starting-style:scale-[0.97] data-ending-style:scale-[0.97]"
        >
          <div className="flex items-center justify-between px-8 pt-6 pb-4 shrink-0">
            <div>
              <SheetTitle className="text-lg font-semibold text-foreground">
                {report.title ?? "Untitled Report"}
              </SheetTitle>
              <p className="text-xs text-muted-foreground mt-0.5">
                View report details and update status.
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

          <div className="flex min-h-0 flex-1 overflow-hidden">
            <div className="flex w-1/2 flex-col gap-4 overflow-y-auto border-r px-8 py-6">
              <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Report Details</p>

              <div className="rounded-lg border bg-background p-4">
                <p className="mb-2 text-xs font-medium text-muted-foreground uppercase tracking-wide">Description</p>
                <p className="text-sm leading-relaxed text-foreground whitespace-pre-line">
                  {report.description ?? "No description provided."}
                </p>
              </div>

              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <HugeiconsIcon icon={Image01Icon} size={14} className="text-muted-foreground" strokeWidth={1.8} />
                  <p className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
                    Attached Images ({report.image_urls.length})
                  </p>
                </div>
                {imagesLoading ? (
                  <div className="flex items-center justify-center rounded-lg border bg-muted/30 py-8">
                    <HugeiconsIcon icon={Loading01Icon} size={20} className="animate-spin text-muted-foreground" />
                  </div>
                ) : imageUrls.length > 0 ? (
                  <div className="grid grid-cols-2 gap-2">
                    {imageUrls.map((url, i) => (
                      <button
                        key={i}
                        onClick={() => setLightbox(url)}
                        className="group relative aspect-square overflow-hidden rounded-lg border bg-muted"
                      >
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={url}
                          alt={`Image ${i + 1}`}
                          className="h-full w-full object-cover transition-transform group-hover:scale-105"
                        />
                      </button>
                    ))}
                  </div>
                ) : report.image_urls.length === 0 ? (
                  <p className="rounded-lg border bg-muted/30 py-4 text-center text-xs text-muted-foreground">
                    No images attached
                  </p>
                ) : null}
              </div>
            </div>

            <div className="flex w-1/2 flex-col gap-6 overflow-y-auto px-8 py-6">
              <div className="space-y-3">
                <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Status</p>
                <div className="flex items-center gap-2 rounded-lg border bg-muted/30 px-4 py-3">
                  <Select value={currentStatus} onValueChange={handleStatusChange}>
                    <SelectTrigger className="w-44">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {STATUS_OPTIONS.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>
                          {opt.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {isPending && (
                    <HugeiconsIcon icon={Loading01Icon} size={14} className="animate-spin text-muted-foreground" />
                  )}
                </div>
              </div>

              <Separator />

              <div className="space-y-3">
                <p className="text-[11px] font-semibold uppercase tracking-widest text-muted-foreground">Metadata</p>
                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-lg border bg-background p-3">
                    <p className="text-xs text-muted-foreground">Location</p>
                    <p className="mt-0.5 text-sm font-medium">{report.location ?? "-"}</p>
                  </div>
                  <div className="rounded-lg border bg-background p-3">
                    <p className="text-xs text-muted-foreground">Submitted</p>
                    <p className="mt-0.5 text-sm font-medium">
                      {new Date(report.created_at).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </p>
                  </div>
                </div>

                {(report.reporter_student_id || report.reporter_email) && (
                  <div className="rounded-lg border bg-background p-3 space-y-1">
                    {report.reporter_student_id && (
                      <p className="text-xs text-muted-foreground">Student ID: <span className="text-foreground">{report.reporter_student_id}</span></p>
                    )}
                    {report.reporter_email && (
                      <p className="text-xs text-muted-foreground">Email: <span className="text-foreground">{report.reporter_email}</span></p>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>

          <Separator />

          <div className="flex items-center justify-end gap-2 px-8 py-4 shrink-0">
            <Button type="button" variant="outline" onClick={() => setOpen(false)} className="h-9 px-5 text-sm">
              Close
            </Button>
          </div>
        </SheetContent>
      </Sheet>

      {/* Lightbox */}
      {lightbox && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/90 p-4"
          onClick={() => setLightbox(null)}
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={lightbox}
            alt="Full size"
            className="max-h-full max-w-full rounded-lg object-contain"
          />
        </div>
      )}
    </>
  )
}
