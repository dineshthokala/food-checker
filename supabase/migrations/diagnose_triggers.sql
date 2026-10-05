-- DIAGNOSTIC 2: triggers / functions that may still force uuid.
-- Run alone and paste rows back.
SELECT
  n.nspname AS schema,
  c.relname AS table_name,
  t.tgname AS trigger_name,
  pg_get_triggerdef(t.oid) AS definition
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT t.tgisinternal
  AND n.nspname = 'public'
  AND c.relname IN ('profiles','user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
ORDER BY c.relname, t.tgname;