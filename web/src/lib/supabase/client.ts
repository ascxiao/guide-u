import { createBrowserClient } from "@supabase/ssr"

/**
 * Browser / client-component Supabase client.
 * Uses the anon key — subject to Row Level Security.
 *
 * Create a fresh instance per call so it is never shared across requests.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
