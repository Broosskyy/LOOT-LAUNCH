import { rpcHandler } from "../_shared/http.ts";
Deno.serve((req) => rpcHandler(req, "submit_attack_shot", (b) => ({
  attack_id: b.AttackId, shot_number: b.ShotNumber, angle: b.Angle, power: b.Power,
  building_hit: b.BuildingHit || null, impact_speed: b.ImpactSpeed, idempotency_key: b.IdempotencyKey,
})));

