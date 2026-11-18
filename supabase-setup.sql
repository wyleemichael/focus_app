-- 在 Supabase Dashboard → SQL Editor 中运行一次。
-- 每个用户只能读取/修改自己的数据。
create table if not exists public.focus_user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.focus_user_data enable row level security;

revoke all on table public.focus_user_data from anon;
grant select, insert, update, delete on table public.focus_user_data to authenticated;

create policy "focus_read_own" on public.focus_user_data
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "focus_insert_own" on public.focus_user_data
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "focus_update_own" on public.focus_user_data
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "focus_delete_own" on public.focus_user_data
  for delete to authenticated using ((select auth.uid()) = user_id);

create or replace function public.focus_touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists focus_update_timestamp on public.focus_user_data;
create trigger focus_update_timestamp before update on public.focus_user_data
for each row execute function public.focus_touch_updated_at();
