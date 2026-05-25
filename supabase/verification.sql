-- Vérifier si les tables existent dans le schéma public
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Vérifier spécifiquement la table branches
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'branches'
) AS branches_existe;