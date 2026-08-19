import { createClient } from "@supabase/supabase-js";

import { handleGetCourseContent } from "./handler.ts";
import type { HandlerDeps } from "./handler.ts";
import type { PremiumLanguage } from "./types.ts";

// Import attributes bundle these directly into the deployed function —
// Deno.readTextFileSync against the deployed bundle's own directory
// crashed at module-load time in production (WORKER_ERROR, no logs reached
// our own error handling), even though it works fine locally. This is
// Supabase's documented pattern for shipping static JSON with an Edge
// Function.
import ptCourse from "./content/pt.json" with { type: "json" };
import frCourse from "./content/fr.json" with { type: "json" };
import jaCourse from "./content/ja.json" with { type: "json" };

// Supabase injects these into every Edge Function automatically.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// service-role client: only used to read `subscriptions`, which clients
// have no read access to for other users' rows anyway (RLS scopes SELECT
// to `auth.uid() = user_id`) — service-role here is about not needing a
// second round-trip to mint a scoped client per request.
const admin = createClient(supabaseUrl, supabaseServiceRoleKey);

async function getUserId(authHeader: string | null): Promise<string | null> {
  if (!authHeader?.startsWith("Bearer ")) return null;
  const jwt = authHeader.slice("Bearer ".length);
  const asCaller = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data, error } = await asCaller.auth.getUser(jwt);
  if (error || !data.user) return null;
  return data.user.id;
}

async function hasActivePremium(userId: string): Promise<boolean> {
  const { count, error } = await admin
    .from("subscriptions")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("status", "active")
    .or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`);
  if (error) throw new Error(`Premium check failed: ${error.message}`);
  return (count ?? 0) > 0;
}

const courseContent: Record<PremiumLanguage, unknown> = {
  pt: ptCourse,
  fr: frCourse,
  ja: jaCourse,
};

const deps: HandlerDeps = {
  getUserId,
  hasActivePremium,
  courseContent,
};

Deno.serve((req) => handleGetCourseContent(req, deps));
