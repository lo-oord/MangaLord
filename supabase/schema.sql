create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  photo_url text,
  bio text,
  updated_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  manga_id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, manga_id)
);

create table if not exists public.history (
  user_id uuid not null references auth.users(id) on delete cascade,
  manga_id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, manga_id)
);

alter table public.profiles enable row level security;
alter table public.favorites enable row level security;
alter table public.history enable row level security;

create policy "users manage own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "users manage own favorites" on public.favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "users manage own history" on public.history for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- The app uploads to profile-images/{auth.uid()}/..., and must never access another user's objects.
create policy "users read own profile images" on storage.objects for select to authenticated
  using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "users upload own profile images" on storage.objects for insert to authenticated
  with check (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "users update own profile images" on storage.objects for update to authenticated
  using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = (select auth.uid()::text));
