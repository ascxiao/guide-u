"use server"

import { revalidatePath } from "next/cache"
import { createAdminClient } from "@/lib/supabase/server"

export async function createArticle(formData: FormData) {
  const supabase = await createAdminClient()

  const payload = {
    chapter_id: (formData.get("chapter_id") as string) || null,
    chapter_title: (formData.get("chapter_title") as string) || null,
    section_id: (formData.get("section_id") as string) || null,
    section_title: (formData.get("section_title") as string) || null,
    sub_section_id: (formData.get("sub_section_id") as string) || null,
    sub_section_title: (formData.get("sub_section_title") as string) || null,
    title: (formData.get("title") as string) || null,
    body_text: (formData.get("body_text") as string) || null,
    content_type: (formData.get("content_type") as string) || null,
    page_approx: formData.get("page_approx") ? Number(formData.get("page_approx")) : null,
    institution: (formData.get("institution") as string) || null,
  }

  const { error } = await supabase.from("articles").insert(payload)
  if (error) return { error: error.message }

  revalidatePath("/admin/handbook")
  return { success: true }
}

export async function updateArticle(id: string, formData: FormData) {
  const supabase = await createAdminClient()

  const payload = {
    chapter_id: (formData.get("chapter_id") as string) || null,
    chapter_title: (formData.get("chapter_title") as string) || null,
    section_id: (formData.get("section_id") as string) || null,
    section_title: (formData.get("section_title") as string) || null,
    sub_section_id: (formData.get("sub_section_id") as string) || null,
    sub_section_title: (formData.get("sub_section_title") as string) || null,
    title: (formData.get("title") as string) || null,
    body_text: (formData.get("body_text") as string) || null,
    content_type: (formData.get("content_type") as string) || null,
    page_approx: formData.get("page_approx") ? Number(formData.get("page_approx")) : null,
    institution: (formData.get("institution") as string) || null,
    updated_at: new Date().toISOString(),
  }

  const { error } = await supabase.from("articles").update(payload).eq("id", id)
  if (error) return { error: error.message }

  revalidatePath("/admin/handbook")
  return { success: true }
}

export async function deleteArticle(id: string) {
  const supabase = await createAdminClient()
  const { error } = await supabase.from("articles").delete().eq("id", id)
  if (error) return { error: error.message }

  revalidatePath("/admin/handbook")
  return { success: true }
}
