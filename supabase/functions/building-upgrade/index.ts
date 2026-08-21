import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "upgrade_building", (b) => ({ building_kind: b.building_kind, idempotency_key: b.idempotency_key })));

