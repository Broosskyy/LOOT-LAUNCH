-- LOOT LAUNCH v15: explicit server-authoritative expedition selection.
-- The legacy two-argument RPC remains available for older clients; v15 calls
-- this three-argument overload and receives the allowed level key/config.
create or replace function private.start_launch(p_lootling text, p_cannon text, p_world text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := private.require_user();
  v_energy public.energy_states;
  v_session public.launch_sessions;
  v_seed bigint;
  v_world text;
  v_level text;
begin
  perform private.take_rate_limit(v_user,'start_launch',20,interval '1 minute');
  v_world := case p_world when 'crystal_forge' then 'crystal_forge' else 'wolkengarten' end;
  v_level := case v_world when 'crystal_forge' then 'kristallschmiede_expedition_v1' else 'wolkengarten_expedition_v1' end;
  if not exists(select 1 from public.player_lootlings where user_id=v_user and lootling_key=p_lootling) then
    raise exception 'lootling_not_owned';
  end if;
  if not exists(select 1 from public.player_cannons where user_id=v_user and cannon_key=p_cannon) then
    raise exception 'cannon_not_owned';
  end if;
  v_energy := private.refresh_energy(v_user);
  if v_energy.current_energy < 1 then raise exception 'insufficient_energy'; end if;
  update public.energy_states set current_energy=current_energy-1,updated_at=clock_timestamp() where user_id=v_user;
  v_seed := ('x'||encode(extensions.gen_random_bytes(8),'hex'))::bit(64)::bigint;
  insert into public.launch_sessions(
    user_id,server_seed,level_key,level_config,lootling_key,cannon_key,
    energy_cost,max_coins,max_crystals,expires_at
  ) values(
    v_user,v_seed,v_level,
    jsonb_build_object(
      'layout_version',6,'world_key',v_world,'seed',v_seed,'route_variant',abs(v_seed % 3),
      'route_islands',6,'island_contract_targets',array[2,3,2,3,3],
      'safe_coin_value',15,'risk_coin_value',25,
      'allowed_events',array['coin','crystal','bounce','treasure','ability','portal','booster','destructible']
    ),
    p_lootling,p_cannon,1,1500,10,clock_timestamp()+interval '15 minutes'
  ) returning * into v_session;
  return jsonb_build_object(
    'SessionId',v_session.id,'Seed',v_seed,'WorldKey',v_world,'LevelKey',v_level,
    'StartsAtUtc',v_session.starts_at,'ExpiresAtUtc',v_session.expires_at,
    'Lootling',case p_lootling when 'bouncer' then 0 when 'magneto' then 1 when 'blasto' then 2 else 3 end,
    'Cannon',case p_cannon when 'standard' then 0 when 'thunder' then 1 else 2 end,
    'EnergyCost',1,'MaxCoins',1500,'MaxCrystals',10
  );
end $$;

create or replace function public.start_launch(lootling text,cannon text,world_key text)
returns jsonb language sql security invoker set search_path=''
as $$select private.start_launch(lootling,cannon,world_key)$$;

revoke all on function private.start_launch(text,text,text) from public,anon;
revoke all on function public.start_launch(text,text,text) from public,anon;
grant execute on function private.start_launch(text,text,text) to authenticated;
grant execute on function public.start_launch(text,text,text) to authenticated;
