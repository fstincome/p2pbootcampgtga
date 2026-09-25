CREATE OR REPLACE FUNCTION public.get_selected_participants()
RETURNS TABLE(full_name text, group_name text, dev_role text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT r.full_name, r.group_name, r.dev_role FROM public.registrations r
  WHERE r.status = 'accepted'
    AND (r.cohort_id = (SELECT c.id FROM public.cohorts c WHERE c.is_active AND c.is_public LIMIT 1)
         OR NOT EXISTS (SELECT 1 FROM public.cohorts c WHERE c.is_active AND c.is_public))
  ORDER BY r.full_name
$$;
CREATE OR REPLACE FUNCTION public.get_registration_count()
RETURNS integer LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT count(*)::int FROM public.registrations
$$;
GRANT EXECUTE ON FUNCTION public.get_selected_participants() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_registration_count() TO anon, authenticated;
CREATE POLICY "Public can read project previews" ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'projects' AND name LIKE 'previews/%');