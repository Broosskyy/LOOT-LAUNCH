import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "reserve_username", (b) => ({ username: b.username, display_name: b.display_name, avatar_key: b.avatar_key })));

