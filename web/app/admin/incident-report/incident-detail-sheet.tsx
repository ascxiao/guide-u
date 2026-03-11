"use client"

import { useState, useTransition } from "react"
import {
  Sheet,
  SheetContent,
  SheetHeader,
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

        <SheetContent side="right" className="w-full sm:max-w-lg overflow-y-auto">
          <SheetHeader className="mb-4">
            <SheetTitle className="text-base font-semibold leading-tight">
              {report.title ?? "Untitled Report"}
            </SheetTitle>
          </SheetHeader>

          <div className="space-y-5">
            {/* Status updater */}
            <div className="flex items-center justify-between rounded-lg border bg-muted/30 px-4 py-3">
              <span className="text-xs font-medium text-muted-foreground">Status</span>
              <Select value={currentStatus} onValueChange={handleStatusChange}>
                <SelectTrigger className="w-36">
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
                <HugeiconsIcon icon={Loading01Icon} size={14} className="ml-2 animate-spin text-muted-foreground" />
              )}
            </div>

            {/* Meta */}
            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-lg border bg-background p-3">
                <p className="text-xs text-muted-foreground">Location</p>
                <p className="mt-0.5 text-sm font-medium">{report.location ?? "—"}</p>
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

            {/* Description */}
            <div className="rounded-lg border bg-background p-4">
              <p className="mb-2 text-xs font-medium text-muted-foreground uppercase tracking-wide">Description</p>
              <p className="text-sm leading-relaxed text-foreground">
                {report.description ?? "No description provided."}
              </p>
            </div>

            {/* Images */}
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
