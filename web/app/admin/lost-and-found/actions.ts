"use server"

import { revalidatePath } from "next/cache"
import { createAdminClient } from "@/lib/supabase/server"
import type { LostFoundStatus } from "@/lib/supabase/types"

export async function updateLostFoundStatus(id: string, status: LostFoundStatus) {
  const supabase = await createAdminClient()
  const { error } = await supabase
    .from("lost_found_reports")
    .update({ status })
    .eq("id", id)

  if (error) return { error: error.message }
  revalidatePath("/admin/lost-and-found")
  return { success: true }
}

/**
 * Generate short-lived signed URLs for private lost & found images.
 */
export async function getLostFoundSignedUrls(imagePaths: string[]): Promise<string[]> {
  if (!imagePaths.length) return []

  const supabase = await createAdminClient()
  const { data, error } = await supabase.storage
    .from("lost-found-images")
    .createSignedUrls(imagePaths, 3600)

  if (error || !data) return []
  return data.map((d) => d.signedUrl).filter(Boolean) as string[]
}
