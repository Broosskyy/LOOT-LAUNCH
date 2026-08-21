begin;

create extension if not exists pgcrypto with schema extensions;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  public_id uuid not null default gen_random_uuid() unique,
  username text unique,
  display_name text not null default 'Sky Rookie',
  avatar_key text not null default 'bouncer',
  player_level integer not null default 1 check (player_level between 1 and 999),
  island_level integer not null default 1 check (island_level between 1 and 100),
  trophies integer not null default 100 check (trophies >= 0),
  is_training_bot boolean not null default false,
  is_banned boolean not null default false,
  beginner_protection_until timestamptz not null default (now() + interval '72 hours'),
  shield_until timestamptz,
  last_active_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username is null or username ~ '^[a-z0-9_]{3,20}$'),
  constraint profiles_avatar check (avatar_key in ('bouncer','magneto','blasto','blink','pilot','crystal'))
);

create table private.private_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email_snapshot text,
  deletion_requested_at timestamptz,
  terms_version text not null default 'v1',
  privacy_version text not null default 'v1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.usernames (
  username text primary key check (username ~ '^[a-z0-9_]{3,20}$'),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  reserved_at timestamptz not null default now()
);

create table public.player_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  language text not null default 'en' check (char_length(language) between 2 and 10),
  privacy_profile_visible boolean not null default true,
  privacy_friend_requests boolean not null default true,
  push_attack boolean not null default true,
  push_friends boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.islands (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null default 'Skyhold' check (char_length(name) between 1 and 30),
  level integer not null default 1 check (level between 1 and 100),
  theme_key text not null default 'verdant_sky',
  repair_debt integer not null default 0 check (repair_debt >= 0),
  production_penalty_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.island_buildings (
  id uuid primary key default gen_random_uuid(),
  island_id uuid not null references public.islands(id) on delete cascade,
  building_kind text not null check (building_kind in ('island_core','lootling_house','cannon_workshop','crystal_mine','airship_harbor')),
  level integer not null default 1 check (level between 1 and 5),
  production_ready_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (island_id, building_kind)
);

create table public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  coins bigint not null default 1500 check (coins >= 0),
  crystals integer not null default 25 check (crystals >= 0),
  trophies integer not null default 100 check (trophies >= 0),
  updated_at timestamptz not null default now()
);

create table public.energy_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  current_energy integer not null default 10 check (current_energy >= 0),
  max_energy integer not null default 10 check (max_energy between 1 and 100),
  next_regeneration_at timestamptz not null default (now() + interval '10 minutes'),
  updated_at timestamptz not null default now(),
  check (current_energy <= max_energy)
);

create table public.lootling_definitions (
  key text primary key,
  display_name text not null,
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  passive_key text not null,
  active_key text not null,
  base_bounce numeric(6,3) not null check (base_bounce between 0 and 3),
  base_power numeric(6,3) not null check (base_power between 0 and 3),
  unlock_level integer not null default 1 check (unlock_level >= 1),
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.player_lootlings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lootling_key text not null references public.lootling_definitions(key) on delete restrict,
  level integer not null default 1 check (level between 1 and 100),
  experience integer not null default 0 check (experience >= 0),
  is_equipped boolean not null default false,
  unlocked_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lootling_key)
);

create unique index player_lootlings_one_equipped_idx on public.player_lootlings(user_id) where is_equipped;

create table public.cannon_definitions (
  key text primary key,
  display_name text not null,
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  base_power numeric(6,3) not null check (base_power between 0 and 3),
  base_precision numeric(6,3) not null check (base_precision between 0 and 1),
  special_key text,
  unlock_level integer not null default 1 check (unlock_level >= 1),
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.player_cannons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  cannon_key text not null references public.cannon_definitions(key) on delete restrict,
  level integer not null default 1 check (level between 1 and 100),
  experience integer not null default 0 check (experience >= 0),
  is_equipped boolean not null default false,
  unlocked_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, cannon_key)
);

create unique index player_cannons_one_equipped_idx on public.player_cannons(user_id) where is_equipped;

create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_key text not null,
  quantity integer not null default 0 check (quantity >= 0),
  metadata jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, item_key)
);

create table public.relic_definitions (
  key text primary key,
  display_name text not null,
  rarity text not null check (rarity in ('common','rare','epic','legendary')),
  effect_key text not null,
  effect_value numeric(10,4) not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.player_relics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  relic_key text not null references public.relic_definitions(key) on delete restrict,
  level integer not null default 1 check (level between 1 and 20),
  is_equipped boolean not null default false,
  acquired_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, relic_key)
);

create table public.launch_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  server_seed bigint not null,
  level_key text not null,
  level_config jsonb not null,
  lootling_key text not null references public.lootling_definitions(key),
  cannon_key text not null references public.cannon_definitions(key),
  energy_cost integer not null check (energy_cost between 0 and 10),
  max_coins integer not null check (max_coins >= 0),
  max_crystals integer not null check (max_crystals >= 0),
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > starts_at)
);

create index launch_sessions_user_created_idx on public.launch_sessions(user_id, created_at desc);

create table public.launch_events (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.launch_sessions(id) on delete cascade,
  sequence integer not null check (sequence between 0 and 500),
  event_type text not null check (event_type in ('coin','crystal','bounce','portal','booster','treasure','destructible','relic','ability','finish')),
  target_id text,
  event_time_ms integer not null check (event_time_ms between 0 and 20000),
  position_x numeric(10,4) not null,
  position_y numeric(10,4) not null,
  speed numeric(10,4) not null check (speed between 0 and 60),
  value integer not null default 0 check (value >= 0),
  created_at timestamptz not null default now(),
  unique (session_id, sequence)
);

create table public.launch_results (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null unique references public.launch_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  coins_awarded integer not null check (coins_awarded >= 0),
  crystals_awarded integer not null check (crystals_awarded >= 0),
  combo integer not null default 0 check (combo >= 0),
  rare_hit boolean not null default false,
  checksum text not null,
  created_at timestamptz not null default now()
);

create table public.attacks (
  id uuid primary key default gen_random_uuid(),
  attacker_id uuid not null references auth.users(id) on delete cascade,
  defender_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active','completed','expired','cancelled')),
  server_seed bigint not null,
  coins_stolen integer not null default 0 check (coins_stolen >= 0),
  trophies_delta integer not null default 0 check (trophies_delta between -100 and 100),
  revenge_of_attack_id uuid references public.attacks(id) on delete set null,
  revenge_available_until timestamptz,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  check (attacker_id <> defender_id),
  check (expires_at > starts_at)
);

create index attacks_attacker_created_idx on public.attacks(attacker_id, created_at desc);
create index attacks_defender_created_idx on public.attacks(defender_id, created_at desc);

create table public.attack_snapshots (
  attack_id uuid primary key references public.attacks(id) on delete cascade,
  defender_public_id uuid not null,
  defender_username text not null,
  defender_trophies integer not null check (defender_trophies >= 0),
  defender_island_level integer not null check (defender_island_level >= 1),
  buildings jsonb not null,
  treasure_slots jsonb not null,
  created_at timestamptz not null default now()
);

create table public.attack_shots (
  id uuid primary key default gen_random_uuid(),
  attack_id uuid not null references public.attacks(id) on delete cascade,
  shot_number integer not null check (shot_number between 1 and 3),
  angle numeric(8,4) not null check (angle between 0 and 90),
  power numeric(8,4) not null check (power between 0 and 1),
  building_hit text,
  impact_speed numeric(10,4) not null check (impact_speed between 0 and 60),
  coins_awarded integer not null default 0 check (coins_awarded >= 0),
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (attack_id, shot_number),
  unique (idempotency_key)
);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined','cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (sender_id <> recipient_id),
  unique (sender_id, recipient_id)
);

create table public.friendships (
  user_low uuid not null references auth.users(id) on delete cascade,
  user_high uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_low, user_high),
  check (user_low < user_high)
);

create table public.activity_feed (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  actor_public_id uuid,
  activity_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index activity_feed_user_created_idx on public.activity_feed(user_id, created_at desc);

create table public.daily_missions (
  id uuid primary key default gen_random_uuid(),
  mission_key text not null,
  mission_date date not null,
  target_value integer not null check (target_value > 0),
  reward_coins integer not null default 0 check (reward_coins >= 0),
  reward_crystals integer not null default 0 check (reward_crystals >= 0),
  created_at timestamptz not null default now(),
  unique (mission_key, mission_date)
);

create table public.mission_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mission_id uuid not null references public.daily_missions(id) on delete cascade,
  progress integer not null default 0 check (progress >= 0),
  completed_at timestamptz,
  claimed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, mission_id)
);

create table public.seasons (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  display_name text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create unique index seasons_one_active_idx on public.seasons(is_active) where is_active;

create table public.leaderboard_entries (
  season_id uuid not null references public.seasons(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null default 0 check (score >= 0),
  rank integer check (rank > 0),
  updated_at timestamptz not null default now(),
  primary key (season_id, user_id)
);

create index leaderboard_score_idx on public.leaderboard_entries(season_id, score desc, updated_at asc);

create table public.world_bosses (
  id uuid primary key default gen_random_uuid(),
  boss_key text not null,
  display_name text not null,
  max_health bigint not null check (max_health > 0),
  current_health bigint not null check (current_health >= 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','active','defeated','ended')),
  milestones jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  check (current_health <= max_health),
  check (ends_at > starts_at)
);

create index world_boss_active_idx on public.world_bosses(status, starts_at, ends_at);

create table public.world_boss_contributions (
  id uuid primary key default gen_random_uuid(),
  boss_id uuid not null references public.world_bosses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  contribution bigint not null default 0 check (contribution >= 0),
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (boss_id, user_id, idempotency_key)
);

create index world_boss_contrib_user_idx on public.world_boss_contributions(user_id, created_at desc);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_created_idx on public.notifications(user_id, created_at desc);

create table private.device_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android','ios','webgl')),
  push_provider text,
  push_token_hash text,
  device_fingerprint_hash text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, platform, device_fingerprint_hash)
);

create table private.security_events (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  severity text not null check (severity in ('info','warning','critical')),
  ip_hash text,
  device_hash text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index security_events_user_created_idx on private.security_events(user_id, created_at desc);

create table private.idempotency_keys (
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  idempotency_key text not null,
  response jsonb,
  created_at timestamptz not null default now(),
  primary key (user_id, operation, idempotency_key)
);

create table private.rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  window_start timestamptz not null,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (user_id, operation, window_start)
);

create index profiles_trophies_idx on public.profiles(trophies desc);
create index profiles_matchmaking_idx on public.profiles(island_level, trophies) where not is_training_bot and not is_banned;
create index usernames_user_idx on public.usernames(user_id);
create index island_buildings_island_idx on public.island_buildings(island_id);
create index friend_requests_recipient_idx on public.friend_requests(recipient_id, status, created_at desc);

commit;
