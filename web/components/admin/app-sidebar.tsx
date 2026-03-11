"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { HugeiconsIcon } from "@hugeicons/react"
import {
  DashboardSquare01Icon,
  Book01Icon,
  Alert02Icon,
  Archive01Icon,
  ChevronUp,
  Logout01Icon,
  User02Icon,
} from "@hugeicons/core-free-icons"
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
    icon: DashboardSquare01Icon,
  },
  {
    title: "Handbook",
    href: "/admin/handbook",
    icon: Book01Icon,
  },
  {
    title: "Incident Report",
    href: "/admin/incident-report",
    icon: Alert02Icon,
  },
  {
    title: "Lost and Found",
    href: "/admin/lost-and-found",
    icon: Archive01Icon,
  },
]

export function AppSidebar() {
  const pathname = usePathname()

  return (
    <Sidebar>
      <SidebarHeader className="px-4 py-5">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white/20">
            <span className="text-sm font-bold text-white">G</span>
          </div>
          <div className="flex flex-col">
            <span className="text-sm font-semibold text-white leading-tight">GuideU</span>
            <span className="text-xs text-white/70 leading-tight">Admin Portal</span>
          </div>
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
                      <HugeiconsIcon icon={item.icon} size={18} strokeWidth={1.8} />
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
                <HugeiconsIcon icon={ChevronUp} size={14} className="ml-auto text-white/60" />
              </DropdownMenuTrigger>
              <DropdownMenuContent side="top" align="start" className="w-56">
                <DropdownMenuItem
                  render={<Link href="/admin/profile" />}
                  className="flex items-center gap-2"
                >
                  <HugeiconsIcon icon={User02Icon} size={15} />
                  <span>Profile</span>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem className="p-0">
                  <form action={logout} className="w-full">
                    <button
                      type="submit"
                      className="flex w-full items-center gap-2 px-2 py-1 text-xs text-destructive"
                    >
                      <HugeiconsIcon icon={Logout01Icon} size={15} />
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

