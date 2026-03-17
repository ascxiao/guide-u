import { createServerClient } from "@supabase/ssr"
import { createClient as createSupabaseClient } from "@supabase/supabase-js"
import { cookies } from "next/headers"

/**
 * Server-component / Route-handler Supabase client.
 * Reads cookies so the user's session is available server-side.
 * Uses the anon key — subject to Row Level Security.
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // setAll is called from a Server Component where cookies cannot be
            // mutated. The middleware handles the refresh, so this is safe to ignore.
          }
        },
      },
    }
  )
}

/**
 * Admin / service-role client — bypasses Row Level Security.
 * Use ONLY in trusted server-side code (Server Actions, Route Handlers).
 * ⚠️  Never import this in client components.
 */
export async function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false, autoRefreshToken: false } }
  )
}
