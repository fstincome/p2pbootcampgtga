import { createServerFn } from "@tanstack/react-start";

/** Public: returns just the registration count for the landing page. */
export const getPublicRegistrationCount = createServerFn({ method: "GET" }).handler(async () => {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const { count, error } = await supabaseAdmin
    .from("registrations")
    .select("*", { count: "exact", head: true });
  if (error) throw new Error(error.message);
  return { count: count ?? 0 };
});

export type SelectedParticipant = {
  full_name: string;
  group_name: string | null;
  dev_role: string | null;
};

/** Public: names of accepted (selected) participants for the active cohort. */
export const getSelectedParticipants = createServerFn({ method: "GET" }).handler(async () => {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const { data: cohort } = await supabaseAdmin
    .from("cohorts")
    .select("id")
    .eq("is_active", true)
    .eq("is_public", true)
    .maybeSingle();

  let query = supabaseAdmin
    .from("registrations")
    .select("full_name,group_name,dev_role")
    .eq("status", "accepted")
    .order("full_name");
  if (cohort?.id) query = query.eq("cohort_id", cohort.id);

  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return { participants: (data ?? []) as SelectedParticipant[] };
});

export type PublicProject = {
  id: string;
  team_name: string;
  project_name: string | null;
  team_leader: string | null;
  description: string | null;
  website_url: string | null;
  docs_url: string | null;
  image_url: string | null;
  award_rank: number | null;
};

/** Public: projects the admin has marked as public. GitHub links and slide decks stay private (admin only). */
export const getPublicProjects = createServerFn({ method: "GET" }).handler(async () => {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const { data, error } = await supabaseAdmin
    .from("project_submissions")
    .select("id,team_name,project_name,team_leader,description,website_url,docs_url,preview_image_url,award_rank")
    .eq("is_public", true)
    .order("created_at", { ascending: true });
  if (error) throw new Error(error.message);
  const rows = ((data ?? []) as any[]).sort((a, b) => (a.award_rank ?? 9) - (b.award_rank ?? 9));
  const paths = rows.map((r) => r.preview_image_url).filter(Boolean);
  const map: Record<string, string> = {};
  if (paths.length) {
    const { data: urls } = await supabaseAdmin.storage.from("projects").createSignedUrls(paths, 60 * 60 * 6);
    (urls ?? []).forEach((u) => { if (u.path && u.signedUrl) map[u.path] = u.signedUrl; });
  }
  const projects: PublicProject[] = rows.map((r) => ({
    id: r.id, team_name: r.team_name, project_name: r.project_name, team_leader: r.team_leader,
    description: r.description, website_url: r.website_url, docs_url: r.docs_url,
    image_url: r.preview_image_url ? map[r.preview_image_url] ?? null : null,
    award_rank: r.award_rank ?? null,
  }));
  return { projects };
});
