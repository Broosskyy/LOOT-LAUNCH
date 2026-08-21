import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req)=>rpcHandler(req,"claim_crystal_mine",(b)=>({idempotency_key:b.idempotency_key})));
