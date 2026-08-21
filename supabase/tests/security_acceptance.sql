-- Run against a disposable local Supabase database after creating two Auth users.
-- This file is intentionally transaction-wrapped and leaves no game mutations behind.
begin;

select plan(8);

select has_table('public','wallets','wallets exists');
select has_table('public','attacks','attacks exists');
select has_table('private','security_events','security events are private');
select policies_are('public','wallets',array['wallets_owner_read'],'wallet has read-only owner policy');
select policies_are('public','energy_states',array['energy_owner_read'],'energy has read-only owner policy');
select policies_are('public','attacks',array['attacks_participant_read'],'attacks are participant-readable only');
select function_privs_are('public','start_launch',array['text','text'],'authenticated',array['EXECUTE'],'authenticated may start launch through RPC');
select function_privs_are('public','submit_launch',array['jsonb'],'authenticated',array['EXECUTE'],'authenticated may submit through RPC');

select * from finish();
rollback;
