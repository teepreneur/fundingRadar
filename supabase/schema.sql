-- Funding Radar: one locked table. Only confirmed accounts whose email is listed in fr_owners can read or write.
create table public.fr_owners (email text primary key);
alter table public.fr_owners enable row level security;
revoke all on public.fr_owners from anon, authenticated;

create table public.fr_docs (
  collection text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);
alter table public.fr_docs enable row level security;
revoke all on public.fr_docs from anon;
grant select, insert, update, delete on public.fr_docs to authenticated;

create function public.fr_is_owner() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from auth.users u
    join public.fr_owners o on lower(o.email) = lower(u.email)
    where u.id = (select auth.uid()) and u.email_confirmed_at is not null
  );
$$;
revoke all on function public.fr_is_owner() from public, anon;
grant execute on function public.fr_is_owner() to authenticated;

create policy fr_docs_owner_only on public.fr_docs
  for all to authenticated
  using ((select public.fr_is_owner()))
  with check ((select public.fr_is_owner()));

create function public.fr_patch(p_collection text, p_id text, p_patch jsonb) returns integer
language plpgsql security invoker set search_path = ''
as $$
declare n integer;
begin
  update public.fr_docs set data = data || p_patch, updated_at = now()
   where collection = p_collection and id = p_id;
  get diagnostics n = row_count;
  return n;
end;
$$;
revoke all on function public.fr_patch(text, text, jsonb) from public, anon;
grant execute on function public.fr_patch(text, text, jsonb) to authenticated;
