import { createServerClient } from "@supabase/ssr"
import { NextResponse, type NextRequest } from "next/server"

/**
 * Middleware Supabase client.
 * Runs on every request to refresh the user's auth session before
 * Server Components render. Without this, sessions can expire mid-visit.
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh the session — do NOT add logic between createServerClient and
  // getUser(), as it may cause intermittent auth issues.
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Redirect unauthenticated users away from /admin/* routes
  if (
    !user &&
    request.nextUrl.pathname.startsWith("/admin")
  ) {
    const url = request.nextUrl.clone()
    url.pathname = "/auth/login"
    return NextResponse.redirect(url)
  }

  // Redirect already-authenticated users away from the login page
  if (user && request.nextUrl.pathname === "/auth/login") {
    const url = request.nextUrl.clone()
    url.pathname = "/admin/dashboard"
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
