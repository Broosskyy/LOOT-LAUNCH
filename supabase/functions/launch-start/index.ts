import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "start_launch", (b) => ({ lootling: b.lootling, cannon: b.cannon, world_key: b.world_key ?? "wolkengarten" })));
