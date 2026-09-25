import { supabase } from "@/integrations/supabase/client";

// Public reads run from the browser with the public key, so they work on any host (Lovable, Vercel…).

export async function getPublicRegistrationCount() {
  const { data, error } = await (supabase as any).rpc("get_registration_count");
  if (error) throw new Error(error.message);
  return { count: (data as number) ?? 0 };
}

export type SelectedParticipant = {
  full_name: string;
  group_name: string | null;
  dev_role: string | null;
};

export async function getSelectedParticipants() {
  const { data, error } = await (supabase as any).rpc("get_selected_participants");
  if (error) throw new Error(error.message);
  return { participants: (data ?? []) as SelectedParticipant[] };
}

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

export async function getPublicProjects() {
  const { data, error } = await supabase
    .from("project_submissions")
    .select("id,team_name,project_name,team_leader,description,website_url,docs_url,preview_image_url,award_rank")
    .eq("is_public", true)
    .order("created_at", { ascending: true });
  if (error) throw new Error(error.message);
  const rows = ((data ?? []) as any[]).sort((a, b) => (a.award_rank ?? 9) - (b.award_rank ?? 9));
  const paths = rows.map((r) => r.preview_image_url).filter(Boolean) as string[];
  const map: Record<string, string> = {};
  if (paths.length) {
    const { data: urls } = await supabase.storage.from("projects").createSignedUrls(paths, 60 * 60 * 6);
    (urls ?? []).forEach((u) => { if (u.path && u.signedUrl) map[u.path] = u.signedUrl; });
  }
  const projects: PublicProject[] = rows.map((r) => ({
    id: r.id, team_name: r.team_name, project_name: r.project_name, team_leader: r.team_leader,
    description: r.description, website_url: r.website_url, docs_url: r.docs_url,
    image_url: r.preview_image_url ? map[r.preview_image_url] ?? null : null,
    award_rank: r.award_rank ?? null,
  }));
  return { projects };
}
