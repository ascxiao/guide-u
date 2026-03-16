// ──────────────────────────────────────────────────
// Shared TypeScript types matching the Supabase schema
// ──────────────────────────────────────────────────

export type IncidentStatus = "pending" | "under_review" | "resolved" | "closed"
export type LostFoundStatus = "open" | "under_review" | "resolved" | "closed"
export type ReportType = "lost" | "found"

export interface IncidentReport {
  id: string
  user_id: string | null
  reporter_student_id: string | null
  reporter_email: string | null
  title: string | null
  description: string | null
  location: string | null
  status: IncidentStatus
  image_urls: string[]
  created_at: string
}

export interface LostFoundReport {
  id: string
  user_id: string | null
  reporter_student_id: string | null
  reporter_email: string | null
  item_name: string | null
  description: string | null
  location: string | null
  report_type: ReportType | null
  status: LostFoundStatus
  image_urls: string[]
  created_at: string
}

export interface Article {
  id: string
  chapter_id: string | null
  chapter_title: string | null
  section_id: string | null
  section_title: string | null
  sub_section_id: string | null
  sub_section_title: string | null
  title: string | null
  body_text: string | null
  content_type: string | null
  page_approx: number | null
  institution: string | null
  created_at: string
  updated_at: string
}
