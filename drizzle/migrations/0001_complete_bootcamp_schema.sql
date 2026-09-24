ALTER TABLE public.registrations
  ADD COLUMN IF NOT EXISTS dev_role text,
  ADD COLUMN IF NOT EXISTS languages text[] NOT NULL DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS group_name text,
  ADD COLUMN IF NOT EXISTS available_all_days boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS has_laptop boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS problem_idea text;
ALTER TABLE public.registrations ALTER COLUMN hackathon_choice SET DEFAULT 'bootcamp';

DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated, service_role;

DROP POLICY IF EXISTS "Anyone can view registrations" ON public.registrations;
REVOKE SELECT ON public.registrations FROM anon;
CREATE POLICY "Admins can view registrations" ON public.registrations FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update registrations" ON public.registrations FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete registrations" ON public.registrations FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.cohorts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, slug text NOT NULL UNIQUE,
  start_date date, end_date date, location text, city text, venue text, tagline text, tagline_en text,
  summary text, summary_en text, highlights text[] NOT NULL DEFAULT '{}'::text[], highlights_en text[] NOT NULL DEFAULT '{}'::text[],
  days integer NOT NULL DEFAULT 2, is_public boolean NOT NULL DEFAULT true, is_active boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.cohorts TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cohorts TO authenticated;
GRANT ALL ON public.cohorts TO service_role;
ALTER TABLE public.cohorts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can view cohorts" ON public.cohorts FOR SELECT USING (true);
CREATE POLICY "Admins can insert cohorts" ON public.cohorts FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update cohorts" ON public.cohorts FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete cohorts" ON public.cohorts FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

ALTER TABLE public.registrations ADD COLUMN cohort_id uuid REFERENCES public.cohorts(id) ON DELETE SET NULL;
CREATE INDEX idx_registrations_cohort ON public.registrations(cohort_id);

CREATE TABLE public.speakers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, role text, role_en text, bio text, bio_en text,
  twitter_url text, avatar_url text, cohort_id uuid REFERENCES public.cohorts(id) ON DELETE SET NULL,
  sort_order integer NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.speakers TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.speakers TO authenticated;
GRANT ALL ON public.speakers TO service_role;
ALTER TABLE public.speakers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can view speakers" ON public.speakers FOR SELECT USING (true);
CREATE POLICY "Admins can insert speakers" ON public.speakers FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update speakers" ON public.speakers FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete speakers" ON public.speakers FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE INDEX idx_speakers_cohort ON public.speakers(cohort_id);

CREATE TABLE public.schedule_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), day integer NOT NULL CHECK (day >= 1 AND day <= 14),
  start_time text NOT NULL, end_time text, title text NOT NULL DEFAULT '', title_en text, theme text, theme_en text,
  speaker_id uuid REFERENCES public.speakers(id) ON DELETE SET NULL, cohort_id uuid REFERENCES public.cohorts(id) ON DELETE CASCADE,
  sort_order integer NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.schedule_slots TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.schedule_slots TO authenticated;
GRANT ALL ON public.schedule_slots TO service_role;
ALTER TABLE public.schedule_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can view schedule slots" ON public.schedule_slots FOR SELECT USING (true);
CREATE POLICY "Admins can insert schedule slots" ON public.schedule_slots FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update schedule slots" ON public.schedule_slots FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete schedule slots" ON public.schedule_slots FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE INDEX idx_schedule_slots_cohort ON public.schedule_slots(cohort_id);

CREATE TABLE public.contact_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL, email text NOT NULL, message text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
GRANT INSERT ON public.contact_messages TO anon;
GRANT SELECT, INSERT, DELETE ON public.contact_messages TO authenticated;
GRANT ALL ON public.contact_messages TO service_role;
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit a contact message" ON public.contact_messages FOR INSERT TO anon, authenticated WITH CHECK (length(trim(name)) BETWEEN 1 AND 100 AND length(trim(email)) BETWEEN 3 AND 255 AND length(trim(message)) BETWEEN 1 AND 2000);
CREATE POLICY "Admins can view contact messages" ON public.contact_messages FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete contact messages" ON public.contact_messages FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

CREATE OR REPLACE FUNCTION public.update_updated_at_column() RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TABLE public.project_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), cohort_id uuid REFERENCES public.cohorts(id) ON DELETE SET NULL,
  team_name text NOT NULL, team_leader text, project_name text, contact_email text, members text, description text,
  website_url text, github_url text, github_backend_url text, preview_image_url text, slides_pdf_url text, slides_link text, docs_url text,
  status text NOT NULL DEFAULT 'submitted', is_public boolean NOT NULL DEFAULT false, award_rank integer CHECK (award_rank IN (1,2)),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT INSERT ON public.project_submissions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_submissions TO authenticated;
GRANT ALL ON public.project_submissions TO service_role;
ALTER TABLE public.project_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can submit a project" ON public.project_submissions FOR INSERT TO anon, authenticated WITH CHECK (
  length(trim(team_name)) BETWEEN 1 AND 150 AND (contact_email IS NULL OR length(trim(contact_email)) BETWEEN 3 AND 255)
  AND coalesce(length(description),0) <= 2000 AND coalesce(length(members),0) <= 500
  AND coalesce(length(website_url),0) <= 500 AND coalesce(length(github_url),0) <= 500
  AND coalesce(length(github_backend_url),0) <= 500 AND coalesce(length(slides_link),0) <= 500
  AND coalesce(length(team_leader),0) <= 150 AND coalesce(length(project_name),0) <= 150
  AND coalesce(length(preview_image_url),0) <= 1000 AND coalesce(length(slides_pdf_url),0) <= 1000 AND coalesce(length(docs_url),0) <= 500
);
CREATE POLICY "Public can view published projects" ON public.project_submissions FOR SELECT TO anon, authenticated USING (is_public = true);
CREATE POLICY "Admins can view project submissions" ON public.project_submissions FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update project submissions" ON public.project_submissions FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete project submissions" ON public.project_submissions FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));
CREATE INDEX idx_project_submissions_cohort ON public.project_submissions(cohort_id);
CREATE TRIGGER update_project_submissions_updated_at BEFORE UPDATE ON public.project_submissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();