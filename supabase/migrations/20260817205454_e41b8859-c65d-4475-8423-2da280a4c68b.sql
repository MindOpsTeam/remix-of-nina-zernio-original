create or replace function public.bootstrap_current_user(_full_name text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
begin
  if _uid is null then
    raise exception 'not authenticated';
  end if;

  insert into public.profiles (user_id, full_name)
  values (_uid, nullif(_full_name, ''))
  on conflict (user_id) do nothing;

  if not exists (select 1 from public.user_roles where user_id = _uid) then
    if not exists (select 1 from public.user_roles where role = 'admin') then
      insert into public.user_roles (user_id, role) values (_uid, 'admin');
    else
      insert into public.user_roles (user_id, role) values (_uid, 'user');
    end if;
  end if;
end;
$$;

revoke all on function public.bootstrap_current_user(text) from public, anon;
grant execute on function public.bootstrap_current_user(text) to authenticated;