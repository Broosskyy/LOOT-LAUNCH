begin;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from anon, authenticated;
revoke all on all tables in schema private from anon, authenticated;
revoke all on all sequences in schema private from anon, authenticated;
revoke all on all functions in schema private from anon, authenticated;

alter table public.profiles enable row level security;
alter table public.usernames enable row level security;
alter table public.player_settings enable row level security;
alter table public.islands enable row level security;
alter table public.island_buildings enable row level security;
alter table public.wallets enable row level security;
alter table public.energy_states enable row level security;
alter table public.lootling_definitions enable row level security;
alter table public.player_lootlings enable row level security;
alter table public.cannon_definitions enable row level security;
alter table public.player_cannons enable row level security;
alter table public.inventory_items enable row level security;
alter table public.relic_definitions enable row level security;
alter table public.player_relics enable row level security;
alter table public.launch_sessions enable row level security;
alter table public.launch_events enable row level security;
alter table public.launch_results enable row level security;
alter table public.attacks enable row level security;
alter table public.attack_snapshots enable row level security;
alter table public.attack_shots enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.activity_feed enable row level security;
alter table public.daily_missions enable row level security;
alter table public.mission_progress enable row level security;
alter table public.seasons enable row level security;
alter table public.leaderboard_entries enable row level security;
alter table public.world_bosses enable row level security;
alter table public.world_boss_contributions enable row level security;
alter table public.notifications enable row level security;

alter table public.profiles force row level security;
alter table public.usernames force row level security;
alter table public.player_settings force row level security;
alter table public.islands force row level security;
alter table public.island_buildings force row level security;
alter table public.wallets force row level security;
alter table public.energy_states force row level security;
alter table public.player_lootlings force row level security;
alter table public.player_cannons force row level security;
alter table public.inventory_items force row level security;
alter table public.player_relics force row level security;
alter table public.launch_sessions force row level security;
alter table public.launch_events force row level security;
alter table public.launch_results force row level security;
alter table public.attacks force row level security;
alter table public.attack_snapshots force row level security;
alter table public.attack_shots force row level security;
alter table public.friend_requests force row level security;
alter table public.friendships force row level security;
alter table public.activity_feed force row level security;
alter table public.mission_progress force row level security;
alter table public.leaderboard_entries force row level security;
alter table public.world_boss_contributions force row level security;
alter table public.notifications force row level security;

grant usage on schema public to anon, authenticated;
grant select on public.lootling_definitions, public.cannon_definitions, public.relic_definitions, public.seasons, public.world_bosses to anon, authenticated;
grant select on public.profiles, public.player_settings, public.islands, public.island_buildings, public.wallets, public.energy_states,
  public.player_lootlings, public.player_cannons, public.inventory_items, public.player_relics,
  public.launch_sessions, public.launch_results, public.attacks, public.attack_snapshots, public.attack_shots,
  public.friend_requests, public.friendships, public.activity_feed, public.daily_missions, public.mission_progress,
  public.leaderboard_entries, public.world_boss_contributions, public.notifications to authenticated;

create policy profiles_authenticated_public_read on public.profiles for select to authenticated
  using (not is_banned or user_id = auth.uid());
create policy settings_owner_read on public.player_settings for select to authenticated using (user_id = auth.uid());
create policy islands_owner_read on public.islands for select to authenticated using (user_id = auth.uid());
create policy buildings_owner_read on public.island_buildings for select to authenticated
  using (exists (select 1 from public.islands i where i.id = island_id and i.user_id = auth.uid()));
create policy wallets_owner_read on public.wallets for select to authenticated using (user_id = auth.uid());
create policy energy_owner_read on public.energy_states for select to authenticated using (user_id = auth.uid());
create policy lootling_catalog_public_read on public.lootling_definitions for select to anon, authenticated using (enabled);
create policy player_lootlings_owner_read on public.player_lootlings for select to authenticated using (user_id = auth.uid());
create policy cannon_catalog_public_read on public.cannon_definitions for select to anon, authenticated using (enabled);
create policy player_cannons_owner_read on public.player_cannons for select to authenticated using (user_id = auth.uid());
create policy inventory_owner_read on public.inventory_items for select to authenticated using (user_id = auth.uid());
create policy relic_catalog_public_read on public.relic_definitions for select to anon, authenticated using (enabled);
create policy player_relics_owner_read on public.player_relics for select to authenticated using (user_id = auth.uid());
create policy launch_sessions_owner_read on public.launch_sessions for select to authenticated using (user_id = auth.uid());
create policy launch_results_owner_read on public.launch_results for select to authenticated using (user_id = auth.uid());
create policy attacks_participant_read on public.attacks for select to authenticated using (attacker_id = auth.uid() or defender_id = auth.uid());
create policy snapshots_participant_read on public.attack_snapshots for select to authenticated
  using (exists (select 1 from public.attacks a where a.id = attack_id and (a.attacker_id = auth.uid() or a.defender_id = auth.uid())));
create policy shots_participant_read on public.attack_shots for select to authenticated
  using (exists (select 1 from public.attacks a where a.id = attack_id and (a.attacker_id = auth.uid() or a.defender_id = auth.uid())));
create policy friend_requests_participant_read on public.friend_requests for select to authenticated using (sender_id = auth.uid() or recipient_id = auth.uid());
create policy friendships_participant_read on public.friendships for select to authenticated using (user_low = auth.uid() or user_high = auth.uid());
create policy activity_owner_read on public.activity_feed for select to authenticated using (user_id = auth.uid());
create policy mission_catalog_current_read on public.daily_missions for select to authenticated using (mission_date >= current_date - 1 and mission_date <= current_date + 1);
create policy mission_progress_owner_read on public.mission_progress for select to authenticated using (user_id = auth.uid());
create policy seasons_public_read on public.seasons for select to anon, authenticated using (true);
create policy leaderboard_public_read on public.leaderboard_entries for select to anon, authenticated using (true);
create policy boss_public_read on public.world_bosses for select to anon, authenticated using (true);
create policy boss_contribution_owner_read on public.world_boss_contributions for select to authenticated using (user_id = auth.uid());
create policy notification_owner_read on public.notifications for select to authenticated using (user_id = auth.uid());

-- Deliberately no INSERT/UPDATE/DELETE policies for economy, inventory, launch, attack, mission or leaderboard tables.
-- Mutations are available only through narrowly granted security-definer RPCs / Edge Functions.

do $$
begin
  if not exists (select 1 from pg_publication where pubname='supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='activity_feed') then alter publication supabase_realtime add table public.activity_feed; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='friend_requests') then alter publication supabase_realtime add table public.friend_requests; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='leaderboard_entries') then alter publication supabase_realtime add table public.leaderboard_entries; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='world_bosses') then alter publication supabase_realtime add table public.world_bosses; end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='notifications') then alter publication supabase_realtime add table public.notifications; end if;
end $$;

commit;
