create table if not exists public.site_content (
  section text primary key,
  content jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.admin_users (
  email text primary key,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_site_content_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_site_content_updated_at on public.site_content;

create trigger trg_site_content_updated_at
before update on public.site_content
for each row
execute function public.set_site_content_updated_at();

alter table public.site_content enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Public can read site content" on public.site_content;
create policy "Public can read site content"
on public.site_content
for select
to anon, authenticated
using (true);

drop policy if exists "Allowed admins can write site content" on public.site_content;
create policy "Allowed admins can write site content"
on public.site_content
for all
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where lower(admin_users.email) = lower((select auth.jwt() ->> 'email'))
  )
)
with check (
  exists (
    select 1
    from public.admin_users
    where lower(admin_users.email) = lower((select auth.jwt() ->> 'email'))
  )
);

drop policy if exists "Admins can read admin users" on public.admin_users;
create policy "Admins can read admin users"
on public.admin_users
for select
to authenticated
using (
  lower(email) = lower((select auth.jwt() ->> 'email'))
);

insert into public.admin_users (email)
values
  ('dgarduno@zapata.com'),
  ('clopezc@zapata.com.mx'),
  ('holainnovacion@zapata.com.mx'),
  ('ajuarezd@zapata.com.mx')
on conflict (email) do nothing;
