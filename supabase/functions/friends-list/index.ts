import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req)=>rpcHandler(req,"list_friends",()=>({})));
