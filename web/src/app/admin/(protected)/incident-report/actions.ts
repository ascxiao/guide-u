"use server"

import { revalidatePath } from "next/cache"
import { createAdminClient } from "@/lib/supabase/server"
import type { IncidentStatus } from "@/lib/supabase/types"
import { sendIncidentCreatedEmail, sendStatusChangeEmail } from "@/lib/email/status-notifier"

const INCIDENT_BUCKET = "incident-report-images"
const INCIDENT_CREATE_NOTIFICATION_EMAIL = "usls.projectdigitalization@gmail.com"
const REPORT_EMAIL_MODE = (process.env.REPORT_EMAIL_MODE ?? "inline").toLowerCase()

function looksLikeEmail(value: string | null) {
  if (!value) return false
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

function looksLikeUuid(value: string | null) {
  if (!value) return false
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

function hasMissingReporterEmailColumnError(error: { message?: string } | null) {
  if (!error?.message) return false
  return /reporter_email|reporter_student_id/i.test(error.message)
}

function sanitizeFileName(fileName: string) {
  return fileName.replace(/[^a-zA-Z0-9._-]/g, "_")
}

async function uploadIncidentImages(userId: string | null, files: File[]) {
  if (!files.length) return []

  const supabase = await createAdminClient()
  const folder = userId || "admin"
  const uploadedPaths: string[] = []

  for (const file of files) {
    if (!file || file.size === 0) continue

    const fileName = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}-${sanitizeFileName(file.name)}`
    const path = `${folder}/${fileName}`
    const buffer = Buffer.from(await file.arrayBuffer())

    const { error } = await supabase.storage
      .from(INCIDENT_BUCKET)
      .upload(path, buffer, { contentType: file.type || "application/octet-stream" })

    if (error) {
      throw new Error(`Image upload failed: ${error.message}`)
    }

    uploadedPaths.push(path)
  }

  return uploadedPaths
}

async function getRecipientEmail(userId: string | null) {
  if (!userId) return null

  const supabase = await createAdminClient()
  const { data, error } = await supabase.auth.admin.getUserById(userId)
  if (error) return null
  return data.user?.email ?? null
}

export async function createIncidentReport(formData: FormData) {
  const supabase = await createAdminClient()

  const userIdRaw = (formData.get("user_id") as string | null)?.trim() || null
  const userId = looksLikeUuid(userIdRaw) ? userIdRaw : null
  const reporterStudentId = (formData.get("reporter_student_id") as string | null)?.trim() || null
  const reporterEmailRaw = (formData.get("reporter_email") as string | null)?.trim() || null
  const reporterEmail = looksLikeEmail(reporterEmailRaw) ? reporterEmailRaw : null
  const title = (formData.get("title") as string | null)?.trim() || null
  const description = (formData.get("description") as string | null)?.trim() || null
  const location = (formData.get("location") as string | null)?.trim() || null
  const images = formData.getAll("images").filter((v): v is File => v instanceof File)

  try {
    const imagePaths = await uploadIncidentImages(userIdRaw, images)

    const payload = {
      user_id: userId,
      reporter_student_id: reporterStudentId,
      reporter_email: reporterEmail,
      title,
      description,
      location,
      status: "pending",
      image_urls: imagePaths,
    }

    let { error } = await supabase.from("incident_reports").insert(payload)

    if (hasMissingReporterEmailColumnError(error)) {
      ;({ error } = await supabase.from("incident_reports").insert({
        user_id: userId,
        title,
        description,
        location,
        status: "pending",
        image_urls: imagePaths,
      }))
    }

    if (error) return { error: error.message }

    if (REPORT_EMAIL_MODE !== "observer") {
      // Keep report creation successful even if notification email fails.
      try {
        await sendIncidentCreatedEmail({
          to: INCIDENT_CREATE_NOTIFICATION_EMAIL,
          title: title ?? "",
          description: description ?? "",
          location: location ?? "",
          reporterStudentId: reporterStudentId ?? "",
          reporterEmail: reporterEmail ?? "",
          imageCount: imagePaths.length,
        })
      } catch {
        // Swallow email errors so report persistence is not blocked.
      }
    }

    revalidatePath("/admin/incident-report")
    return { success: true }
  } catch (error) {
    return { error: error instanceof Error ? error.message : "Failed to create incident report" }
  }
}

export async function updateIncidentStatus(id: string, status: IncidentStatus) {
  const supabase = await createAdminClient()

  let { data: current, error: readError } = await supabase
    .from("incident_reports")
    .select("id, user_id, reporter_email, title, status")
    .eq("id", id)
    .single()

  if (hasMissingReporterEmailColumnError(readError)) {
    ;({ data: current, error: readError } = await supabase
      .from("incident_reports")
      .select("id, user_id, title, status")
      .eq("id", id)
      .single())
  }

  if (readError) return { error: readError.message }
  if (!current) return { error: "Incident report not found" }

  if (current.status === status) {
    return { success: true, emailSent: false }
  }

  const { error } = await supabase
    .from("incident_reports")
    .update({ status })
    .eq("id", id)

  if (error) return { error: error.message }

  const currentReporterEmail = (current as { reporter_email?: string | null }).reporter_email ?? null
  const recipientEmail = looksLikeEmail(currentReporterEmail)
    ? currentReporterEmail
    : await getRecipientEmail(current.user_id)
  if (recipientEmail && REPORT_EMAIL_MODE !== "observer") {
    await sendStatusChangeEmail({
      to: recipientEmail,
      reportKind: "incident",
      reportTitle: current.title ?? "Untitled",
      newStatus: status,
    })
  }

  revalidatePath("/admin/incident-report")
  return { success: true, emailSent: Boolean(recipientEmail) }
}

/**
 * Generate short-lived signed URLs for private incident images.
 * image_urls are stored as paths relative to the bucket root, e.g. "{user_id}/file.jpg"
 */
export async function getIncidentSignedUrls(imagePaths: string[]): Promise<string[]> {
  if (!imagePaths.length) return []

  const supabase = await createAdminClient()
  const { data, error } = await supabase.storage
    .from("incident-report-images")
    .createSignedUrls(imagePaths, 3600)

  if (error || !data) return []
  return data.map((d) => d.signedUrl).filter(Boolean) as string[]
}
