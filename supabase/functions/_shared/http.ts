import { createClient } from "npm:@supabase/supabase-js@2";

export function cors(req: Request) {
  const origin = req.headers.get("origin") ?? "";
  const allowed = (Deno.env.get("ALLOWED_ORIGINS") ?? "http://localhost:4173").split(",").map((x) => x.trim());
  return {
    "Access-Control-Allow-Origin": allowed.includes(origin) ? origin : allowed[0],
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
    "Content-Type": "application/json",
  };
}

export function userClient(req: Request) {
  const auth = req.headers.get("Authorization");
  if (!auth) throw new Error("authentication_required");
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: auth } }, auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function rpcHandler(req: Request, rpcName: string, map: (body: Record<string, unknown>) => Record<string, unknown>) {
  const headers = cors(req);
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
  try {
    const client = userClient(req); const body = await req.json().catch(() => ({}));
    const { data, error } = await client.rpc(rpcName, map(body));
    if (error) throw error;
    return new Response(JSON.stringify(data ?? {}), { status: 200, headers });
  } catch (error) {
    const message = error instanceof Error ? error.message : "request_failed";
    const status = message.includes("auth") || message.includes("JWT") ? 401 : 400;
    return new Response(JSON.stringify({ error: message }), { status, headers });
  }
}

export async function requireUser(req: Request) {
  const client = userClient(req); const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new Error("authentication_required");
  return { client, user: data.user };
}

