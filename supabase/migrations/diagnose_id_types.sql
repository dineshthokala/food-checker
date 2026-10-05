-- DIAGNOSTIC: run this alone and paste the result rows back.
SELECT
  c.table_name,
  c.column_name,
  c.data_type,
  c.column_default,
  (SELECT count(*)::int
     FROM pg_constraint con
     JOIN pg_class rel ON rel.oid = con.conrelid
     JOIN pg_attribute att
       ON att.attrelid = rel.oid AND att.attnum = ANY (con.conkey)
    WHERE con.contype = 'f'
      AND rel.relname = c.table_name
      AND att.attname = c.column_name
  ) AS fk_count
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND (
    (c.table_name = 'profiles' AND c.column_name IN ('id','user_id'))
    OR (c.table_name IN ('user_conditions','user_allergies','user_medications','saved_foods','food_decisions','food_reports')
        AND c.column_name = 'user_id')
  )
ORDER BY c.table_name, c.column_name;