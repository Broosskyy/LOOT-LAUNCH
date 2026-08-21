import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "start_attack", (b) => ({ target_public_id: b.target_public_id, revenge_attack_id: b.revenge_attack_id || null })));

