// Server-side anti-cheat check for an uploaded run.
// Deploy: supabase functions deploy validate-run
import { createClient } from "jsr:@supabase/supabase-js@2";

const MAX_SPEED_MPS = 7.0; // faster than this between points = bike / motorbike
const MAX_FAST_FRACTION = 0.1; // allow GPS glitches on up to 10% of segments
const MAX_GAP_SEC = 60; // longer silence = phone likely handed off / tracking off

type Point = { lat: number; lng: number; t: string };

function haversineM(a: Point, b: Point): number {
  const r = (d: number) => (d * Math.PI) / 180;
  const dLat = r(b.lat - a.lat);
  const dLng = r(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(r(a.lat)) * Math.cos(r(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.min(1, Math.sqrt(h)));
}

Deno.serve(async (req) => {
  const { run_id } = await req.json();
  if (!run_id) return new Response("run_id required", { status: 400 });

  // Confirm the caller owns this run before using the service role.
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: owned } = await userClient.from("runs").select("id").eq("id", run_id).maybeSingle();
  if (!owned) return new Response("not found", { status: 404 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: points, error } = await admin
    .from("gps_points")
    .select("lat,lng,t")
    .eq("run_id", run_id)
    .order("seq");
  if (error) return new Response(error.message, { status: 500 });

  let fast = 0;
  let maxGap = 0;
  for (let i = 1; i < (points?.length ?? 0); i++) {
    const a = points![i - 1] as Point, b = points![i] as Point;
    const dt = (Date.parse(b.t) - Date.parse(a.t)) / 1000;
    if (dt <= 0) continue;
    maxGap = Math.max(maxGap, dt);
    if (haversineM(a, b) / dt > MAX_SPEED_MPS) fast++;
  }
  const segments = Math.max(1, (points?.length ?? 1) - 1);
  const speedOk = fast / segments <= MAX_FAST_FRACTION;
  const gapsOk = maxGap <= MAX_GAP_SEC;
  const reasons = [
    !speedOk && `${fast} of ${segments} segments faster than ${MAX_SPEED_MPS} m/s`,
    !gapsOk && `GPS gap of ${Math.round(maxGap)} s`,
    (points?.length ?? 0) < 10 && "too few GPS points",
  ].filter(Boolean);

  await admin.from("run_validations").upsert({
    run_id,
    speed_ok: speedOk,
    gaps_ok: gapsOk,
    flag_reason: reasons.length ? reasons.join("; ") : null,
  });
  await admin.from("runs").update({ status: reasons.length ? "flagged" : "approved" }).eq("id", run_id);

  return Response.json({ speed_ok: speedOk, gaps_ok: gapsOk, flag_reason: reasons.join("; ") || null });
});
