"use client"

import Image from "next/image"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { logout } from "@/app/auth/actions"

const navItems = [
  {
    title: "Dashboard",
    href: "/admin/dashboard",
    icon: "D",
  },
  {
    title: "Handbook",
    href: "/admin/handbook",
    icon: "H",
  },
  {
    title: "Article Analytics",
    href: "/admin/article-analytics",
    icon: "A",
  },
  {
    title: "Incident Report",
    href: "/admin/incident-report",
    icon: "I",
  },
  {
    title: "Lost and Found",
    href: "/admin/lost-and-found",
    icon: "L",
  },
]

export function AppSidebar() {
  const pathname = usePathname()

  return (
    <Sidebar>
      <SidebarHeader className="px-4 pt-6 pb-4">
        <div className="flex w-full items-center justify-center">
          <Image
            src="/images/logo.svg"
            alt="GuideU"
            width={140}
            height={40}
            priority
            className="h-10 w-auto max-w-[9.5rem] object-contain brightness-0 invert"
          />
        </div>
      </SidebarHeader>

      <SidebarSeparator className="bg-white/20" />

      <SidebarContent className="px-2 py-3">
        <SidebarGroup>
          <SidebarGroupContent>
            <SidebarMenu className="gap-1">
              {navItems.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(item.href + "/")
                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton
                      render={<Link href={item.href} />}
                      isActive={isActive}
                      className="h-10 rounded-lg px-3 text-white/80 hover:bg-white/15 hover:text-white data-[active=true]:bg-white data-[active=true]:text-[#006633] data-[active=true]:font-semibold"
                    >
                      <span className="inline-flex h-5 w-5 items-center justify-center rounded bg-white/10 text-[11px] font-semibold">
                        {item.icon}
                      </span>
                      <span className="text-sm">{item.title}</span>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                )
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="px-3 pb-4">
        <SidebarSeparator className="mb-3 bg-white/20" />
        <SidebarMenu>
          <SidebarMenuItem>
            <DropdownMenu>
              <DropdownMenuTrigger
                render={
                  <SidebarMenuButton
                    size="lg"
                    className="h-12 rounded-lg px-3 text-white/80 hover:bg-white/15 hover:text-white"
                  />
                }
              >
                <Avatar className="h-7 w-7 shrink-0">
                  <AvatarImage src="" alt="Admin" />
                  <AvatarFallback className="bg-white/20 text-white text-xs font-medium">AD</AvatarFallback>
                </Avatar>
                <div className="flex min-w-0 flex-col">
                  <span className="truncate text-sm font-medium text-white">Admin User</span>
                  <span className="truncate text-xs text-white/60">admin@guideu.com</span>
                </div>
                <span className="ml-auto text-sm text-white/60">^</span>
              </DropdownMenuTrigger>
              <DropdownMenuContent side="top" align="start" className="w-56">
                <DropdownMenuItem
                  render={<Link href="/admin/profile" />}
                  className="flex items-center gap-2"
                >
                  <span className="inline-flex h-4 w-4 items-center justify-center text-[10px] font-semibold">P</span>
                  <span>Profile</span>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="p-0">
                  <form action={logout} className="w-full">
                    <button
                      type="submit"
                      className="flex w-full items-center gap-2 px-2 py-1 text-xs text-destructive"
                    >
                      <span className="inline-flex h-4 w-4 items-center justify-center text-[10px] font-semibold">X</span>
                      <span>Sign out</span>
                    </button>
                  </form>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  )
}

