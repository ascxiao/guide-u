import { NextRequest, NextResponse } from "next/server"
import { createAdminClient } from "@/lib/supabase/server"
import {
  sendIncidentCreatedEmail,
  sendLostFoundCreatedEmail,
  sendStatusChangeEmail,
} from "@/lib/email/status-notifier"

type ReportObserverEvent = {
  type?: "INSERT" | "UPDATE" | "DELETE" | string
  table?: string
  schema?: string
  record?: Record<string, unknown>
  old_record?: Record<string, unknown> | null
}

const DEFAULT_NOTIFY_EMAIL = "usls.projectdigitalization@gmail.com"

function looksLikeEmail(value: string | null) {
  if (!value) return false
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

function statusLabel(status: string | null) {
  if (!status) return "Unknown"
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())
}

async function getRecipientEmail(userId: string | null) {
  if (!userId) return null
  const supabase = await createAdminClient()
  const { data, error } = await supabase.auth.admin.getUserById(userId)
  if (error) return null
  return data.user?.email ?? null
}

export async function POST(request: NextRequest) {
  const configuredSecret = process.env.REPORT_OBSERVER_SECRET
  const requestSecret = request.headers.get("x-report-observer-secret")

  if (configuredSecret && requestSecret !== configuredSecret) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
  }

  const event = (await request.json()) as ReportObserverEvent
  const type = (event.type ?? "").toUpperCase()
  const table = event.table ?? ""
  const record = event.record ?? {}
  const oldRecord = event.old_record ?? null

  try {
    const notifyEmail = process.env.REPORT_CREATED_NOTIFICATION_EMAIL ?? DEFAULT_NOTIFY_EMAIL

    if (type === "INSERT" && table === "incident_reports") {
      await sendIncidentCreatedEmail({
        to: notifyEmail,
        title: String(record.title ?? ""),
        description: String(record.description ?? ""),
        location: String(record.location ?? ""),
        reporterStudentId: String(record.reporter_student_id ?? ""),
        reporterEmail: String(record.reporter_email ?? ""),
        imageCount: Array.isArray(record.image_urls) ? record.image_urls.length : 0,
      })

      return NextResponse.json({ ok: true })
    }

    if (type === "INSERT" && table === "lost_found_reports") {
      await sendLostFoundCreatedEmail({
        to: notifyEmail,
        itemName: String(record.item_name ?? ""),
        reportType: String(record.report_type ?? ""),
        description: String(record.description ?? ""),
        location: String(record.location ?? ""),
        reporterStudentId: String(record.reporter_student_id ?? ""),
        reporterEmail: String(record.reporter_email ?? ""),
        imageCount: Array.isArray(record.image_urls) ? record.image_urls.length : 0,
      })

      return NextResponse.json({ ok: true })
    }

    if (type === "UPDATE" && (table === "incident_reports" || table === "lost_found_reports")) {
      const newStatus = String(record.status ?? "")
      const oldStatus = String((oldRecord?.status ?? "") as string)

      if (newStatus && newStatus !== oldStatus) {
        const directReporterEmail = String(record.reporter_email ?? "").trim()
        const recipientEmail = looksLikeEmail(directReporterEmail)
          ? directReporterEmail
          : await getRecipientEmail(String(record.user_id ?? "") || null)

        if (recipientEmail) {
          await sendStatusChangeEmail({
            to: recipientEmail,
            reportKind: table === "incident_reports" ? "incident" : "lost_found",
            reportTitle:
              table === "incident_reports"
                ? String(record.title ?? "Untitled")
                : String(record.item_name ?? "Unnamed"),
            newStatus,
          })
        }
      }

      return NextResponse.json({ ok: true, status: statusLabel(newStatus) })
    }

    return NextResponse.json({ ok: true, ignored: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to process observer event"
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
