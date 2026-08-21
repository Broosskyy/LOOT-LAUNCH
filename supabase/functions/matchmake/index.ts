import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "find_match", (b) => ({ allow_training: Boolean(b.allow_training) })));

