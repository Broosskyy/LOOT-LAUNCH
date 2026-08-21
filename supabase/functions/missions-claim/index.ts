import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req)=>rpcHandler(req,"claim_daily_missions",(b)=>({idempotency_key:b.idempotency_key})));
