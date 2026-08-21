import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "remove_friend", (b) => ({ target_public_id: b.target_public_id })));
