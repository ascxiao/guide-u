-- ===============================
-- EXTENSIONS
-- ===============================
create extension if not exists vector;
create extension if not exists "uuid-ossp";


-- ===============================
-- ARTICLES (Student Handbook)
-- ===============================
create table articles (
    id uuid primary key default uuid_generate_v4(),
    chapter_id text,
    chapter_title text,
    section_id text,
    section_title text,
    sub_section_id text,
    sub_section_title text,
    title text,
    body_text text,
    content_type text,
    page_approx integer,
    institution text,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);


-- ===============================
-- ARTICLE EMBEDDINGS (Vector DB)
-- ===============================
create table article_embeddings (
    id uuid primary key default uuid_generate_v4(),
    article_id uuid references articles(id) on delete cascade,
    chunk_text text,
    embedding vector(1536),
    created_at timestamp with time zone default now()
);


-- ===============================
-- SAVED ARTICLES
-- ===============================
create table saved_articles (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    article_id uuid references articles(id) on delete cascade,
    created_at timestamp with time zone default now(),
    unique(user_id, article_id)
);


-- ===============================
-- INCIDENT REPORTS
-- ===============================
create table incident_reports (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id),
    reporter_student_id text,
    reporter_email text,
    title text,
    description text,
    location text,
    status text default 'pending',
    image_urls text[] default '{}',
    created_at timestamp with time zone default now()
);


-- ===============================
-- LOST AND FOUND REPORTS
-- ===============================
create table lost_found_reports (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id),
    reporter_student_id text,
    reporter_email text,
    item_name text,
    description text,
    location text,
    report_type text,
    status text default 'open',
    image_urls text[] default '{}',
    created_at timestamp with time zone default now()
);


-- ===============================
-- CHATBOT MESSAGES
-- ===============================
create table chatbot_messages (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id),
    role text,
    message text,
    created_at timestamp with time zone default now()
);


-- ===============================
-- ADMINS
-- ===============================
create table admins (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade,
    role text default 'admin',
    created_at timestamp with time zone default now()
);


-- ===============================
-- INDEXES
-- ===============================
create index idx_articles_section on articles(section_id);
create index idx_saved_articles_user on saved_articles(user_id);
create index idx_incident_reports_user on incident_reports(user_id);
create index idx_lost_found_user on lost_found_reports(user_id);
create index article_embeddings_idx on article_embeddings
    using ivfflat (embedding vector_cosine_ops);


-- ===============================
-- STORAGE BUCKETS
-- ===============================
do $$
begin
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'incident-report-images',
    'incident-report-images',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  ) on conflict (id) do nothing;

  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'lost-found-images',
    'lost-found-images',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  ) on conflict (id) do nothing;
end $$;


-- ===============================
-- STORAGE POLICIES: INCIDENT IMAGES
-- ===============================
create policy "Users can upload own incident images"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'incident-report-images'
    and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users can view own incident images"
on storage.objects for select to authenticated
using (
    bucket_id = 'incident-report-images'
    and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Users can delete own incident images"
on storage.objects for delete to authenticated
using (
    bucket_id = 'incident-report-images'
    and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Admins can view all incident images"
on storage.objects for select to authenticated
using (
    bucket_id = 'incident-report-images'
    and exists (select 1 from admins where admins.user_id = auth.uid())
);

create policy "Admins can delete any incident image"
on storage.objects for delete to authenticated
using (
    bucket_id = 'incident-report-images'
    and exists (select 1 from admins where admins.user_id = auth.uid())
);


-- ===============================
-- STORAGE POLICIES: LOST & FOUND IMAGES
-- ===============================
create policy "Users can upload own lost-found images"
on storage.objects for insert to authenticated
with check (
    bucket_id = 'lost-found-images'
    and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Authenticated users can view all lost-found images"
on storage.objects for select to authenticated
using (
    bucket_id = 'lost-found-images'
);

create policy "Users can delete own lost-found images"
on storage.objects for delete to authenticated
using (
    bucket_id = 'lost-found-images'
    and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Admins can delete any lost-found image"
on storage.objects for delete to authenticated
using (
    bucket_id = 'lost-found-images'
    and exists (select 1 from admins where admins.user_id = auth.uid())
);