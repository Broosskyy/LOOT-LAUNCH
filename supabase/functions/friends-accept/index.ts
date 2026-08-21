import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "accept_friend_request", (b) => ({ request_id: b.request_id })));

