import { cors, requireUser } from "../_shared/http.ts";
Deno.serve(async (req) => {
  const headers=cors(req); if(req.method==="OPTIONS") return new Response(null,{status:204,headers});
  try { const {client}=await requireUser(req); const b=await req.json(); const q=String(b.username??"").toLowerCase().replace(/[^a-z0-9_]/g,"").slice(0,20); const {data,error}=await client.from("profiles").select("public_id,username,display_name,avatar_key,player_level,island_level,trophies,is_training_bot").ilike("username",q+"%").eq("is_training_bot",false).limit(10); if(error) throw error;
    return new Response(JSON.stringify({items:(data??[]).map((x)=>({PublicId:x.public_id,Username:x.username,DisplayName:x.display_name,AvatarKey:x.avatar_key,PlayerLevel:x.player_level,IslandLevel:x.island_level,Trophies:x.trophies,IsTrainingBot:false}))}),{headers});
  } catch(e){return new Response(JSON.stringify({error:e instanceof Error?e.message:"request_failed"}),{status:400,headers});}
});

