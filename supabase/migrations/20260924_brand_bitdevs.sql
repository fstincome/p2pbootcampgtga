-- Rename Free Tech Institute to BitDevs Gitega in live schedule data
UPDATE public.schedule_slots
SET theme = 'Objectifs et mentors BitDevs Gitega'
WHERE theme ILIKE '%Free Tech Institute%';
