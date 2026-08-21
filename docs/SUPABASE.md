# Supabase Setup

1. Create separate Supabase development and production projects.
2. From this project run `supabase start` for local development.
3. Link the hosted development project and run `supabase db push`. The final v10 migration changes launch sessions to `sky_route_v3`, keeps the five-minute authoritative expiry and declares safe/risk values plus loadout events.
4. Apply `supabase/seed.sql`.
5. Deploy every folder in `supabase/functions`.
6. Set `ALLOWED_ORIGINS` to the exact HTTPS Web export domains.
7. Copy `config/backend.example.json` to the ignored `config/backend.json` and insert the publishable values.
8. Enable email confirmation and anonymous sign-in in Supabase Auth.

The client never contains a service-role key. Account deletion is the only Edge Function that reads it from server-side Supabase secrets.

For a live two-player test, create and verify two Auth accounts, reserve different usernames, remove beginner protection in the development project or wait for it to expire, then attack from player A and inspect player B's activity.
