-- ============================================
-- Tables pour l'export ObjectBox -> Supabase
-- ============================================

CREATE TABLE IF NOT EXISTS public.branches (
  id BIGINT PRIMARY KEY,
  branch_nom TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.staffs (
  id BIGINT PRIMARY KEY,
  nom TEXT NOT NULL,
  grade TEXT,
  groupe TEXT,
  equipe TEXT,
  ordre INTEGER,
  branch_id BIGINT REFERENCES public.branches(id)
);

CREATE TABLE IF NOT EXISTS public.type_activites (
  id BIGINT PRIMARY KEY,
  code TEXT NOT NULL,
  libelle TEXT NOT NULL,
  description TEXT,
  couleur_hex INTEGER
);

CREATE TABLE IF NOT EXISTS public.activite_jours (
  id BIGINT PRIMARY KEY,
  jour INTEGER NOT NULL,
  statut TEXT NOT NULL,
  staff_id BIGINT REFERENCES public.staffs(id)
);

CREATE TABLE IF NOT EXISTS public.time_offs (
  id BIGINT PRIMARY KEY,
  debut TIMESTAMPTZ NOT NULL,
  fin TIMESTAMPTZ NOT NULL,
  motif TEXT,
  staff_id BIGINT REFERENCES public.staffs(id)
);

CREATE TABLE IF NOT EXISTS public.planifications (
  id BIGINT PRIMARY KEY,
  mois INTEGER NOT NULL,
  annee INTEGER NOT NULL,
  ordre_equipes TEXT,
  branch_id BIGINT REFERENCES public.branches(id),
  activites_json TEXT
);

CREATE TABLE IF NOT EXISTS public.planning_hebdos (
  id BIGINT PRIMARY KEY,
  staff_id BIGINT REFERENCES public.staffs(id),
  dimanche TEXT,
  lundi TEXT,
  mardi TEXT,
  mercredi TEXT,
  jeudi TEXT,
  vendredi TEXT,
  samedi TEXT,
  date_debut TIMESTAMPTZ,
  date_fin TIMESTAMPTZ
);

NOTIFY pgrst, 'reload schema';
