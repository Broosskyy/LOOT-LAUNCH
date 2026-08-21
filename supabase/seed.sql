insert into public.lootling_definitions(key,display_name,rarity,passive_key,active_key,base_bounce,base_power,unlock_level) values
  ('bouncer','Bouncer','common','power_bounce','speed_surge',0.92,1.00,1),
  ('magneto','Magneto','rare','magnet_field','loot_pull',0.72,0.95,2),
  ('blasto','Blasto','rare','first_hit_break','shock_blast',0.65,1.08,3),
  ('blink','Blink','epic','phase_guard','phase_blink',0.70,0.98,4)
on conflict(key) do update set display_name=excluded.display_name,rarity=excluded.rarity,passive_key=excluded.passive_key,active_key=excluded.active_key,base_bounce=excluded.base_bounce,base_power=excluded.base_power,unlock_level=excluded.unlock_level;

insert into public.cannon_definitions(key,display_name,rarity,base_power,base_precision,special_key,unlock_level) values
  ('standard','Standard Cannon','common',1.00,0.95,null,1),
  ('thunder','Thunder Cannon','rare',1.25,0.70,'impact_break',2),
  ('portal','Portal Thrower','epic',0.88,0.90,'second_impulse',3)
on conflict(key) do update set display_name=excluded.display_name,rarity=excluded.rarity,base_power=excluded.base_power,base_precision=excluded.base_precision,special_key=excluded.special_key,unlock_level=excluded.unlock_level;

insert into public.relic_definitions(key,display_name,rarity,effect_key,effect_value) values
  ('echo_spring','Echo Spring','rare','bounce_reward',0.05),
  ('sky_compass','Sky Compass','epic','precision_window',0.04),
  ('vault_feather','Vault Feather','legendary','crystal_chance',0.01)
on conflict(key) do update set display_name=excluded.display_name,rarity=excluded.rarity,effect_key=excluded.effect_key,effect_value=excluded.effect_value;

insert into public.seasons(key,display_name,starts_at,ends_at,is_active) values
  ('founders_sky','Founders Sky',date_trunc('day',now()),date_trunc('day',now())+interval '28 days',true)
on conflict(key) do update set display_name=excluded.display_name,starts_at=excluded.starts_at,ends_at=excluded.ends_at,is_active=true;

insert into public.daily_missions(mission_key,mission_date,target_value,reward_coins,reward_crystals) values
  ('launch_once',current_date,1,150,0),('hit_five',current_date,5,250,0),('upgrade_once',current_date,1,300,1)
on conflict(mission_key,mission_date) do update set target_value=excluded.target_value,reward_coins=excluded.reward_coins,reward_crystals=excluded.reward_crystals;

insert into public.world_bosses(boss_key,display_name,max_health,current_health,starts_at,ends_at,status,milestones)
select 'vault_whale','The Vault Whale',1000000,1000000,date_trunc('day',now()),date_trunc('day',now())+interval '7 days','active','[{"percent":25,"reward_coins":250},{"percent":50,"reward_coins":500},{"percent":100,"reward_crystals":5}]'::jsonb
where not exists(select 1 from public.world_bosses where status='active' and ends_at>now());

-- No fake people are inserted. Local development training opponents live only in LocalDevelopmentBackend and are visibly marked TRAINING BOT.
-- Create real test players through Supabase Auth so auth.users owns their identity and the bootstrap trigger initializes them.
