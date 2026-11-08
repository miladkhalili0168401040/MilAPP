-- Run this in Supabase SQL Editor.
create extension if not exists "pgcrypto";
create table if not exists public.profiles (id uuid primary key references auth.users(id) on delete cascade, username text unique, display_name text, avatar_url text, created_at timestamptz default now());
create table if not exists public.conversations (id uuid primary key default gen_random_uuid(), title text, is_group boolean default false, created_at timestamptz default now());
create table if not exists public.conversation_members (conversation_id uuid references public.conversations(id) on delete cascade, user_id uuid references auth.users(id) on delete cascade, primary key(conversation_id,user_id));
create table if not exists public.messages (id uuid primary key default gen_random_uuid(), conversation_id uuid references public.conversations(id) on delete cascade, sender_id uuid references auth.users(id) on delete cascade, body text not null, created_at timestamptz default now());
alter table public.profiles enable row level security; alter table public.conversations enable row level security; alter table public.conversation_members enable row level security; alter table public.messages enable row level security;
create policy "profiles readable" on public.profiles for select to authenticated using (true);
create policy "own profile insert" on public.profiles for insert to authenticated with check (auth.uid()=id);
create policy "own profile update" on public.profiles for update to authenticated using (auth.uid()=id);
create policy "members readable" on public.conversation_members for select to authenticated using (auth.uid()=user_id);
create policy "messages members read" on public.messages for select to authenticated using (exists(select 1 from public.conversation_members cm where cm.conversation_id=messages.conversation_id and cm.user_id=auth.uid()));
create policy "messages members insert" on public.messages for insert to authenticated with check (auth.uid()=sender_id and exists(select 1 from public.conversation_members cm where cm.conversation_id=messages.conversation_id and cm.user_id=auth.uid()));
alter publication supabase_realtime add table public.messages;
