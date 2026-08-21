import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "submit_launch", (b) => ({ submission: b })));

