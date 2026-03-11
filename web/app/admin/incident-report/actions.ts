"use server"

import { revalidatePath } from "next/cache"
import { createAdminClient } from "@/lib/supabase/server"
import type { IncidentStatus } from "@/lib/supabase/types"

export async function updateIncidentStatus(id: string, status: IncidentStatus) {
  const supabase = await createAdminClient()
  const { error } = await supabase
    .from("incident_reports")
    .update({ status })
    .eq("id", id)

  if (error) return { error: error.message }
  revalidatePath("/admin/incident-report")
  return { success: true }
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
