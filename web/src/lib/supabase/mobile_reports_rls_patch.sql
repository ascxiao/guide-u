-- Apply this patch in Supabase SQL Editor for existing databases.
-- It makes mobile report submission/history work with RLS.

alter table incident_reports enable row level security;
alter table lost_found_reports enable row level security;

-- Incident report table policies

drop policy if exists "Users can create own incident reports" on incident_reports;
create policy "Users can create own incident reports"
on incident_reports for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read own incident reports" on incident_reports;
create policy "Users can read own incident reports"
on incident_reports for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Admins can manage all incident reports" on incident_reports;
create policy "Admins can manage all incident reports"
on incident_reports for all to authenticated
using (
  exists (select 1 from admins where admins.user_id = auth.uid())
)
with check (
  exists (select 1 from admins where admins.user_id = auth.uid())
);

-- Lost and found table policies

drop policy if exists "Users can create own lost_found reports" on lost_found_reports;
create policy "Users can create own lost_found reports"
on lost_found_reports for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read own lost_found reports" on lost_found_reports;
create policy "Users can read own lost_found reports"
on lost_found_reports for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Admins can manage all lost_found reports" on lost_found_reports;
create policy "Admins can manage all lost_found reports"
on lost_found_reports for all to authenticated
using (
  exists (select 1 from admins where admins.user_id = auth.uid())
)
with check (
  exists (select 1 from admins where admins.user_id = auth.uid())
);
