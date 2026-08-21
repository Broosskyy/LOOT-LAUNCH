import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "send_friend_request", (b) => ({ target_public_id: b.target_public_id })));

