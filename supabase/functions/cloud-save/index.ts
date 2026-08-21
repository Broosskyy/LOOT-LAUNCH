import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "get_cloud_save", () => ({})));

