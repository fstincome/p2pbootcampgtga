CREATE POLICY "Speaker files readable" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'speakers');
CREATE POLICY "Admins can upload speaker files" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'speakers' AND public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update speaker files" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'speakers' AND public.has_role(auth.uid(), 'admin')) WITH CHECK (bucket_id = 'speakers' AND public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete speaker files" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'speakers' AND public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Anyone can upload project files" ON storage.objects FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'projects');
CREATE POLICY "Admins can read project files" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'projects' AND public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete project files" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'projects' AND public.has_role(auth.uid(), 'admin'));