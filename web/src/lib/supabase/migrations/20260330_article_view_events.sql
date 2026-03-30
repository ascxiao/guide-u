create table if not exists article_view_events (
    id uuid primary key default uuid_generate_v4(),
    article_id uuid not null references articles(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    source text default 'mobile_app',
    opened_at timestamp with time zone default now()
);

create index if not exists idx_article_view_events_article
    on article_view_events(article_id);

create index if not exists idx_article_view_events_user
    on article_view_events(user_id);

create index if not exists idx_article_view_events_opened_at
    on article_view_events(opened_at desc);

alter table article_view_events enable row level security;

drop policy if exists "Users can create own article view events" on article_view_events;
create policy "Users can create own article view events"
on article_view_events for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read own article view events" on article_view_events;
create policy "Users can read own article view events"
on article_view_events for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Admins can manage all article view events" on article_view_events;
create policy "Admins can manage all article view events"
on article_view_events for all to authenticated
using (
    exists (select 1 from admins where admins.user_id = auth.uid())
)
with check (
    exists (select 1 from admins where admins.user_id = auth.uid())
);
