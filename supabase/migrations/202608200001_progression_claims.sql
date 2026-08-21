begin;

create or replace function private.ensure_daily_mission_catalog()
returns void language sql security definer set search_path='' as $$
  insert into public.daily_missions(mission_key,mission_date,target_value,reward_coins,reward_crystals) values
    ('launch_once',current_date,1,150,0),
    ('hit_five',current_date,5,250,0),
    ('upgrade_once',current_date,1,300,1)
  on conflict(mission_key,mission_date) do nothing;
$$;

create or replace function private.track_launch_mission_progress()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  perform private.ensure_daily_mission_catalog();
  insert into public.mission_progress(user_id,mission_id)
    select new.user_id,m.id from public.daily_missions m where m.mission_date=current_date
    on conflict(user_id,mission_id) do nothing;
  update public.mission_progress p set
    progress=least(m.target_value,p.progress+case m.mission_key when 'launch_once' then 1 when 'hit_five' then new.combo else 0 end),
    completed_at=case when p.progress+case m.mission_key when 'launch_once' then 1 when 'hit_five' then new.combo else 0 end>=m.target_value then coalesce(p.completed_at,clock_timestamp()) else p.completed_at end,
    updated_at=clock_timestamp()
  from public.daily_missions m
  where p.mission_id=m.id and p.user_id=new.user_id and m.mission_date=current_date and m.mission_key in('launch_once','hit_five');
  return new;
end $$;

drop trigger if exists launch_result_mission_progress on public.launch_results;
create trigger launch_result_mission_progress after insert on public.launch_results
for each row execute function private.track_launch_mission_progress();

create or replace function private.track_upgrade_mission_progress()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_user uuid;
begin
  perform private.ensure_daily_mission_catalog();
  if new.level<=old.level then return new; end if;
  select i.user_id into v_user from public.islands i where i.id=new.island_id;
  insert into public.mission_progress(user_id,mission_id)
    select v_user,m.id from public.daily_missions m where m.mission_date=current_date
    on conflict(user_id,mission_id) do nothing;
  update public.mission_progress p set progress=m.target_value,completed_at=coalesce(p.completed_at,clock_timestamp()),updated_at=clock_timestamp()
  from public.daily_missions m where p.mission_id=m.id and p.user_id=v_user and m.mission_date=current_date and m.mission_key='upgrade_once';
  return new;
end $$;

drop trigger if exists building_upgrade_mission_progress on public.island_buildings;
create trigger building_upgrade_mission_progress after update of level on public.island_buildings
for each row execute function private.track_upgrade_mission_progress();

create or replace function private.claim_daily_missions(p_idempotency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_existing jsonb; v_coins integer:=0; v_crystals integer:=0; v_count integer:=0;
begin
  perform private.ensure_daily_mission_catalog();
  select response into v_existing from private.idempotency_keys where user_id=v_user and operation='claim_daily_missions' and idempotency_key=p_idempotency;
  if found then return v_existing; end if;
  insert into public.mission_progress(user_id,mission_id)
    select v_user,m.id from public.daily_missions m where m.mission_date=current_date on conflict(user_id,mission_id) do nothing;
  with claimable as (
    select p.id,m.reward_coins,m.reward_crystals from public.mission_progress p join public.daily_missions m on m.id=p.mission_id
    where p.user_id=v_user and m.mission_date=current_date and p.progress>=m.target_value and p.claimed_at is null for update of p
  ), claimed as (
    update public.mission_progress p set claimed_at=clock_timestamp(),updated_at=clock_timestamp() from claimable c where p.id=c.id
    returning c.reward_coins,c.reward_crystals
  ) select coalesce(sum(reward_coins),0),coalesce(sum(reward_crystals),0),count(*) into v_coins,v_crystals,v_count from claimed;
  if v_count=0 then raise exception 'no_mission_rewards'; end if;
  update public.wallets set coins=coins+v_coins,crystals=crystals+v_crystals,updated_at=clock_timestamp() where user_id=v_user;
  v_existing:=jsonb_build_object('Claimed',v_count,'Coins',v_coins,'Crystals',v_crystals);
  insert into private.idempotency_keys(user_id,operation,idempotency_key,response) values(v_user,'claim_daily_missions',p_idempotency,v_existing);
  return v_existing;
end $$;

create or replace function private.claim_crystal_mine(p_idempotency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_building public.island_buildings; v_existing jsonb; v_ready timestamptz; v_cycles integer; v_amount integer;
begin
  select response into v_existing from private.idempotency_keys where user_id=v_user and operation='claim_crystal_mine' and idempotency_key=p_idempotency;
  if found then return v_existing; end if;
  select b.* into v_building from public.islands i join public.island_buildings b on b.island_id=i.id
    where i.user_id=v_user and b.building_kind='crystal_mine' for update of b;
  if not found then raise exception 'crystal_mine_not_found'; end if;
  v_ready:=coalesce(v_building.production_ready_at,v_building.created_at+interval '10 minutes');
  if clock_timestamp()<v_ready then raise exception 'crystal_mine_not_ready'; end if;
  v_cycles:=least(6,1+floor(extract(epoch from (clock_timestamp()-v_ready))/600)::integer);
  v_amount:=v_cycles*v_building.level;
  update public.island_buildings set production_ready_at=v_ready+(v_cycles*interval '10 minutes'),updated_at=clock_timestamp() where id=v_building.id;
  update public.wallets set crystals=crystals+v_amount,updated_at=clock_timestamp() where user_id=v_user;
  v_existing:=jsonb_build_object('Crystals',v_amount,'NextReadyUtc',v_ready+(v_cycles*interval '10 minutes'));
  insert into private.idempotency_keys(user_id,operation,idempotency_key,response) values(v_user,'claim_crystal_mine',p_idempotency,v_existing);
  return v_existing;
end $$;

create or replace function public.claim_daily_missions(idempotency_key text) returns jsonb language sql security invoker set search_path='' as $$select private.claim_daily_missions(idempotency_key)$$;
create or replace function public.claim_crystal_mine(idempotency_key text) returns jsonb language sql security invoker set search_path='' as $$select private.claim_crystal_mine(idempotency_key)$$;

grant execute on function private.claim_daily_missions(text),private.claim_crystal_mine(text),public.claim_daily_missions(text),public.claim_crystal_mine(text) to authenticated;

commit;
