begin;

create or replace function private.require_user()
returns uuid language plpgsql stable security invoker set search_path = '' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if exists (select 1 from public.profiles p where p.user_id = v_user and p.is_banned) then
    raise exception 'account_suspended' using errcode = '42501';
  end if;
  return v_user;
end $$;

create or replace function private.take_rate_limit(p_user uuid, p_operation text, p_limit integer, p_window interval)
returns void language plpgsql security definer set search_path = '' as $$
declare v_window timestamptz := date_bin(p_window, clock_timestamp(), '2020-01-01'::timestamptz); v_count integer;
begin
  insert into private.rate_limits(user_id, operation, window_start, request_count)
  values (p_user, p_operation, v_window, 1)
  on conflict (user_id, operation, window_start) do update set request_count = private.rate_limits.request_count + 1
  returning request_count into v_count;
  if v_count > p_limit then
    insert into private.security_events(user_id,event_type,severity,payload) values(p_user,'rate_limit','warning',jsonb_build_object('operation',p_operation,'count',v_count));
    raise exception 'rate_limit_exceeded' using errcode = 'P0001';
  end if;
end $$;

create or replace function private.refresh_energy(p_user uuid)
returns public.energy_states language plpgsql security definer set search_path = '' as $$
declare v_state public.energy_states; v_now timestamptz := clock_timestamp(); v_ticks integer;
begin
  select * into v_state from public.energy_states where user_id = p_user for update;
  if not found then raise exception 'energy_state_missing'; end if;
  if v_state.current_energy < v_state.max_energy and v_now >= v_state.next_regeneration_at then
    v_ticks := floor(extract(epoch from (v_now - v_state.next_regeneration_at)) / 600)::integer + 1;
    update public.energy_states set
      current_energy = least(max_energy, current_energy + v_ticks),
      next_regeneration_at = case when current_energy + v_ticks >= max_energy then v_now + interval '10 minutes' else next_regeneration_at + (v_ticks * interval '10 minutes') end,
      updated_at = v_now
    where user_id = p_user returning * into v_state;
  end if;
  return v_state;
end $$;

create or replace function private.bootstrap_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_island uuid; v_season uuid;
begin
  insert into public.profiles(user_id, display_name) values(new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Sky Rookie'));
  insert into private.private_profiles(user_id, email_snapshot) values(new.id, new.email);
  insert into public.player_settings(user_id) values(new.id);
  insert into public.wallets(user_id) values(new.id);
  insert into public.energy_states(user_id) values(new.id);
  insert into public.islands(user_id) values(new.id) returning id into v_island;
  insert into public.island_buildings(island_id,building_kind) values
    (v_island,'island_core'),(v_island,'lootling_house'),(v_island,'cannon_workshop'),(v_island,'crystal_mine'),(v_island,'airship_harbor');
  insert into public.player_lootlings(user_id,lootling_key,is_equipped) values(new.id,'bouncer',true);
  insert into public.player_cannons(user_id,cannon_key,is_equipped) values(new.id,'standard',true);
  insert into public.inventory_items(user_id,item_key,quantity) values(new.id,'starter_shield',1);
  select id into v_season from public.seasons where is_active order by starts_at desc limit 1;
  if v_season is not null then insert into public.leaderboard_entries(season_id,user_id,score) values(v_season,new.id,100); end if;
  insert into public.mission_progress(user_id,mission_id)
    select new.id,id from public.daily_missions where mission_date=current_date on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function private.bootstrap_new_user();

create or replace function private.reserve_username(p_username text, p_display_name text, p_avatar_key text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_name text := lower(trim(p_username)); v_result jsonb;
begin
  perform private.take_rate_limit(v_user,'reserve_username',5,interval '10 minutes');
  if v_name !~ '^[a-z0-9_]{3,20}$' then raise exception 'invalid_username'; end if;
  insert into public.usernames(username,user_id) values(v_name,v_user)
    on conflict (user_id) do update set username=excluded.username,reserved_at=clock_timestamp();
  update public.profiles set username=v_name,display_name=left(coalesce(nullif(trim(p_display_name),''),v_name),30),avatar_key=p_avatar_key,updated_at=clock_timestamp()
    where user_id=v_user returning to_jsonb(profiles.*) into v_result;
  return v_result - 'user_id' - 'is_banned';
exception when unique_violation then raise exception 'username_unavailable' using errcode='23505';
end $$;

create or replace function private.cloud_save()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_energy public.energy_states; v_result jsonb;
begin
  v_energy := private.refresh_energy(v_user);
  select jsonb_build_object(
    'Profile', jsonb_build_object('PublicId',p.public_id,'Username',p.username,'DisplayName',p.display_name,'AvatarKey',p.avatar_key,'PlayerLevel',p.player_level,'IslandLevel',p.island_level,'Trophies',p.trophies,'IsTrainingBot',p.is_training_bot),
    'Wallet', jsonb_build_object('Coins',w.coins,'Crystals',w.crystals,'Trophies',w.trophies),
    'Energy', jsonb_build_object('Current',v_energy.current_energy,'Maximum',v_energy.max_energy,'NextRegenerationUtc',v_energy.next_regeneration_at),
    'Buildings', coalesce((select jsonb_agg(jsonb_build_object('Kind',case b.building_kind when 'island_core' then 0 when 'lootling_house' then 1 when 'cannon_workshop' then 2 when 'crystal_mine' then 3 else 4 end,'Level',b.level,'UpgradeCost',case when b.level>=5 then 0 else 150*b.level*b.level end) order by b.building_kind) from public.islands i join public.island_buildings b on b.island_id=i.id where i.user_id=v_user),'[]'::jsonb),
    'EquippedLootling', coalesce((select case lootling_key when 'bouncer' then 0 when 'magneto' then 1 when 'blasto' then 2 else 3 end from public.player_lootlings where user_id=v_user and is_equipped limit 1),0),
    'EquippedCannon', coalesce((select case cannon_key when 'standard' then 0 when 'thunder' then 1 else 2 end from public.player_cannons where user_id=v_user and is_equipped limit 1),0),
    'Activity', coalesce((select jsonb_agg(a.body order by a.created_at desc) from (select body,created_at from public.activity_feed where user_id=v_user order by created_at desc limit 20) a),'[]'::jsonb)
  ) into v_result from public.profiles p join public.wallets w on w.user_id=p.user_id where p.user_id=v_user;
  return v_result;
end $$;

create or replace function private.start_launch(p_lootling text, p_cannon text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_energy public.energy_states; v_session public.launch_sessions; v_seed bigint;
begin
  perform private.take_rate_limit(v_user,'start_launch',20,interval '1 minute');
  if not exists(select 1 from public.player_lootlings where user_id=v_user and lootling_key=p_lootling) then raise exception 'lootling_not_owned'; end if;
  if not exists(select 1 from public.player_cannons where user_id=v_user and cannon_key=p_cannon) then raise exception 'cannon_not_owned'; end if;
  v_energy := private.refresh_energy(v_user);
  if v_energy.current_energy < 1 then raise exception 'insufficient_energy'; end if;
  update public.energy_states set current_energy=current_energy-1,updated_at=clock_timestamp() where user_id=v_user;
  v_seed := ('x'||encode(extensions.gen_random_bytes(8),'hex'))::bit(64)::bigint;
  insert into public.launch_sessions(user_id,server_seed,level_key,level_config,lootling_key,cannon_key,energy_cost,max_coins,max_crystals,expires_at)
  values(v_user,v_seed,'treasure_garden_v1',jsonb_build_object('layout_version',1,'seed',v_seed,'allowed_events',array['coin','crystal','bounce','treasure','ability']),p_lootling,p_cannon,1,500,5,clock_timestamp()+interval '2 minutes') returning * into v_session;
  return jsonb_build_object('SessionId',v_session.id,'Seed',v_seed,'StartsAtUtc',v_session.starts_at,'ExpiresAtUtc',v_session.expires_at,'Lootling',case p_lootling when 'bouncer' then 0 when 'magneto' then 1 when 'blasto' then 2 else 3 end,'Cannon',case p_cannon when 'standard' then 0 when 'thunder' then 1 else 2 end,'EnergyCost',1,'MaxCoins',500,'MaxCrystals',5);
end $$;

create or replace function private.submit_launch(p_submission jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_session public.launch_sessions; v_existing public.launch_results; v_event jsonb; v_seq integer := -1; v_coins integer := 0; v_crystals integer := 0; v_combo integer := 0; v_result public.launch_results; v_checksum text;
begin
  perform private.take_rate_limit(v_user,'submit_launch',30,interval '1 minute');
  select * into v_session from public.launch_sessions where id=(p_submission->>'SessionId')::uuid and user_id=v_user for update;
  if not found then raise exception 'launch_session_not_found'; end if;
  select * into v_existing from public.launch_results where session_id=v_session.id;
  if found then return jsonb_build_object('ResultId',v_existing.id,'Coins',v_existing.coins_awarded,'Crystals',v_existing.crystals_awarded,'Combo',v_existing.combo,'RareHit',v_existing.rare_hit,'WasAlreadyProcessed',true); end if;
  if v_session.expires_at < clock_timestamp() then raise exception 'launch_session_expired'; end if;
  if jsonb_array_length(coalesce(p_submission->'Events','[]'::jsonb)) > 200 then raise exception 'too_many_events'; end if;
  for v_event in select * from jsonb_array_elements(coalesce(p_submission->'Events','[]'::jsonb)) loop
    if (v_event->>'Sequence')::integer <> v_seq+1 then raise exception 'invalid_event_sequence'; end if; v_seq := v_seq+1;
    if (v_event->>'Speed')::numeric < 0 or (v_event->>'Speed')::numeric > 60 or (v_event->>'Time')::numeric < 0 or (v_event->>'Time')::numeric > 20 then raise exception 'impossible_event'; end if;
    if v_event->>'EventType'='coin' then v_coins := v_coins + least(greatest((v_event->>'Value')::integer,0),25);
    elsif v_event->>'EventType'='crystal' then v_crystals := v_crystals + least(greatest((v_event->>'Value')::integer,0),1);
    elsif v_event->>'EventType'='treasure' then v_coins := v_coins + 100;
    elsif v_event->>'EventType' not in ('bounce','ability','portal','booster','destructible','relic','finish') then raise exception 'event_not_allowed'; end if;
    insert into public.launch_events(session_id,sequence,event_type,target_id,event_time_ms,position_x,position_y,speed,value)
    values(v_session.id,v_seq,v_event->>'EventType',v_event->>'TargetId',round((v_event->>'Time')::numeric*1000)::integer,(v_event->>'X')::numeric,(v_event->>'Y')::numeric,(v_event->>'Speed')::numeric,greatest(coalesce((v_event->>'Value')::integer,0),0));
    v_combo := v_combo+1;
  end loop;
  v_coins := least(v_coins,v_session.max_coins); v_crystals := least(v_crystals,v_session.max_crystals); v_checksum := coalesce(p_submission->>'Checksum','missing');
  insert into public.launch_results(session_id,user_id,coins_awarded,crystals_awarded,combo,rare_hit,checksum)
    values(v_session.id,v_user,v_coins,v_crystals,v_combo,v_crystals>0 or v_coins>=250,v_checksum) returning * into v_result;
  update public.wallets set coins=coins+v_coins,crystals=crystals+v_crystals,updated_at=clock_timestamp() where user_id=v_user;
  update public.launch_sessions set processed_at=clock_timestamp() where id=v_session.id;
  insert into public.activity_feed(user_id,activity_type,title,body,payload) values(v_user,'launch_result','Loot secured',format('%s coins and %s crystals',v_coins,v_crystals),jsonb_build_object('session_id',v_session.id));
  return jsonb_build_object('ResultId',v_result.id,'Coins',v_coins,'Crystals',v_crystals,'Combo',v_combo,'RareHit',v_result.rare_hit,'WasAlreadyProcessed',false);
exception when others then
  if sqlerrm in ('impossible_event','invalid_event_sequence','too_many_events','event_not_allowed') then insert into private.security_events(user_id,event_type,severity,payload) values(v_user,'launch_validation_failed','warning',jsonb_build_object('reason',sqlerrm,'session',p_submission->>'SessionId')); end if;
  raise;
end $$;

create or replace function private.upgrade_building(p_kind text,p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_building public.island_buildings; v_cost integer; v_existing jsonb;
begin
  select response into v_existing from private.idempotency_keys where user_id=v_user and operation='upgrade_building' and idempotency_key=p_idempotency_key;
  if found then return v_existing; end if;
  select b.* into v_building from public.islands i join public.island_buildings b on b.island_id=i.id where i.user_id=v_user and b.building_kind=p_kind for update of b;
  if not found then raise exception 'building_not_found'; end if; if v_building.level>=5 then raise exception 'building_max_level'; end if;
  v_cost := 150*v_building.level*v_building.level;
  update public.wallets set coins=coins-v_cost,updated_at=clock_timestamp() where user_id=v_user and coins>=v_cost;
  if not found then raise exception 'insufficient_coins'; end if;
  update public.island_buildings set level=level+1,updated_at=clock_timestamp() where id=v_building.id;
  update public.islands set level=(select greatest(1,floor(sum(b.level)/5.0)::integer) from public.island_buildings b where b.island_id=v_building.island_id),updated_at=clock_timestamp() where id=v_building.island_id;
  update public.profiles set island_level=(select level from public.islands where user_id=v_user),updated_at=clock_timestamp() where user_id=v_user;
  v_existing := private.cloud_save();
  insert into private.idempotency_keys(user_id,operation,idempotency_key,response) values(v_user,'upgrade_building',p_idempotency_key,v_existing);
  return v_existing;
end $$;

create or replace function private.find_match(p_allow_training boolean default false)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid := private.require_user(); v_me public.profiles; v_target public.profiles; v_buildings jsonb;
begin
  perform private.take_rate_limit(v_user,'find_match',20,interval '10 minutes'); select * into v_me from public.profiles where user_id=v_user;
  select p.* into v_target from public.profiles p where p.user_id<>v_user and not p.is_banned and (p.beginner_protection_until<=clock_timestamp()) and (p.shield_until is null or p.shield_until<=clock_timestamp()) and (not p.is_training_bot or p_allow_training)
    and not exists(select 1 from public.attacks a where a.attacker_id=v_user and a.defender_id=p.user_id and a.created_at>current_date and a.status='completed' group by a.defender_id having count(*)>=2)
    order by abs(p.trophies-v_me.trophies)+abs(p.island_level-v_me.island_level)*25, random() limit 1;
  if not found then raise exception 'no_eligible_opponent'; end if;
  select jsonb_agg(jsonb_build_object('Kind',case b.building_kind when 'island_core' then 0 when 'lootling_house' then 1 when 'cannon_workshop' then 2 when 'crystal_mine' then 3 else 4 end,'Level',b.level,'UpgradeCost',0)) into v_buildings from public.islands i join public.island_buildings b on b.island_id=i.id where i.user_id=v_target.user_id;
  return jsonb_build_object('PublicId',v_target.public_id,'Username',v_target.username,'DisplayName',v_target.display_name,'AvatarKey',v_target.avatar_key,'IslandLevel',v_target.island_level,'Trophies',v_target.trophies,'IsTrainingBot',v_target.is_training_bot,'Buildings',coalesce(v_buildings,'[]'::jsonb));
end $$;

create or replace function private.start_attack(p_target_public_id uuid,p_revenge_attack_id uuid default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=private.require_user(); v_target public.profiles; v_attack public.attacks; v_seed bigint; v_buildings jsonb;
begin
  perform private.take_rate_limit(v_user,'start_attack',10,interval '10 minutes'); select * into v_target from public.profiles where public_id=p_target_public_id and user_id<>v_user and not is_banned for share;
  if not found then raise exception 'target_not_found'; end if;
  if (v_target.beginner_protection_until>clock_timestamp() or v_target.shield_until>clock_timestamp()) and p_revenge_attack_id is null then raise exception 'target_protected'; end if;
  if p_revenge_attack_id is not null and not exists(select 1 from public.attacks where id=p_revenge_attack_id and defender_id=v_user and attacker_id=v_target.user_id and revenge_available_until>clock_timestamp() and status='completed') then raise exception 'revenge_unavailable'; end if;
  select jsonb_agg(jsonb_build_object('kind',b.building_kind,'level',b.level) order by b.building_kind) into v_buildings from public.islands i join public.island_buildings b on b.island_id=i.id where i.user_id=v_target.user_id;
  v_seed:=('x'||encode(extensions.gen_random_bytes(8),'hex'))::bit(64)::bigint;
  insert into public.attacks(attacker_id,defender_id,server_seed,revenge_of_attack_id,expires_at) values(v_user,v_target.user_id,v_seed,p_revenge_attack_id,clock_timestamp()+interval '10 minutes') returning * into v_attack;
  insert into public.attack_snapshots(attack_id,defender_public_id,defender_username,defender_trophies,defender_island_level,buildings,treasure_slots) values(v_attack.id,v_target.public_id,v_target.username,v_target.trophies,v_target.island_level,v_buildings,jsonb_build_array(1,3));
  return jsonb_build_object('AttackId',v_attack.id,'Seed',v_seed,'ShotsRemaining',3,'Target',jsonb_build_object(
    'PublicId',v_target.public_id,'Username',v_target.username,'DisplayName',v_target.display_name,'AvatarKey',v_target.avatar_key,
    'IslandLevel',v_target.island_level,'Trophies',v_target.trophies,'IsTrainingBot',v_target.is_training_bot,
    'Buildings',(select jsonb_agg(jsonb_build_object('Kind',case x->>'kind' when 'island_core' then 0 when 'lootling_house' then 1 when 'cannon_workshop' then 2 when 'crystal_mine' then 3 else 4 end,'Level',(x->>'level')::integer,'UpgradeCost',0)) from jsonb_array_elements(v_buildings) x)
  ));
end $$;

create or replace function private.submit_attack_shot(p_attack_id uuid,p_shot integer,p_angle numeric,p_power numeric,p_building text,p_speed numeric,p_idempotency text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_user uuid:=private.require_user(); v_attack public.attacks; v_hit boolean; v_award integer; v_count integer; v_total integer; v_hits integer; v_delta integer;
begin
  select * into v_attack from public.attacks where id=p_attack_id and attacker_id=v_user for update; if not found then raise exception 'attack_not_found'; end if;
  if v_attack.status<>'active' or v_attack.expires_at<clock_timestamp() then raise exception 'attack_inactive'; end if;
  if p_shot<>(select count(*)+1 from public.attack_shots where attack_id=p_attack_id) or p_shot not between 1 and 3 then raise exception 'invalid_shot_order'; end if;
  if p_angle not between 0 and 90 or p_power not between 0 and 1 or p_speed not between 0 and 60 then raise exception 'impossible_shot'; end if;
  v_hit:=p_building is not null and p_speed>=2; v_award:=case when v_hit then least(180,greatest(20,round(p_speed*6)::integer)) else 0 end;
  insert into public.attack_shots(attack_id,shot_number,angle,power,building_hit,impact_speed,coins_awarded,idempotency_key) values(p_attack_id,p_shot,p_angle,p_power,case when v_hit then p_building end,p_speed,v_award,p_idempotency)
    on conflict(idempotency_key) do nothing;
  select count(*),coalesce(sum(coins_awarded),0),count(*) filter(where building_hit is not null) into v_count,v_total,v_hits from public.attack_shots where attack_id=p_attack_id;
  if v_count<3 then return jsonb_build_object('AttackId',p_attack_id,'CoinsStolen',0,'TrophyDelta',0,'BuildingsHit',v_hits,'Complete',false); end if;
  v_delta:=least(8,greatest(-4,v_hits*4-4)); v_total:=least(v_total,(select least(500,(coins/10)::integer) from public.wallets where user_id=v_attack.defender_id));
  update public.wallets set coins=greatest(0,coins-v_total),trophies=greatest(0,trophies-v_delta),updated_at=clock_timestamp() where user_id=v_attack.defender_id;
  update public.wallets set coins=coins+v_total,trophies=greatest(0,trophies+v_delta),updated_at=clock_timestamp() where user_id=v_user;
  update public.profiles p set trophies=w.trophies,updated_at=clock_timestamp() from public.wallets w where p.user_id=w.user_id and p.user_id in(v_user,v_attack.defender_id);
  update public.attacks set status='completed',coins_stolen=v_total,trophies_delta=v_delta,completed_at=clock_timestamp(),revenge_available_until=clock_timestamp()+interval '48 hours' where id=p_attack_id;
  insert into public.activity_feed(user_id,actor_public_id,activity_type,title,body,payload) select v_attack.defender_id,p.public_id,'defense_result','Your island was attacked',format('%s buildings hit, %s coins lost',v_hits,v_total),jsonb_build_object('attack_id',p_attack_id,'revenge_until',clock_timestamp()+interval '48 hours') from public.profiles p where p.user_id=v_user;
  return jsonb_build_object('AttackId',p_attack_id,'CoinsStolen',v_total,'TrophyDelta',v_delta,'BuildingsHit',v_hits,'Complete',true);
exception when unique_violation then
  select count(*),coalesce(sum(coins_awarded),0),count(*) filter(where building_hit is not null) into v_count,v_total,v_hits from public.attack_shots where attack_id=p_attack_id;
  return jsonb_build_object('AttackId',p_attack_id,'CoinsStolen',case when v_count=3 then v_attack.coins_stolen else 0 end,'TrophyDelta',case when v_count=3 then v_attack.trophies_delta else 0 end,'BuildingsHit',v_hits,'Complete',v_count=3);
end $$;

create or replace function private.send_friend_request(p_target_public_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_target uuid;
begin
  perform private.take_rate_limit(v_user,'friend_request',20,interval '1 day'); select user_id into v_target from public.profiles where public_id=p_target_public_id and not is_banned and not is_training_bot;
  if v_target is null or v_target=v_user then raise exception 'invalid_friend_target'; end if;
  insert into public.friend_requests(sender_id,recipient_id) values(v_user,v_target) on conflict(sender_id,recipient_id) do update set status='pending',created_at=clock_timestamp(),responded_at=null;
  insert into public.activity_feed(user_id,actor_public_id,activity_type,title,body) select v_target,public_id,'friend_request','New crew request','@'||username||' wants to join your sky crew' from public.profiles where user_id=v_user;
end $$;

create or replace function private.accept_friend_request(p_request_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_sender uuid;
begin
  update public.friend_requests set status='accepted',responded_at=clock_timestamp() where id=p_request_id and recipient_id=v_user and status='pending' returning sender_id into v_sender;
  if v_sender is null then raise exception 'request_not_found'; end if;
  insert into public.friendships(user_low,user_high) values(least(v_user,v_sender),greatest(v_user,v_sender)) on conflict do nothing;
end $$;

create or replace function private.remove_friend(p_target_public_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_target uuid;
begin
  select user_id into v_target from public.profiles where public_id=p_target_public_id;
  if v_target is null then raise exception 'friend_not_found'; end if;
  delete from public.friendships where user_low=least(v_user,v_target) and user_high=greatest(v_user,v_target);
end $$;

create or replace function private.list_friends()
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user();
begin
  return jsonb_build_object('items',coalesce((select jsonb_agg(jsonb_build_object('Profile',jsonb_build_object('PublicId',p.public_id,'Username',p.username,'DisplayName',p.display_name,'AvatarKey',p.avatar_key,'PlayerLevel',p.player_level,'IslandLevel',p.island_level,'Trophies',p.trophies,'IsTrainingBot',p.is_training_bot),'Online',p.last_active_at>clock_timestamp()-interval '5 minutes') order by p.username)
    from public.friendships f join public.profiles p on p.user_id=case when f.user_low=v_user then f.user_high else f.user_low end where f.user_low=v_user or f.user_high=v_user),'[]'::jsonb));
end $$;

create or replace function private.friends_leaderboard()
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user();
begin
  return jsonb_build_object('items',coalesce((select jsonb_agg(row_data order by score desc) from (
    select p.trophies score,jsonb_build_object('Rank',row_number() over(order by p.trophies desc),'Score',p.trophies,'Profile',jsonb_build_object('PublicId',p.public_id,'Username',p.username,'DisplayName',p.display_name,'AvatarKey',p.avatar_key,'PlayerLevel',p.player_level,'IslandLevel',p.island_level,'Trophies',p.trophies,'IsTrainingBot',p.is_training_bot)) row_data
    from public.profiles p where p.user_id=v_user or p.user_id in(select case when f.user_low=v_user then f.user_high else f.user_low end from public.friendships f where f.user_low=v_user or f.user_high=v_user)
  ) q),'[]'::jsonb));
end $$;

create or replace function private.contribute_world_boss(p_score integer,p_idempotency text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.require_user(); v_boss public.world_bosses; v_score integer:=least(1000,greatest(0,p_score)); v_personal bigint;
begin
  select * into v_boss from public.world_bosses where status='active' and starts_at<=clock_timestamp() and ends_at>clock_timestamp() order by starts_at desc limit 1 for update;
  if not found then raise exception 'no_active_world_boss'; end if;
  insert into public.world_boss_contributions(boss_id,user_id,contribution,idempotency_key) values(v_boss.id,v_user,v_score,p_idempotency) on conflict do nothing;
  if found then update public.world_bosses set current_health=greatest(0,current_health-v_score),status=case when current_health-v_score<=0 then 'defeated' else status end where id=v_boss.id returning * into v_boss; end if;
  select coalesce(sum(contribution),0) into v_personal from public.world_boss_contributions where boss_id=v_boss.id and user_id=v_user;
  return jsonb_build_object('BossId',v_boss.id,'Name',v_boss.display_name,'CurrentHealth',v_boss.current_health,'MaximumHealth',v_boss.max_health,'PersonalContribution',v_personal,'EndsAtUtc',v_boss.ends_at);
end $$;

-- Data API entry points: exposed wrappers are invoker functions; privileged work stays in the non-exposed private schema.
create or replace function public.reserve_username(username text,display_name text,avatar_key text) returns jsonb language sql security invoker set search_path='' as $$select private.reserve_username(username,display_name,avatar_key)$$;
create or replace function public.get_cloud_save() returns jsonb language sql security invoker set search_path='' as $$select private.cloud_save()$$;
create or replace function public.start_launch(lootling text,cannon text) returns jsonb language sql security invoker set search_path='' as $$select private.start_launch(lootling,cannon)$$;
create or replace function public.submit_launch(submission jsonb) returns jsonb language sql security invoker set search_path='' as $$select private.submit_launch(submission)$$;
create or replace function public.upgrade_building(building_kind text,idempotency_key text) returns jsonb language sql security invoker set search_path='' as $$select private.upgrade_building(building_kind,idempotency_key)$$;
create or replace function public.find_match(allow_training boolean default false) returns jsonb language sql security invoker set search_path='' as $$select private.find_match(allow_training)$$;
create or replace function public.start_attack(target_public_id uuid,revenge_attack_id uuid default null) returns jsonb language sql security invoker set search_path='' as $$select private.start_attack(target_public_id,revenge_attack_id)$$;
create or replace function public.submit_attack_shot(attack_id uuid,shot_number integer,angle numeric,power numeric,building_hit text,impact_speed numeric,idempotency_key text) returns jsonb language sql security invoker set search_path='' as $$select private.submit_attack_shot(attack_id,shot_number,angle,power,building_hit,impact_speed,idempotency_key)$$;
create or replace function public.send_friend_request(target_public_id uuid) returns void language sql security invoker set search_path='' as $$select private.send_friend_request(target_public_id)$$;
create or replace function public.accept_friend_request(request_id uuid) returns void language sql security invoker set search_path='' as $$select private.accept_friend_request(request_id)$$;
create or replace function public.remove_friend(target_public_id uuid) returns void language sql security invoker set search_path='' as $$select private.remove_friend(target_public_id)$$;
create or replace function public.list_friends() returns jsonb language sql security invoker set search_path='' as $$select private.list_friends()$$;
create or replace function public.friends_leaderboard() returns jsonb language sql security invoker set search_path='' as $$select private.friends_leaderboard()$$;
create or replace function public.contribute_world_boss(score integer,idempotency_key text) returns jsonb language sql security invoker set search_path='' as $$select private.contribute_world_boss(score,idempotency_key)$$;

grant usage on schema private to authenticated;
grant execute on function private.reserve_username(text,text,text),private.cloud_save(),private.start_launch(text,text),private.submit_launch(jsonb),private.upgrade_building(text,text),private.find_match(boolean),private.start_attack(uuid,uuid),private.submit_attack_shot(uuid,integer,numeric,numeric,text,numeric,text),private.send_friend_request(uuid),private.accept_friend_request(uuid),private.remove_friend(uuid),private.list_friends(),private.friends_leaderboard(),private.contribute_world_boss(integer,text) to authenticated;
grant execute on function public.reserve_username(text,text,text),public.get_cloud_save(),public.start_launch(text,text),public.submit_launch(jsonb),public.upgrade_building(text,text),public.find_match(boolean),public.start_attack(uuid,uuid),public.submit_attack_shot(uuid,integer,numeric,numeric,text,numeric,text),public.send_friend_request(uuid),public.accept_friend_request(uuid),public.remove_friend(uuid),public.list_friends(),public.friends_leaderboard(),public.contribute_world_boss(integer,text) to authenticated;

-- Column-level public profile access; internal Auth UUIDs and moderation flags are never selectable by clients.
revoke select on public.profiles from authenticated;
grant select(public_id,username,display_name,avatar_key,player_level,island_level,trophies,is_training_bot,last_active_at) on public.profiles to authenticated;
revoke select on public.attacks,public.attack_snapshots,public.attack_shots,public.friend_requests,public.friendships,public.leaderboard_entries from authenticated;
revoke select on public.leaderboard_entries from anon;

commit;
