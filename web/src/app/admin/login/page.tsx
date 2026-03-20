"use client"

import { useActionState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
import { login } from "@/app/auth/actions"

export default function AdminLoginPage() {
  const [state, action, isPending] = useActionState(
    async (_prev: { error?: string } | null, formData: FormData) => {
      return (await login(formData)) ?? null
    },
    null
  )

  return (
    <div className="flex min-h-svh items-center justify-center bg-[#006633]/5 px-4">
      <div className="w-full max-w-sm space-y-6">
        <div className="flex flex-col items-center gap-2">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-[#006633]">
            <span className="text-lg font-bold text-white">G</span>
          </div>
          <div className="text-center">
            <h1 className="text-xl font-semibold text-foreground">GuideU Admin</h1>
            <p className="text-sm text-muted-foreground">Sign in to your account</p>
          </div>
        </div>

        <Card className="bg-white border shadow-sm">
          <CardHeader className="pb-4">
            <CardTitle className="text-base font-semibold">Sign in</CardTitle>
            <CardDescription className="text-xs">
              Enter your credentials to access the admin portal.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form action={action} className="space-y-4">
              <div className="space-y-1.5">
                <Label htmlFor="email" className="text-sm font-medium">
                  Email address
                </Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="admin@guideu.com"
                  autoComplete="email"
                  required
                  className="h-10"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="password" className="text-sm font-medium">
                  Password
                </Label>
                <Input
                  id="password"
                  name="password"
                  type="password"
                  placeholder="••••••••"
                  autoComplete="current-password"
                  required
                  className="h-10"
                />
              </div>

              {state?.error && (
                <p className="rounded-md bg-destructive/10 px-3 py-2 text-xs text-destructive">
                  {state.error}
                </p>
              )}

              <Button
                type="submit"
                disabled={isPending}
                className="w-full h-10 bg-[#006633] text-white hover:bg-[#005229] font-medium"
              >
                {isPending ? "Signing in..." : "Sign in"}
              </Button>
            </form>
          </CardContent>
        </Card>

        <p className="text-center text-xs text-muted-foreground">
          GuideU &copy; {new Date().getFullYear()}. All rights reserved.
        </p>
      </div>
    </div>
  )
}
