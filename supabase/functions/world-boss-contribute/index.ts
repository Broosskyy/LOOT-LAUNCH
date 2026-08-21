import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "contribute_world_boss", (b) => ({ score: b.score, idempotency_key: b.idempotency_key })));

