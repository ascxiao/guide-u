import { SidebarProvider, SidebarInset, SidebarTrigger } from "@/components/ui/sidebar"
import { AppSidebar } from "@/components/admin/app-sidebar"
import { Separator } from "@/components/ui/separator"

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset className="bg-background">
        <header className="flex h-14 shrink-0 items-center gap-2 border-b bg-white px-4">
          <SidebarTrigger className="-ml-1 text-[#006633] hover:bg-[#006633]/10 hover:text-[#006633]" />
          <Separator orientation="vertical" className="mr-2 h-4" />
          <span className="text-sm text-muted-foreground font-medium">GuideU Admin</span>
        </header>
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}
